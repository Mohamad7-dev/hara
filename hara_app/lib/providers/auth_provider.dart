import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class AuthProvider extends ChangeNotifier {
  static const String _sessionKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _online = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isSeller => _currentUser?.userType == 'seller';
  bool get isDelivery => _currentUser?.userType == 'delivery';
  bool get isAdmin => _currentUser?.userType == 'admin';
  bool get online => _online;

  /// هل الملف الشخصي ناقص (مطلوب: اسم + جوال + صورة)؟
  bool get needsProfile {
    final u = _currentUser;
    if (u == null) return false;
    return u.name.trim().isEmpty || u.phone.trim().isEmpty || (u.photo ?? '').isEmpty;
  }

  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  Future<void> init() async {
    await LocalStore.instance.init();
    final savedToken = LocalStore.instance.getMap(_tokenKey);
    if (savedToken != null && savedToken['token'] != null) {
      ApiClient.instance.token = savedToken['token'].toString();
    }
    if (ApiClient.instance.token != null) {
      try {
        final res = await ApiClient.instance.get('api/auth/me');
        _online = true;
        final u = res['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(u, u['uid'] ?? '');
        await _saveSession();
        notifyListeners();
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          ApiClient.instance.token = null;
          await LocalStore.instance.remove(_tokenKey);
        }
      } catch (_) {
        // offline: نتابع للجلسة المحلية
      }
    }
    final session = LocalStore.instance.getMap(_sessionKey);
    if (session != null) {
      _currentUser = UserModel.fromMap(session, session['uid'] ?? '');
    }
    notifyListeners();
  }

  Future<void> _saveToken() async {
    await LocalStore.instance
        .setMap(_tokenKey, {'token': ApiClient.instance.token});
  }

  Future<void> _saveSession() {
    return LocalStore.instance.setMap(_sessionKey, _currentUser!.toMap());
  }

  Future<bool> googleLogin() async {
    if (googleClientId.isEmpty) {
      _error = 'تسجيل الدخول عبر جوجل غير مفعّل حالياً';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final google = GoogleSignIn(clientId: googleClientId);
      final account = await google.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _error = 'تعذر الحصول على بيانات جوجل';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final photoUrl = account.photoUrl?.toString();
      final res = await ApiClient.instance.post('api/auth/google', {
        'idToken': idToken,
        if (photoUrl != null) 'photo': photoUrl,
      });
      ApiClient.instance.token = res['token'] as String;
      await _saveToken();
      final u = res['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromMap(u, u['uid'] ?? '');
      await _saveSession();
      _online = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'تعذر تسجيل الدخول عبر جوجل';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photo,
  }) async {
    final u = _currentUser;
    if (u == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.put('api/auth/profile', {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (photo != null) 'photo': photo,
      });
      _online = true;
      final user = res['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromMap(user, user['uid'] ?? '');
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDeliveryProfile({
    required List<String> areas,
    required double fee,
    required String vehicleType,
  }) async {
    final u = _currentUser;
    if (u == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.put('api/auth/profile', {
        'deliveryAreas': areas,
        'deliveryFee': fee,
        'vehicleType': vehicleType,
        'userType': 'delivery',
      });
      _online = true;
      final user = res['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromMap(user, user['uid'] ?? '');
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setArea(String area) async {
    final u = _currentUser;
    if (u == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.put('api/auth/profile', {'area': area});
      _online = true;
      final user = res['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromMap(user, user['uid'] ?? '');
      await _saveSession();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (ApiClient.instance.token != null) {
      try {
        await ApiClient.instance.post('api/auth/logout', {});
      } on ApiException {
        // ignore
      }
    }
    ApiClient.instance.token = null;
    await LocalStore.instance.remove(_sessionKey);
    await LocalStore.instance.remove(_tokenKey);
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
