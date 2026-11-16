import 'dart:math';

import 'package:flutter/material.dart';

import '../data/api_app_repository.dart';
import '../data/app_repository.dart';
import '../data/app_storage.dart';
import '../data/auth_repository.dart';
import '../data/auth_session_store.dart';
import '../data/local_app_repository.dart';
import '../data/models/activity_entry.dart';
import '../data/models/auth_session.dart';
import '../data/models/modul_ajar.dart';
import '../data/models/teacher_profile.dart';
import '../data/report_service.dart';
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

/// Sumber kebenaran tunggal untuk sesi login, modul, aktivitas, profil,
/// dan preferensi.
class AppController extends ChangeNotifier {
  /// Konstruktor untuk pengujian dan mode tanpa server.
  ///
  /// Mode lokal otomatis memakai sesi demo sehingga test widget tidak perlu
  /// melewati layar login.
  AppController(
    AppStorage storage, {
    DateTime Function()? now,
    ReportService? reportService,
  }) : this.withRepository(
         LocalAppRepository(storage),
         now: now,
         reportService: reportService,
       );

  /// Konstruktor produksi yang memakai REST API dan login.
  factory AppController.production() {
    final repository = ApiAppRepository();
    final reportService = ReportService();
    final controller = AppController.withRepository(
      repository,
      reportService: reportService,
      authRepository: ApiAuthRepository(),
      authSessionStore: SharedPreferencesAuthSessionStore(),
    );

    repository.tokenProvider = () => controller.session?.token;
    repository.onUnauthorized = controller.handleUnauthorized;
    reportService.tokenProvider = () => controller.session?.token;
    reportService.onUnauthorized = controller.handleUnauthorized;
    return controller;
  }

  /// Konstruktor dengan repository yang dapat diinjeksi.
  AppController.withRepository(
    this._repository, {
    DateTime Function()? now,
    ReportService? reportService,
    AuthRepository? authRepository,
    AuthSessionStore? authSessionStore,
  }) : _now = now ?? DateTime.now,
       _reportService = reportService ?? ReportService(),
       _authRepository = authRepository,
       _authSessionStore = authSessionStore;

  static const String modulesKey = AppStorageKeys.modules;
  static const String activitiesKey = AppStorageKeys.activities;
  static const String profileKey = AppStorageKeys.profile;
  static const String themeKey = AppStorageKeys.theme;
  static const String initializedKey = AppStorageKeys.initialized;

  static const int _maxActivities = 80;

  static final AuthSession _demoSession = AuthSession(
    token: 'local-demo',
    expiresAt: null,
    user: const AuthUser(
      id: 0,
      nama: 'Rizal Pratama',
      sekolah: 'SMA Negeri 1 Bandung',
      nip: '198705122015031004',
      email: 'rizal.pratama@sekolah.id',
    ),
  );

  final AppRepository _repository;
  final ReportService _reportService;
  final AuthRepository? _authRepository;
  final AuthSessionStore? _authSessionStore;
  final DateTime Function() _now;
  final Random _random = Random();

  List<ModulAjar> _modules = [];
  List<ActivityEntry> _activities = [];
  TeacherProfile _profile = TeacherProfile.contoh;
  ThemeMode _themeMode = ThemeMode.system;
  AuthSession? _session;
  bool _isReady = false;
  bool _authBusy = false;
  String? _storageError;
  String? _authError;

  bool get isReady => _isReady;
  bool get isAuthenticated => _session != null;
  bool get canLogout => _authRepository != null;
  bool get authBusy => _authBusy;
  AuthSession? get session => _session;
  String? get authError => _authError;
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
        totalJp: entry.value.fold(0, (total, modul) => total + modul.alokasiJp),
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

