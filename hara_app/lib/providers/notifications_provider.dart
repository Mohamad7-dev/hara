import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class NotificationsProvider extends ChangeNotifier {
  static const String _key = 'notifications';

  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items {
    final sorted = [..._items];
    sorted.sort((a, b) => DateTime.parse(b['time'].toString())
        .compareTo(DateTime.parse(a['time'].toString())));
    return sorted;
  }

  int get unreadCount => _items.where((n) => n['read'] != true).length;

  Future<void> load() async {
    try {
      final res = await ApiClient.instance.get('api/notifications');
      _items = (res as List).map((m) => Map<String, dynamic>.from(m)).toList();
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _items = LocalStore.instance.getList(_key);
    if (_items.isEmpty) {
      _seedDemo();
      await _save();
    }
    notifyListeners();
  }

  void _seedDemo() {
    final now = DateTime.now();
    _items = [
      {
        'iconKey': 'order',
        'title': 'طلب جديد',
        'body': 'طلبك رقم #1042 أصبح قيد التوصيل',
        'time': now.subtract(const Duration(minutes: 12)).toIso8601String(),
        'read': false,
      },
      {
        'iconKey': 'message',
        'title': 'رسالة جديدة',
        'body': 'سامي عوض: أهلاً بك! نعم الشنطة متوفرة.',
        'time': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'read': false,
      },
    ];
  }

  Future<void> markAllRead() async {
    for (final n in _items) {
      n['read'] = true;
    }
    try {
      await ApiClient.instance.post('api/notifications/read', {});
    } on ApiException {
      // offline: local only
    }
    await _save();
    notifyListeners();
  }

  /// Creates a local-only notification (used for offline confirmation).
  Future<void> add({
    required String iconKey,
    required String title,
    required String body,
  }) async {
    _items.insert(0, {
      'iconKey': iconKey,
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    });
    await _save();
    notifyListeners();
  }

  Future<void> _save() {
    return LocalStore.instance.saveCollection(_key, _items);
  }
}
