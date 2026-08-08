import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class AuthProvider extends ChangeNotifier {
  static const String _usersKey = 'users';
  static const String _passwordsKey = 'passwords';
  static const String _sessionKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  List<UserModel> _users = [];
  Map<String, String> _passwords = {};
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _online = false;

  List<UserModel> get users => _users;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isSeller => _currentUser?.userType == 'seller';
  bool get isDelivery => _currentUser?.userType == 'delivery';
  bool get isAdmin => _currentUser?.userType == 'admin';
  bool get online => _online;

  Future<void> init() async {
    await LocalStore.instance.init();
    _loadLocalUsers();
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
      }
    }
    final session = LocalStore.instance.getMap(_sessionKey);
    if (session != null) {
      _currentUser = UserModel.fromMap(session, session['uid'] ?? '');
    }
    if (_currentUser == null) {
      for (final u in _users) {
        if (u.uid == 'user1') {
          _currentUser = u;
          await _saveSession();
          break;
        }
      }
    }
    notifyListeners();
  }

  void _loadLocalUsers() {
    _users = LocalStore.instance
        .getList(_usersKey)
        .map((m) => UserModel.fromMap(m, m['uid'] ?? ''))
        .toList();
    _passwords = _loadPasswords();
    final needsReseed = _users.isEmpty || _users.any((u) => u.email.isEmpty);
    if (needsReseed) {
      _seedDemoUsers();
      _saveUsers();
      _savePasswords();
    }
  }

  void _seedDemoUsers() {
    final now = DateTime.now();
    _users = [
      UserModel(
        uid: 'admin1',
        email: 'admin@hara.ps',
        name: 'الإدارة',
        phone: '0599000000',
        address: 'رام الله',
        userType: 'admin',
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      UserModel(
        uid: 'user1',
        email: 'user1@hara.ps',
        name: 'محمد أبو أحمد',
        phone: '0599000001',
        address: 'الخليل - عسكر',
        userType: 'regular',
        createdAt: now.subtract(const Duration(days: 210)),
      ),
      UserModel(
        uid: 'user2',
        email: 'user2@hara.ps',
        name: 'سامي عوض',
        phone: '0599000003',
        address: 'نابلس - رفيديا',
        userType: 'regular',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      UserModel(
        uid: 'delivery1',
        email: 'delivery@hara.ps',
        name: 'خالد حسن',
        phone: '0599000002',
        address: 'رام الله - البيرة',
        userType: 'delivery',
        deliveryAreas: const ['البيرة', 'الماصيون'],
        deliveryFee: 7,
        vehicleType: 'دراجة',
        createdAt: now.subtract(const Duration(days: 150)),
      ),
    ];
    _passwords = {
      'admin1': '123456',
      'user1': '123456',
      'user2': '123456',
      'delivery1': '123456',
    };
  }

  Map<String, String> _loadPasswords() {
    final raw = LocalStore.instance.getMap(_passwordsKey);
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _savePasswords() {
    return LocalStore.instance.setMap(_passwordsKey, _passwords);
  }

  Future<void> _saveUsers() {
    return LocalStore.instance
        .saveCollection(_usersKey, _users.map((u) => u.toMap()).toList());
  }

  Future<void> _saveToken() async {
    await LocalStore.instance.setMap(_tokenKey, {'token': ApiClient.instance.token});
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.post('api/auth/login', {
        'email': email,
        'password': password,
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
      if (!e.offline) {
        _error = e.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
    final matches = _users.where((u) => u.email == email).toList();
    final user = matches.isEmpty ? null : matches.first;
    if (user == null || _passwords[user.uid] != password) {
      _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    _currentUser = user;
    await _saveSession();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

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
      final res = await ApiClient.instance
          .post('api/auth/google', {'idToken': idToken});
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

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
    required String userType,
    List<String>? deliveryAreas,
    double? deliveryFee,
    String? vehicleType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.post('api/auth/register', {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'password': password,
        'userType': userType,
        if (userType == 'delivery') 'deliveryAreas': deliveryAreas ?? [],
        if (userType == 'delivery') 'deliveryFee': deliveryFee,
        if (userType == 'delivery') 'vehicleType': vehicleType,
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
      if (!e.offline) {
        _error = e.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
    if (_users.any((u) => u.toMap()['email'] == email)) {
      _error = 'البريد الإلكتروني مستخدم مسبقاً';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final uid = 'u${DateTime.now().millisecondsSinceEpoch}';
    final user = UserModel(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      address: address,
      userType: userType,
      deliveryAreas: userType == 'delivery' ? deliveryAreas : null,
      deliveryFee: userType == 'delivery' ? deliveryFee : null,
      vehicleType: userType == 'delivery' ? vehicleType : null,
    );
    _users.add(user);
    _passwords[uid] = password;
    await _saveUsers();
    await _savePasswords();
    _currentUser = user;
    await _saveSession();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateDeliveryProfile({
    required List<String> areas,
    required double fee,
    required String vehicleType,
  }) async {
    final u = _currentUser;
    if (u == null) return;
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
      notifyListeners();
      return;
    } on ApiException {
      // fallback to local
    }
    final map = Map<String, dynamic>.from(u.toMap());
    map['deliveryAreas'] = areas;
    map['deliveryFee'] = fee;
    map['vehicleType'] = vehicleType;
    map['userType'] = 'delivery';
    _currentUser = UserModel.fromMap(map, u.uid);
    final idx = _users.indexWhere((x) => x.uid == u.uid);
    if (idx >= 0) {
      _users[idx] = _currentUser!;
      await _saveUsers();
    }
    await _saveSession();
    notifyListeners();
  }

  Future<void> setArea(String area) async {
    final u = _currentUser;
    if (u == null) return;
    try {
      final res = await ApiClient.instance.put('api/auth/profile', {'area': area});
      _online = true;
      final user = res['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromMap(user, user['uid'] ?? '');
      await _saveSession();
      notifyListeners();
      return;
    } on ApiException {
      // fallback to local
    }
    final map = Map<String, dynamic>.from(u.toMap());
    map['area'] = area;
    _currentUser = UserModel.fromMap(map, u.uid);
    final idx = _users.indexWhere((x) => x.uid == u.uid);
    if (idx >= 0) {
      _users[idx] = _currentUser!;
      await _saveUsers();
    }
    await _saveSession();
    notifyListeners();
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

  Future<void> _saveSession() {
    return LocalStore.instance.setMap(_sessionKey, _currentUser!.toMap());
  }
}