  /// Memulihkan sesi tersimpan lalu memuat data awal.
  Future<void> initialize() async {
    _authError = null;
    try {
      if (_authRepository == null) {
        _session = _demoSession;
      } else {
        _session = await _authSessionStore?.read();
        final current = _session;
        if (current != null) {
          if (current.isExpired) {
            await _clearSession();
            _authError = 'Sesi sudah berakhir. Silakan masuk kembali.';
          } else {
            try {
              final user = await _authRepository!.me(current.token);
              _session = AuthSession(
                token: current.token,
                expiresAt: current.expiresAt,
                user: user,
              );
              await _authSessionStore?.write(_session!);
              _profile = user.profile;
            } on AuthException catch (error) {
              await _clearSession();
              _authError = error.message;
            }
          }
        }
      }

      if (_authRepository != null && _session == null) {
        _modules = [];
        _activities = [];
        _isReady = true;
        notifyListeners();
        return;
      }

      await _loadData();
      _storageError = null;
    } catch (error, stackTrace) {
      debugPrint('Gagal memuat data: $error\n$stackTrace');
      _storageError = error is AppRepositoryException
          ? error.message
          : 'Data tidak dapat dimuat dari server. Periksa koneksi dan container Docker.';
      _modules = [];
      _activities = [];
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> muatUlang() => initialize();

  Future<void> _loadData() async {
    final now = _now();
    final snapshot = await _repository.load();
    _profile = snapshot.profile;
    _themeMode = snapshot.themeMode;

    if (!snapshot.initialized) {
      _modules = buildSeedModules(now);
      _activities = buildSeedActivities(_modules, now);
      await _repository.saveAll(
        modules: _modules,
        activities: _activities,
        profile: _profile,
        themeMode: _themeMode,
      );
    } else {
      _modules = [...snapshot.modules]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _activities = [...snapshot.activities];
    }
  }

  Future<bool> login(String email, String password) async {
    final repository = _authRepository;
    if (repository == null) {
      _session = _demoSession;
      notifyListeners();
      return true;
    }
    if (_authBusy) return false;

    _authBusy = true;
    _authError = null;
    notifyListeners();

    try {
      final session = await repository.login(
        email: email.trim(),
        password: password,
      );
      return await _applySession(session);
    } on AuthException catch (error) {
      _authError = error.message;
      return false;
    } catch (error) {
      debugPrint('Login gagal: $error');
      _authError =
          'Tidak dapat terhubung ke server. Periksa koneksi dan container Docker.';
      return false;
    } finally {
      _authBusy = false;
      _isReady = true;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nama,
    required String sekolah,
    required String email,
    required String password,
  }) async {
    final repository = _authRepository;
    if (repository == null) return login(email, password);
    if (_authBusy) return false;

    _authBusy = true;
    _authError = null;
    notifyListeners();

    try {
      final session = await repository.register(
        nama: nama.trim(),
        sekolah: sekolah.trim(),
        email: email.trim(),
        password: password,
      );
      return await _applySession(session);
    } on AuthException catch (error) {
      _authError = error.message;
      return false;
    } catch (error) {
      debugPrint('Registrasi gagal: $error');
      _authError =
          'Tidak dapat terhubung ke server. Periksa koneksi dan container Docker.';
      return false;
    } finally {
      _authBusy = false;
      _isReady = true;
      notifyListeners();
    }
  }

  Future<bool> _applySession(AuthSession session) async {
    _session = session;
    _profile = session.user.profile;
    try {
      await _authSessionStore?.write(session);
    } catch (error) {
      debugPrint('Sesi tidak dapat disimpan di perangkat: $error');
    }

    _isReady = false;
    notifyListeners();

    try {
      await _loadData();
      _storageError = null;
    } catch (error) {
      debugPrint('Data gagal dimuat setelah login: $error');
      _storageError = error is AppRepositoryException
          ? error.message
          : 'Data tidak dapat dimuat dari server.';
    }
    return true;
  }

  Future<void> logout() async {
    final token = _session?.token;
    if (_authRepository != null && token != null) {
      try {
        await _authRepository.logout(token);
      } on Exception catch (error) {
        debugPrint('Logout server gagal: $error');
      }
    }

    await _clearSession();
    _modules = [];
    _activities = [];
    _profile = TeacherProfile.contoh;
    _themeMode = ThemeMode.system;
    _storageError = null;
    _authError = null;
    notifyListeners();
  }

  /// Dipanggil repository ketika server membalas 401.
  Future<void> handleUnauthorized() async {
    if (_session == null) return;
    await _clearSession();
    _modules = [];
    _activities = [];
    _profile = TeacherProfile.contoh;
    _themeMode = ThemeMode.system;
    _storageError = null;
    _authError = 'Sesi sudah berakhir. Silakan masuk kembali.';
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _session = null;
    try {
      await _authSessionStore?.clear();
    } catch (error) {
      debugPrint('Sesi tidak dapat dihapus dari perangkat: $error');
    }
  }

  Future<ReportSummary> muatRingkasanServer() {
    return _reportService.fetchSummary();
  }

  /// Mengambil berkas CSV rekap modul milik guru yang sedang login.
  Future<String> muatCsvModul() {
    return _reportService.fetchModulesCsv();
  }

  /// Mengubah kata sandi akun yang sedang login.
  ///
  /// Mengembalikan `true` bila server menerima perubahan. Pesan kesalahan
  /// disimpan pada [authError] agar dapat ditampilkan oleh UI.
  Future<bool> ubahKataSandi({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repository = _authRepository;
    final token = _session?.token;
    if (repository == null || token == null) return false;

    _authError = null;
    try {
      await repository.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on AuthException catch (error) {
      _authError = error.message;
      notifyListeners();
      return false;
    } catch (error) {
      debugPrint('Ubah kata sandi gagal: $error');
      _authError = 'Kata sandi tidak berhasil diubah. Periksa koneksi.';
      notifyListeners();
      return false;
    }
  }

  Future<ModulAjar?> tambahModul(ModulAjar modul) async {
    final now = _now();
    final created = modul.copyWith(
      id: _newId('modul'),
      createdAt: now,
      updatedAt: now,
    );
    _modules.insert(0, created);
    final activity = _log(ActivityType.dibuat, created, now);
    notifyListeners();

    try {
      final saved = await _repository.createModul(created);
      _replaceModule(saved);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
      return saved;
    } catch (error) {
      _modules.removeWhere((item) => item.id == created.id);
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Modul tidak berhasil disimpan ke server.');
      return null;
    }
  }

  Future<ModulAjar?> perbaruiModul(ModulAjar modul) async {
    final index = _modules.indexWhere((item) => item.id == modul.id);
    if (index == -1) return null;

    final now = _now();
    final previous = _modules[index];
    final updated = modul.copyWith(updatedAt: now);
    _modules[index] = updated;
    final activity = _log(ActivityType.diperbarui, updated, now);
    notifyListeners();

    try {
      final saved = await _repository.updateModul(updated);
      _replaceModule(saved);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
      return saved;
    } catch (error) {
      if (index < _modules.length) {
        _modules[index] = previous;
      }
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Perubahan modul tidak berhasil disimpan ke server.');
      return null;
    }
  }

  Future<ModulAjar?> hapusModul(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return null;

    final removed = _modules.removeAt(index);
    final activity = _log(ActivityType.dihapus, removed, _now());
    notifyListeners();

    try {
      await _repository.deleteModul(id);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
      return removed;
    } catch (error) {
      if (!_modules.any((modul) => modul.id == removed.id)) {
        _modules.insert(min(index, _modules.length), removed);
      }
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Modul tidak berhasil dihapus dari server.');
      return null;
    }
  }

  Future<void> pulihkanModul(ModulAjar modul) async {
    if (cariModul(modul.id) != null) return;

    _modules.insert(0, modul);
    final activity = _log(ActivityType.dipulihkan, modul, _now());
    notifyListeners();

    try {
      await _repository.restoreModul(modul);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
    } catch (error) {
      _modules.removeWhere((item) => item.id == modul.id);
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Modul tidak berhasil dipulihkan di server.');
    }
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
    final activity = _log(ActivityType.diduplikasi, copy, now);
    notifyListeners();

    try {
      final saved = await _repository.createModul(copy);
      _replaceModule(saved);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
      return saved;
    } catch (error) {
      _modules.removeWhere((item) => item.id == copy.id);
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Salinan modul tidak berhasil disimpan ke server.');
      return null;
    }
  }

  Future<bool> toggleFavorit(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return false;

    final previous = _modules[index];
    final updated = previous.copyWith(favorit: !previous.favorit);
    _modules[index] = updated;
    notifyListeners();

    try {
      await _repository.updateModul(updated);
      _storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (index < _modules.length) {
        _modules[index] = previous;
      }
      _reportError(error, 'Status favorit tidak berhasil disimpan.');
      return false;
    }
  }

  Future<ModulAjar?> ubahStatus(String id) async {
    final index = _modules.indexWhere((modul) => modul.id == id);
    if (index == -1) return null;

    final previous = _modules[index];
    final next = previous.status == ModulStatus.terbit
        ? ModulStatus.draft
        : ModulStatus.terbit;
    final updated = previous.copyWith(status: next, updatedAt: _now());
    _modules[index] = updated;
    final activity = _log(
      next == ModulStatus.terbit
          ? ActivityType.diterbitkan
          : ActivityType.ditarikDraft,
      updated,
      updated.updatedAt,
    );
    notifyListeners();

    try {
      final saved = await _repository.updateModul(updated);
      _replaceModule(saved);
      await _tryAddActivity(activity);
      _storageError = null;
      notifyListeners();
      return saved;
    } catch (error) {
      if (index < _modules.length) {
        _modules[index] = previous;
      }
      _activities.removeWhere((item) => item.id == activity.id);
      _reportError(error, 'Status modul tidak berhasil disimpan ke server.');
      return null;
    }
  }

  Future<bool> hapusSemuaAktivitas() async {
    final previous = [..._activities];
    _activities.clear();
    notifyListeners();

    try {
      await _repository.clearActivities();
      _storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _activities = previous;
      _reportError(error, 'Riwayat aktivitas tidak berhasil dibersihkan.');
      return false;
    }
  }

  Future<bool> perbaruiProfil(TeacherProfile profile) async {
    final previous = _profile;
    _profile = profile;
    notifyListeners();

    try {
      await _repository.saveProfile(profile);
      final current = _session;
      if (current != null) {
        _session = AuthSession(
          token: current.token,
          expiresAt: current.expiresAt,
          user: current.user.copyWith(
            nama: profile.nama,
            sekolah: profile.sekolah,
            nip: profile.nip,
            email: profile.email,
          ),
        );
        try {
          await _authSessionStore?.write(_session!);
        } catch (error) {
          debugPrint('Sesi tidak dapat diperbarui di perangkat: $error');
        }
      }
      _storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _profile = previous;
      _reportError(error, 'Profil tidak berhasil disimpan ke server.');
      return false;
    }
  }

  Future<void> ubahTema(ThemeMode mode) async {
    if (_themeMode == mode) return;
    final previous = _themeMode;
    _themeMode = mode;
    notifyListeners();

    try {
      await _repository.saveTheme(mode);
      _storageError = null;
      notifyListeners();
    } catch (error) {
      _themeMode = previous;
      _reportError(error, 'Preferensi tema tidak berhasil disimpan.');
    }
  }

  Future<bool> muatDataContoh() async {
    final now = _now();
    final previousModules = [..._modules];
    final previousActivities = [..._activities];
    _modules = buildSeedModules(now);
    _activities = buildSeedActivities(_modules, now);
    notifyListeners();

    try {
      await _repository.saveAll(
        modules: _modules,
        activities: _activities,
        profile: _profile,
        themeMode: _themeMode,
      );
      _storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _modules = previousModules;
      _activities = previousActivities;
      _reportError(error, 'Data contoh tidak berhasil disimpan ke server.');
      return false;
    }
  }

  Future<bool> hapusSemuaModul() async {
    final previousModules = [..._modules];
    final previousActivities = [..._activities];
    _modules.clear();
    _activities.clear();
    notifyListeners();

    try {
      await _repository.saveAll(
        modules: const [],
        activities: const [],
        profile: _profile,
        themeMode: _themeMode,
      );
      _storageError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _modules = previousModules;
      _activities = previousActivities;
      _reportError(error, 'Data tidak berhasil dihapus dari server.');
      return false;
    }
  }

  Future<void> _tryAddActivity(ActivityEntry entry) async {
    try {
      await _repository.addActivity(entry);
    } catch (error) {
      debugPrint('Aktivitas gagal disimpan: $error');
    }
  }

  void _replaceModule(ModulAjar modul) {
    final index = _modules.indexWhere((item) => item.id == modul.id);
    if (index == -1) return;
    _modules[index] = modul;
  }

  String _newId(String prefix) {
    final timestamp = _now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(100000).toString().padLeft(5, '0');
    return '${prefix}_${timestamp}_$suffix';
  }

  ActivityEntry _log(ActivityType type, ModulAjar modul, DateTime timestamp) {
    final entry = ActivityEntry(
      id: _newId('aktivitas'),
      type: type,
      modulId: modul.id,
      judulModul: modul.judul,
      timestamp: timestamp,
    );
    _activities.insert(0, entry);
    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }
    return entry;
  }

  void _reportError(Object error, String fallback) {
    debugPrint('Operasi data gagal: $error');
    _storageError = error is AppRepositoryException ? error.message : fallback;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.close();
    _reportService.close();
    _authRepository?.close();
    super.dispose();
  }
}
