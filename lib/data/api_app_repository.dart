import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'app_repository.dart';
import 'models/activity_entry.dart';
import 'models/modul_ajar.dart';
import 'models/teacher_profile.dart';

/// Sumber data produksi: REST API PHP yang membaca PostgreSQL.
class ApiAppRepository implements AppRepository {
  ApiAppRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.apiBaseUrl);

  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client;
  final String _baseUrl;

  /// Dipasang oleh [AppController] agar setiap permintaan membawa token login.
  String? Function()? tokenProvider;

  /// Dipanggil saat server membalas 401 supaya aplikasi kembali ke login.
  Future<void> Function()? onUnauthorized;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  @override
  Future<AppSnapshot> load() async {
    final payload = await _send('GET', '/api/bootstrap');
    if (payload is! Map) {
      throw const AppRepositoryException(
        'Respons server tidak sesuai format yang diharapkan.',
      );
    }

    final profileJson = payload['profile'];
    return AppSnapshot(
      initialized: payload['initialized'] == true,
      modules: _parseModules(payload['modules']),
      activities: _parseActivities(payload['activities']),
      profile: profileJson is Map
          ? TeacherProfile.fromJson(Map<String, dynamic>.from(profileJson))
          : TeacherProfile.contoh,
      themeMode: _parseTheme(payload['themeMode'] as String?),
    );
  }

  @override
  Future<void> saveAll({
    required List<ModulAjar> modules,
    required List<ActivityEntry> activities,
    required TeacherProfile profile,
    required ThemeMode themeMode,
  }) async {
    await _send('POST', '/api/bootstrap', {
      'modules': modules.map((modul) => modul.toJson()).toList(),
      'activities': activities.map((item) => item.toJson()).toList(),
      'profile': profile.toJson(),
      'themeMode': themeMode.name,
    });
  }

  @override
  Future<ModulAjar> createModul(ModulAjar modul) async {
    final payload = await _send('POST', '/api/modules', modul.toJson());
    return _parseModule(payload);
  }

  @override
  Future<ModulAjar> updateModul(ModulAjar modul) async {
    final payload = await _send(
      'PUT',
      '/api/modules/${Uri.encodeComponent(modul.id)}',
      modul.toJson(),
    );
    return _parseModule(payload);
  }

  @override
  Future<void> deleteModul(String id) async {
    await _send('DELETE', '/api/modules/${Uri.encodeComponent(id)}');
  }

  @override
  Future<void> restoreModul(ModulAjar modul) async {
    await _send('POST', '/api/modules', modul.toJson());
  }

  @override
  Future<void> addActivity(ActivityEntry entry) async {
    await _send('POST', '/api/activities', entry.toJson());
  }

  @override
  Future<void> clearActivities() async {
    await _send('DELETE', '/api/activities');
  }

  @override
  Future<void> saveProfile(TeacherProfile profile) async {
    await _send('PUT', '/api/profile', profile.toJson());
  }

  @override
  Future<void> saveTheme(ThemeMode mode) async {
    await _send('PUT', '/api/theme', {'themeMode': mode.name});
  }

  @override
  void close() => _client.close();

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = _uri(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
    final token = tokenProvider?.call()?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: headers).timeout(_timeout),
        'POST' =>
          await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(_timeout),
        'PUT' =>
          await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(_timeout),
        'PATCH' =>
          await _client
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(_timeout),
        'DELETE' =>
          await _client
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(_timeout),
        _ => throw AppRepositoryException('Metode $method tidak didukung.'),
      };
    } on AppRepositoryException {
      rethrow;
    } catch (error) {
      throw AppRepositoryException(
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

    if (response.statusCode == 401) {
      await onUnauthorized?.call();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Permintaan ke server gagal (HTTP ${response.statusCode}).';
      throw AppRepositoryException(message);
    }

    return decoded;
  }

  List<ModulAjar> _parseModules(dynamic value) {
    if (value is! List) return [];
    final result = <ModulAjar>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        result.add(ModulAjar.fromJson(Map<String, dynamic>.from(item)));
      } catch (error) {
        debugPrint('Melewati modul rusak dari server: $error');
      }
    }
    return result;
  }

  List<ActivityEntry> _parseActivities(dynamic value) {
    if (value is! List) return [];
    final result = <ActivityEntry>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        result.add(ActivityEntry.fromJson(Map<String, dynamic>.from(item)));
      } catch (error) {
        debugPrint('Melewati aktivitas rusak dari server: $error');
      }
    }
    return result;
  }

  ModulAjar _parseModule(dynamic value) {
    if (value is! Map) {
      throw const AppRepositoryException(
        'Respons server tidak berisi data modul.',
      );
    }
    try {
      return ModulAjar.fromJson(Map<String, dynamic>.from(value));
    } on FormatException catch (error) {
      throw AppRepositoryException(error.message);
    }
  }

  ThemeMode _parseTheme(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  static String _normalizeBaseUrl(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
