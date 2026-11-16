import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/models/activity_entry.dart';
import '../data/models/modul_ajar.dart';
import '../data/models/teacher_profile.dart';
import '../data/seed_data.dart';

enum ModulFilter {
  semua('Semua'),
  terbit('Terbit'),
  draft('Draft'),
  favorit('Favorit');

  const ModulFilter(this.label);

  final String label;
}

enum ModulSort {
  terbaru('Terbaru diperbarui'),
  terlama('Terlama diperbarui'),
  judul('Judul A-Z'),
  alokasi('Alokasi JP terbanyak');

  const ModulSort(this.label);

  final String label;
}

@immutable
class MapelSummary {
  const MapelSummary({
    required this.mapel,
    required this.total,
    required this.terbit,
    required this.totalJp,
  });

  final String mapel;
  final int total;
  final int terbit;
  final int totalJp;

  double get progress => total == 0 ? 0 : terbit / total;
}

/// Sumber kebenaran tunggal untuk modul, aktivitas, profil, dan preferensi.
class AppController extends ChangeNotifier {
  AppController(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const String modulesKey = 'modulajar.modules.v1';
  static const String activitiesKey = 'modulajar.activities.v1';
  static const String profileKey = 'modulajar.profile.v1';
  static const String themeKey = 'modulajar.theme.v1';

  static const int _maxActivities = 80;

  final AppStorage _storage;
  final DateTime Function() _now;
  final Random _random = Random();

  List<ModulAjar> _modules = [];
  List<ActivityEntry> _activities = [];
  TeacherProfile _profile = TeacherProfile.contoh;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isReady = false;
  String? _storageError;

  bool get isReady => _isReady;
  String? get storageError => _storageError;
  TeacherProfile get profile => _profile;
  ThemeMode get themeMode => _themeMode;

  List<ModulAjar> get modules => List.unmodifiable(_modules);
  List<ActivityEntry> get activities => List.unmodifiable(_activities);

  int get totalModul => _modules.length;
  int get totalTerbit =>
      _modules.where((modul) => modul.status == ModulStatus.terbit).length;
  int get totalDraft =>
      _modules.where((modul) => modul.status == ModulStatus.draft).length;
  int get totalFavorit => _modules.where((modul) => modul.favorit).length;
  int get totalJp =>
      _modules.fold(0, (total, modul) => total + modul.alokasiJp);

  List<ModulAjar> get modulTerbaru {
    final sorted = [..._modules]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(sorted);
  }

  List<String> get daftarMapel {
    final mapel = _modules.map((modul) => modul.mataPelajaran).toSet().toList()
      ..sort();
    return List.unmodifiable(mapel);
  }

  List<MapelSummary> get ringkasanMapel {
    final groups = <String, List<ModulAjar>>{};
    for (final modul in _modules) {
      groups.putIfAbsent(modul.mataPelajaran, () => []).add(modul);
    }

    final summaries = groups.entries.map((entry) {
      return MapelSummary(
        mapel: entry.key,
        total: entry.value.length,
        terbit: entry.value
            .where((modul) => modul.status == ModulStatus.terbit)
            .length,
        totalJp: entry.value.fold(
          0,
          (total, modul) => total + modul.alokasiJp,
        ),
      );
    }).toList();

    summaries.sort((a, b) {
      final byTotal = b.total.compareTo(a.total);
      return byTotal != 0 ? byTotal : a.mapel.compareTo(b.mapel);
    });
    return List.unmodifiable(summaries);
  }

  ModulAjar? cariModul(String id) {
    for (final modul in _modules) {
      if (modul.id == id) return modul;
    }
    return null;
  }

  /// Filter dan urutkan modul untuk halaman daftar/pencarian.
  List<ModulAjar> filterModul({
    String query = '',
    ModulFilter filter = ModulFilter.semua,
    String? mapel,
    String? kelas,
    ModulSort sort = ModulSort.terbaru,
  }) {
    Iterable<ModulAjar> result = _modules.where(
      (modul) => modul.cocokDengan(query),
    );

    switch (filter) {
      case ModulFilter.semua:
        break;
      case ModulFilter.terbit:
        result = result.where((modul) => modul.status == ModulStatus.terbit);
      case ModulFilter.draft:
        result = result.where((modul) => modul.status == ModulStatus.draft);
      case ModulFilter.favorit:
        result = result.where((modul) => modul.favorit);
    }

    if (mapel != null && mapel.isNotEmpty) {
      result = result.where((modul) => modul.mataPelajaran == mapel);
    }
    if (kelas != null && kelas.isNotEmpty) {
      result = result.where((modul) => modul.kelas == kelas);
    }

    final list = result.toList();
    switch (sort) {
      case ModulSort.terbaru:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ModulSort.terlama:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case ModulSort.judul:
        list.sort(
          (a, b) => a.judul.toLowerCase().compareTo(b.judul.toLowerCase()),
        );
      case ModulSort.alokasi:
        list.sort((a, b) {
          final byJp = b.alokasiJp.compareTo(a.alokasiJp);
          return byJp != 0
              ? byJp
              : a.judul.toLowerCase().compareTo(b.judul.toLowerCase());
        });
    }
    return list;
  }

  Future<void> initialize() async {
    final now = _now();
    try {
      final raw = await Future.wait<String?>([
        _storage.read(modulesKey),
        _storage.read(activitiesKey),
        _storage.read(profileKey),
        _storage.read(themeKey),
      ]);

      final modulesRaw = raw[0];
      final activitiesRaw = raw[1];
      final profileRaw = raw[2];
      final themeRaw = raw[3];

      if (modulesRaw == null) {
        _modules = buildSeedModules(now);
        _activities = buildSeedActivities(_modules, now);
        await _writeModulesAndActivities();
      } else {
        _modules = _decodeList(modulesRaw, ModulAjar.fromJson);
        _activities = _decodeList(activitiesRaw, ActivityEntry.fromJson);
        _modules.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      if (profileRaw != null) {
        try {
          final decoded = jsonDecode(profileRaw);
          if (decoded is Map<String, dynamic>) {
            _profile = TeacherProfile.fromJson(decoded);
          }
        } catch (_) {
          _profile = TeacherProfile.contoh;
        }
      }

      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeRaw,
        orElse: () => ThemeMode.system,
      );
      _storageError = null;
    } catch (error, stackTrace) {
      debugPrint('Gagal memuat data lokal: $error\n$stackTrace');
      _storageError =
          'Data lokal tidak dapat dibaca. Aplikasi memakai data contoh sementara.';
      _modules = buildSeedModules(now);
      _activities = buildSeedActivities(_modules, now);
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<ModulAjar> tambahModul(ModulAjar modul) async {
    final now = _now();
    final created = modul.copyWith(
      id: _newId('modul'),
      createdAt: now,
      updatedAt: now,
    );
    _modules.insert(0, created);
    _log(ActivityType.dibuat, created, now);
    notifyListeners();
    await _writeModulesAndActivities();
    return created;
  }

  Future<ModulAjar?> perbaruiModul(ModulAjar modul) async {
    final index = _modules.indexWhere((item) => item.id == modul.id);
    if (index == -1) return null;

    final now = _now();
    final updated = modul.copyWith(updatedAt: now);
    _modules[index] = updated;
    _log(ActivityType.diperbarui, updated, now);
    notifyListeners();
    await _writeModulesAndActivities();
    return updated;
  }

  Future<ModulAjar?> hapusModul(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return null;

    final removed = _modules.removeAt(index);
    _log(ActivityType.dihapus, removed, _now());
    notifyListeners();
    await _writeModulesAndActivities();
    return removed;
  }

  Future<void> pulihkanModul(ModulAjar modul) async {
    if (cariModul(modul.id) != null) return;
    _modules.insert(0, modul);
    _log(ActivityType.dipulihkan, modul, _now());
    notifyListeners();
    await _writeModulesAndActivities();
  }

  Future<ModulAjar?> duplikatModul(String id) async {
    final original = cariModul(id);
    if (original == null) return null;

    final now = _now();
    final baseTitle = original.judul.length > 100
        ? original.judul.substring(0, 100)
        : original.judul;
    final copy = original.copyWith(
      id: _newId('modul'),
      judul: '$baseTitle (Salinan)',
      status: ModulStatus.draft,
      favorit: false,
      createdAt: now,
      updatedAt: now,
    );

    final index = _modules.indexWhere((modul) => modul.id == id);
    _modules.insert(index == -1 ? 0 : index + 1, copy);
    _log(ActivityType.diduplikasi, copy, now);
    notifyListeners();
    await _writeModulesAndActivities();
    return copy;
  }

  Future<void> toggleFavorit(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return;

    _modules[index] = _modules[index].copyWith(
      favorit: !_modules[index].favorit,
    );
    notifyListeners();
    await _writeModules();
  }

  Future<ModulAjar?> ubahStatus(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return null;

    final current = _modules[index];
    final next = current.status == ModulStatus.terbit
        ? ModulStatus.draft
        : ModulStatus.terbit;
    final updated = current.copyWith(status: next, updatedAt: _now());
    _modules[index] = updated;
    _log(
      next == ModulStatus.terbit
          ? ActivityType.diterbitkan
          : ActivityType.ditarikDraft,
      updated,
      updated.updatedAt,
    );
    notifyListeners();
    await _writeModulesAndActivities();
    return updated;
  }

  Future<void> hapusSemuaAktivitas() async {
    _activities.clear();
    notifyListeners();
    await _persist(activitiesKey, jsonEncode(const []));
  }

  Future<void> perbaruiProfil(TeacherProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _persist(profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> ubahTema(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist(themeKey, mode.name);
  }

  Future<void> muatDataContoh() async {
    final now = _now();
    _modules = buildSeedModules(now);
    _activities = buildSeedActivities(_modules, now);
    notifyListeners();
    await _writeModulesAndActivities();
  }

  Future<void> hapusSemuaModul() async {
    _modules.clear();
    _activities.clear();
    notifyListeners();
    await _writeModulesAndActivities();
  }

  String _newId(String prefix) {
    final timestamp = _now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(100000).toString().padLeft(5, '0');
    return '${prefix}_${timestamp}_$suffix';
  }

  void _log(ActivityType type, ModulAjar modul, DateTime timestamp) {
    _activities.insert(
      0,
      ActivityEntry(
        id: _newId('aktivitas'),
        type: type,
        modulId: modul.id,
        judulModul: modul.judul,
        timestamp: timestamp,
      ),
    );
    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }
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

  Future<void> _writeModulesAndActivities() async {
    await Future.wait([
      _persist(
        modulesKey,
        jsonEncode(_modules.map((modul) => modul.toJson()).toList()),
      ),
      _persist(
        activitiesKey,
        jsonEncode(_activities.map((item) => item.toJson()).toList()),
      ),
    ]);
  }

  Future<void> _writeModules() async {
    await _persist(
      modulesKey,
      jsonEncode(_modules.map((modul) => modul.toJson()).toList()),
    );
  }

  Future<void> _persist(String key, String value) async {
    try {
      await _storage.write(key, value);
      if (_storageError != null) {
        _storageError = null;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan "$key": $error\n$stackTrace');
      _storageError = 'Perubahan gagal disimpan ke penyimpanan lokal.';
      notifyListeners();
    }
  }
}
