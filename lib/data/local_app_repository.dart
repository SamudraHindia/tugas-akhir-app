import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_repository.dart';
import 'app_storage.dart';
import 'models/activity_entry.dart';
import 'models/modul_ajar.dart';
import 'models/teacher_profile.dart';

/// Penyimpanan lokal berbasis [AppStorage].
///
/// Dipakai oleh pengujian dan sebagai fallback ketika aplikasi dijalankan
/// tanpa backend.
class LocalAppRepository implements AppRepository {
  LocalAppRepository(this._storage);

  static const int _maxActivities = 80;

  final AppStorage _storage;

  List<ModulAjar> _modules = [];
  List<ActivityEntry> _activities = [];
  TeacherProfile _profile = TeacherProfile.contoh;
  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  @override
  Future<AppSnapshot> load() async {
    final values = await Future.wait<String?>([
      _storage.read(AppStorageKeys.initialized),
      _storage.read(AppStorageKeys.modules),
      _storage.read(AppStorageKeys.activities),
      _storage.read(AppStorageKeys.profile),
      _storage.read(AppStorageKeys.theme),
    ]);

    final initializedRaw = values[0];
    final modulesRaw = values[1];
    // Data lama belum memiliki penanda initialized. Keberadaan kunci modul
    // tetap dianggap sebagai sudah pernah diinisialisasi.
    _initialized = initializedRaw == '1' || modulesRaw != null;
    _modules = _decodeList(modulesRaw, ModulAjar.fromJson);
    _activities = _decodeList(values[2], ActivityEntry.fromJson);
    _profile = _decodeProfile(values[3]);
    _themeMode = _decodeTheme(values[4]);

    return AppSnapshot(
      initialized: _initialized,
      modules: List.unmodifiable(_modules),
      activities: List.unmodifiable(_activities),
      profile: _profile,
      themeMode: _themeMode,
    );
  }

  @override
  Future<void> saveAll({
    required List<ModulAjar> modules,
    required List<ActivityEntry> activities,
    required TeacherProfile profile,
    required ThemeMode themeMode,
  }) async {
    _modules = [...modules];
    _activities = [...activities];
    _profile = profile;
    _themeMode = themeMode;
    _initialized = true;

    await Future.wait([
      _persistModules(),
      _persistActivities(),
      _persistProfile(),
      _persistTheme(),
      _storage.write(AppStorageKeys.initialized, '1'),
    ]);
  }

  @override
  Future<ModulAjar> createModul(ModulAjar modul) async {
    _modules.insert(0, modul);
    await _persistModules();
    await _markInitialized();
    return modul;
  }

  @override
  Future<ModulAjar> updateModul(ModulAjar modul) async {
    final index = _modules.indexWhere((item) => item.id == modul.id);
    if (index == -1) {
      throw const AppRepositoryException('Modul tidak ditemukan.');
    }

    _modules[index] = modul;
    await _persistModules();
    return modul;
  }

  @override
  Future<void> deleteModul(String id) async {
    _modules.removeWhere((item) => item.id == id);
    await _persistModules();
  }

  @override
  Future<void> restoreModul(ModulAjar modul) async {
    if (_modules.any((item) => item.id == modul.id)) return;
    _modules.insert(0, modul);
    await _persistModules();
    await _markInitialized();
  }

  @override
  Future<void> addActivity(ActivityEntry entry) async {
    _activities.insert(0, entry);
    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }
    await _persistActivities();
    await _markInitialized();
  }

  @override
  Future<void> clearActivities() async {
    _activities.clear();
    await _persistActivities();
  }

  @override
  Future<void> saveProfile(TeacherProfile profile) async {
    _profile = profile;
    await _persistProfile();
    await _markInitialized();
  }

  @override
  Future<void> saveTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _persistTheme();
    await _markInitialized();
  }

  @override
  void close() {}

  Future<void> _markInitialized() async {
    _initialized = true;
    await _storage.write(AppStorageKeys.initialized, '1');
  }

  Future<void> _persistModules() {
    return _storage.write(
      AppStorageKeys.modules,
      jsonEncode(_modules.map((modul) => modul.toJson()).toList()),
    );
  }

  Future<void> _persistActivities() {
    return _storage.write(
      AppStorageKeys.activities,
      jsonEncode(_activities.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _persistProfile() {
    return _storage.write(
      AppStorageKeys.profile,
      jsonEncode(_profile.toJson()),
    );
  }

  Future<void> _persistTheme() {
    return _storage.write(AppStorageKeys.theme, _themeMode.name);
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final result = <T>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          result.add(fromJson(Map<String, dynamic>.from(item)));
        } catch (error) {
          debugPrint('Melewati data rusak: $error');
        }
      }
      return result;
    } catch (error) {
      debugPrint('Gagal membaca JSON: $error');
      return [];
    }
  }

  TeacherProfile _decodeProfile(String? raw) {
    if (raw == null || raw.trim().isEmpty) return TeacherProfile.contoh;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return TeacherProfile.fromJson(decoded);
      }
      if (decoded is Map) {
        return TeacherProfile.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (error) {
      debugPrint('Gagal membaca profil: $error');
    }

    return TeacherProfile.contoh;
  }

  ThemeMode _decodeTheme(String? raw) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}
