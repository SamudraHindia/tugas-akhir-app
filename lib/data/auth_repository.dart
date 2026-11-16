import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'models/auth_session.dart';

/// Kesalahan autentikasi yang pesannya aman ditampilkan ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kontrak layanan login/register/logout dan perubahan kata sandi.
abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String nama,
    required String sekolah,
    required String email,
    required String password,
  });

  Future<AuthUser> me(String token);

  Future<void> logout(String token);

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });

  void close();
}

/// Implementasi autentikasi terhadap REST API PHP.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.apiBaseUrl);

  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _send(
      'POST',
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    return _parseSession(payload);
  }

  @override
  Future<AuthSession> register({
    required String nama,
    required String sekolah,
    required String email,
    required String password,
  }) async {
    final payload = await _send(
      'POST',
      '/api/auth/register',
      body: {
        'nama': nama,
        'sekolah': sekolah,
        'email': email,
        'password': password,
      },
    );
    return _parseSession(payload);
  }

  @override
  Future<AuthUser> me(String token) async {
    final payload = await _send('GET', '/api/auth/me', token: token);
    final user = payload is Map ? payload['user'] : null;
    if (user is! Map) {
      throw const AuthException('Data akun tidak dikenali.');
    }
    return AuthUser.fromJson(Map<String, dynamic>.from(user));
  }

  @override
  Future<void> logout(String token) async {
    await _send('POST', '/api/auth/logout', token: token);
  }

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _send(
      'POST',
      '/api/auth/change-password',
      token: token,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  void close() => _client.close();

  AuthSession _parseSession(dynamic payload) {
    if (payload is! Map) {
      throw const AuthException('Respons login tidak sesuai format.');
    }
    try {
      return AuthSession.fromJson(Map<String, dynamic>.from(payload));
    } on FormatException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = _uri(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: headers).timeout(_timeout),
        'POST' =>
          await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout),
        _ => throw AuthException('Metode $method tidak didukung.'),
      };
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Tidak dapat terhubung ke server ($_baseUrl). '
        'Pastikan container Docker sudah berjalan.',
      );
    }

    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Permintaan gagal (HTTP ${response.statusCode}).';
      throw AuthException(message);
    }

    return decoded;
  }

  static String _normalizeBaseUrl(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
