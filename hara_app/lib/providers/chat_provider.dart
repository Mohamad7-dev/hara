import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class ChatProvider extends ChangeNotifier {
  static const String _key = 'chats';

  List<ChatConversation> _chats = [];
  bool _online = false;

  bool get online => _online;

  List<ChatConversation> get chats {
    final sorted = [..._chats];
    sorted.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return sorted;
  }

  int get unreadTotal => _chats.fold(0, (s, c) => s + c.unread);

  Future<void> load() async {
    try {
      final res = await ApiClient.instance.get('api/chats');
      _chats = (res as List)
          .map((m) => ChatConversation.fromMap(m as Map<String, dynamic>))
          .toList();
      _online = true;
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _chats = LocalStore.instance
        .getList(_key)
        .map((m) => ChatConversation.fromMap(m))
        .toList();
    notifyListeners();
  }

  /// Refresh all conversations from the server.
  Future<void> refresh() async {
    try {
      final res = await ApiClient.instance.get('api/chats');
      _chats = (res as List)
          .map((m) => ChatConversation.fromMap(m as Map<String, dynamic>))
          .toList();
      _online = true;
      await _save();
      notifyListeners();
    } on ApiException {
      // keep local
    }
  }

  /// Refresh a single conversation (used for polling while chat is open).
  Future<void> refreshConversation(String name) async {
    try {
      final res = await ApiClient.instance.get('api/chats');
      for (final m in res) {
        final conv = ChatConversation.fromMap(m as Map<String, dynamic>);
        if (conv.name == name) _upsert(conv);
      }
      _online = true;
      await _save();
      notifyListeners();
    } on ApiException {
      // keep local
    }
  }

  ChatConversation ensure(
    String name, {
    String? role,
    String? iconKey,
  }) {
    _openOnServer(name);
    final existing = byName(name);
    if (existing != null) return existing;
    final c = ChatConversation(
      id: name,
      name: name,
      role: role ?? '',
      iconKey: iconKey ?? 'person',
    );
    _chats.add(c);
    notifyListeners();
    return c;
  }

  Future<void> _openOnServer(String name) async {
    try {
      final res = await ApiClient.instance.post('api/chats/open', {'peerName': name});
      _upsert(ChatConversation.fromMap(res as Map<String, dynamic>));
      _online = true;
      await _save();
      notifyListeners();
    } on ApiException {
      // offline: conversation stays local-only
    }
  }

  void _upsert(ChatConversation c) {
    final idx = _chats.indexWhere((x) => x.name == c.name);
    if (idx >= 0) {
      _chats[idx] = c;
    } else {
      _chats.add(c);
    }
  }

  ChatConversation? byName(String name) {
    for (final c in _chats) {
      if (c.name == name) return c;
    }
    return null;
  }

  Future<void> markRead(String name) async {
    final c = byName(name);
    if (c != null && c.unread != 0) {
      c.unread = 0;
      notifyListeners();
    }
    try {
      final conv = byName(name) ?? (await _openOnServerReturn(name));
      if (conv != null && conv.id.isNotEmpty) {
        await ApiClient.instance.post('api/chats/${conv.id}/read', {});
        _online = true;
      }
    } on ApiException {
      // offline: local only
    }
    await _save();
  }

  Future<ChatConversation?> _openOnServerReturn(String name) async {
    try {
      final res = await ApiClient.instance.post('api/chats/open', {'peerName': name});
      final conv = ChatConversation.fromMap(res as Map<String, dynamic>);
      _upsert(conv);
      _online = true;
      await _save();
      notifyListeners();
      return conv;
    } on ApiException {
      return null;
    }
  }

  Future<void> send(
    String name, {
    String text = '',
    String? img,
    String? audio,
  }) async {
    String? audioPayload = audio;
    if (audio != null && audio.startsWith('data:')) {
      try {
        final up = await ApiClient.instance.post('api/media', {'base64': audio});
        audioPayload = up['url'] as String;
      } on ApiException {
        audioPayload = audio;
      }
    }
    final conv = ensure(name);
    conv.messages
        .add(ChatMessage(from: 'me', text: text, img: img, audio: audioPayload));
    notifyListeners();
    try {
      final opened = await ApiClient.instance.post('api/chats/open', {'peerName': name});
      final peerUid = (opened as Map<String, dynamic>)['id'] as String;
      String? imgPayload = img;
      if (img != null && img.startsWith('data:')) {
        try {
          final up = await ApiClient.instance.post('api/media', {'base64': img});
          imgPayload = (up['url'] as String);
        } on ApiException {
          imgPayload = img;
        }
      }
      await ApiClient.instance.post('api/chats/$peerUid/messages', {
        'text': text,
        'img': imgPayload,
        'audio': audioPayload,
      });
      _online = true;
      await refreshConversation(name);
      notifyListeners();
    } on ApiException {
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _chats.map((c) => c.toMap()).toList());
  }
}
