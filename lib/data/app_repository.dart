import 'package:flutter/material.dart';

import 'models/activity_entry.dart';
import 'models/modul_ajar.dart';
import 'models/teacher_profile.dart';

/// Kondisi awal aplikasi yang dibaca dari penyimpanan atau server.
@immutable
class AppSnapshot {
  const AppSnapshot({
    required this.initialized,
    required this.modules,
    required this.activities,
    required this.profile,
    required this.themeMode,
  });

  final bool initialized;
  final List<ModulAjar> modules;
  final List<ActivityEntry> activities;
  final TeacherProfile profile;
  final ThemeMode themeMode;
}

/// Kontrak sumber data aplikasi.
///
/// Implementasi produksi memakai REST API PHP, sedangkan implementasi lokal
/// dipakai untuk pengujian dan fallback tanpa server.
abstract interface class AppRepository {
  Future<AppSnapshot> load();

  Future<void> saveAll({
    required List<ModulAjar> modules,
    required List<ActivityEntry> activities,
    required TeacherProfile profile,
    required ThemeMode themeMode,
  });

  Future<ModulAjar> createModul(ModulAjar modul);
  Future<ModulAjar> updateModul(ModulAjar modul);
  Future<void> deleteModul(String id);
  Future<void> restoreModul(ModulAjar modul);

  Future<void> addActivity(ActivityEntry entry);
  Future<void> clearActivities();

  Future<void> saveProfile(TeacherProfile profile);
  Future<void> saveTheme(ThemeMode mode);

  void close();
}

/// Kesalahan yang berasal dari API atau penyimpanan data.
class AppRepositoryException implements Exception {
  const AppRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
