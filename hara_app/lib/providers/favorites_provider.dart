import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _key = 'favorites';

  Set<String> _ids = {};

  Set<String> get ids => _ids;
  bool isFavorite(String id) => _ids.contains(id);

  Future<void> load() async {
    try {
      final res = await ApiClient.instance.get('api/favorites');
      _ids = (res as List)
          .map((m) => (m['id'] ?? '').toString())
          .toSet();
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _ids = LocalStore.instance
        .getList(_key)
        .map((m) => (m['id'] ?? '').toString())
        .toSet();
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    try {
      await ApiClient.instance.post('api/favorites/$id', {});
    } on ApiException {
      // offline: local only
    }
    if (!_ids.remove(id)) _ids.add(id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _ids.map((id) => {'id': id}).toList());
  }
}
