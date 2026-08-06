import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static final LocalStore instance = LocalStore._();
  LocalStore._();

  SharedPreferences? _prefs;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  bool get ready => _ready;

  SharedPreferences get _p {
    if (!_ready) {
      throw StateError('LocalStore.init() must be called first');
    }
    return _prefs!;
  }

  List<Map<String, dynamic>> getList(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> setList(String key, List<Map<String, dynamic>> list) {
    return _p.setString(key, jsonEncode(list));
  }

  Map<String, dynamic>? getMap(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> setMap(String key, Map<String, dynamic> map) {
    return _p.setString(key, jsonEncode(map));
  }

  Future<void> remove(String key) => _p.remove(key);

  Future<void> saveCollection(String key, List<Map<String, dynamic>> list) =>
      setList(key, list);
}
