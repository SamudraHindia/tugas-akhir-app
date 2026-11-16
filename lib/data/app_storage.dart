import 'package:shared_preferences/shared_preferences.dart';

/// Abstraksi penyimpanan agar controller mudah diuji tanpa plugin platform.
abstract interface class AppStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Implementasi produksi menggunakan SharedPreferences.
class SharedPreferencesStorage implements AppStorage {
  SharedPreferencesStorage([this._preferences]);

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> read(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _instance();
    await prefs.remove(key);
  }
}

/// Penyimpanan in-memory untuk pengujian dan fallback.
class InMemoryStorage implements AppStorage {
  InMemoryStorage([Map<String, String>? initial])
    : _data = {...?initial};

  final Map<String, String> _data;

  Map<String, String> get values => Map.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
