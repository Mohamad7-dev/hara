import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class CommentProvider extends ChangeNotifier {
  static const String _key = 'comments';

  List<CommentModel> _comments = [];
  final Map<String, DateTime> _lastFetch = {};

  Future<void> load() async {
    _comments = LocalStore.instance
        .getList(_key)
        .map((m) => CommentModel.fromMap(m))
        .toList();
    notifyListeners();
  }

  List<CommentModel> commentsFor(String kind, String targetId) {
    _refreshIfStale(kind, targetId);
    final list = _comments
        .where((c) => c.kind == kind && c.targetId == targetId)
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  void _refreshIfStale(String kind, String targetId) {
    final key = '$kind|$targetId';
    final last = _lastFetch[key];
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 12)) {
      return;
    }
    _lastFetch[key] = DateTime.now();
    loadFor(kind, targetId);
  }

  Future<void> loadFor(String kind, String targetId) async {
    try {
      final res = await ApiClient.instance
          .get('api/comments?kind=$kind&targetId=${Uri.encodeQueryComponent(targetId)}');
      final fresh = (res as List)
          .map((m) => CommentModel.fromMap(m as Map<String, dynamic>))
          .toList();
      _comments.removeWhere((c) => c.kind == kind && c.targetId == targetId);
      _comments.addAll(fresh);
      await _save();
      notifyListeners();
    } on ApiException {
      // offline fallback: keep local cache
    }
  }

  int countFor(String kind, String targetId) =>
      _comments.where((c) => c.kind == kind && c.targetId == targetId).length;

  double averageRating(String productId) {
    final rs = _comments
        .where((c) =>
            c.kind == 'product' && c.targetId == productId && c.rating > 0)
        .toList();
    if (rs.isEmpty) return 0;
    var sum = 0;
    for (final c in rs) {
      sum += c.rating;
    }
    return sum / rs.length;
  }

  Future<void> addComment({
    required String kind,
    required String targetId,
    required String author,
    required String role,
    required String avatarKey,
    required String text,
    int rating = 0,
  }) async {
    try {
      final res = await ApiClient.instance.post('api/comments', {
        'kind': kind,
        'targetId': targetId,
        'text': text,
        'rating': rating,
      });
      final c = CommentModel.fromMap(res as Map<String, dynamic>);
      _comments.add(c);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final c = CommentModel(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      kind: kind,
      targetId: targetId,
      author: author,
      role: role,
      avatarKey: avatarKey,
      text: text,
      rating: rating,
      time: DateTime.now(),
    );
    _comments.add(c);
    await _save();
    notifyListeners();
  }

  Future<void> addReply({
    required String kind,
    required String targetId,
    required String commentId,
    required String author,
    required String role,
    required String avatarKey,
    required String text,
  }) async {
    try {
      await ApiClient.instance.post('api/comments/$commentId/replies', {'text': text});
      await loadFor(kind, targetId);
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final reply = CommentModel(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      kind: kind,
      targetId: targetId,
      author: author,
      role: role,
      avatarKey: avatarKey,
      text: text,
      time: DateTime.now(),
    );
    for (var i = 0; i < _comments.length; i++) {
      if (_comments[i].id == commentId) {
        _comments[i] = _comments[i]
            .copyWith(replies: [..._comments[i].replies, reply]);
        break;
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _comments.map((c) => c.toMap()).toList());
  }
}
