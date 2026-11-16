import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/auth_session.dart';

/// Penyimpanan sesi login di perangkat.
abstract interface class AuthSessionStore {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// Implementasi produksi memakai SharedPreferences.
///
/// Catatan: token tidak dienkripsi. Untuk produksi gunakan
/// `flutter_secure_storage` atau penyimpanan terenkripsi platform.
class SharedPreferencesAuthSessionStore implements AuthSessionStore {
  SharedPreferencesAuthSessionStore([this._preferences]);

  static const String sessionKey = 'modulajar.session.v1';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AuthSession?> read() async {
    final prefs = await _instance();
    final raw = prefs.getString(sessionKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(sessionKey);
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final prefs = await _instance();
    await prefs.setString(sessionKey, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _instance();
    await prefs.remove(sessionKey);
  }
}

/// Penyimpanan in-memory untuk pengujian.
class InMemoryAuthSessionStore implements AuthSessionStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
