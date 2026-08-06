import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final bool offline;
  final int? statusCode;
  ApiException(this.message, {this.offline = false, this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _envBase = String.fromEnvironment('API_BASE');

  String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:8000';
      }
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) {
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request().timeout(const Duration(seconds: 10));
      final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body;
      }
      var msg = 'خطأ في الخادم (${res.statusCode})';
      if (body is Map && body['detail'] != null) {
        msg = body['detail'].toString();
      }
      throw ApiException(msg, statusCode: res.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (_) {
      throw ApiException('انتهت مهلة الاتصال', offline: true);
    } catch (_) {
      throw ApiException('لا يوجد اتصال بالخادم', offline: true);
    }
  }

  Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  /// Test connectivity to the server.
  Future<bool> ping() async {
    try {
      final res = await http.get(_uri('api/health')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
