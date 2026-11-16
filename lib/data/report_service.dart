import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'app_repository.dart';

class MapelReport {
  const MapelReport({
    required this.mataPelajaran,
    required this.total,
    required this.terbit,
    required this.totalJp,
  });

  final String mataPelajaran;
  final int total;
  final int terbit;
  final int totalJp;
}

/// Rekap yang dihitung oleh layanan Python (FastAPI).
class ReportSummary {
  const ReportSummary({
    required this.totalModul,
    required this.totalTerbit,
    required this.totalDraft,
    required this.totalFavorit,
    required this.totalJp,
    required this.totalAktivitas,
    required this.perMapel,
  });

  final int totalModul;
  final int totalTerbit;
  final int totalDraft;
  final int totalFavorit;
  final int totalJp;
  final int totalAktivitas;
  final List<MapelReport> perMapel;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final rawMapel = json['perMapel'];
    final perMapel = <MapelReport>[];
    if (rawMapel is List) {
      for (final item in rawMapel) {
        if (item is! Map) continue;
        perMapel.add(
          MapelReport(
            mataPelajaran: (item['mataPelajaran'] as String?) ?? 'Umum',
            total: (item['total'] as num?)?.toInt() ?? 0,
            terbit: (item['terbit'] as num?)?.toInt() ?? 0,
            totalJp: (item['totalJp'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    }

    return ReportSummary(
      totalModul: (json['totalModul'] as num?)?.toInt() ?? 0,
      totalTerbit: (json['totalTerbit'] as num?)?.toInt() ?? 0,
      totalDraft: (json['totalDraft'] as num?)?.toInt() ?? 0,
      totalFavorit: (json['totalFavorit'] as num?)?.toInt() ?? 0,
      totalJp: (json['totalJp'] as num?)?.toInt() ?? 0,
      totalAktivitas: (json['totalAktivitas'] as num?)?.toInt() ?? 0,
      perMapel: List.unmodifiable(perMapel),
    );
  }
}

/// Klien untuk layanan laporan Python.
class ReportService {
  ReportService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.reportBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  /// Dipasang oleh [AppController] agar rekap hanya memuat data guru yang login.
  String? Function()? tokenProvider;

  /// Dipanggil saat layanan laporan membalas 401.
  Future<void> Function()? onUnauthorized;

  String get csvUrl => '$_baseUrl/report/modules.csv';

  Future<ReportSummary> fetchSummary() async {
    final uri = Uri.parse('$_baseUrl/report/summary');
    final headers = <String, String>{'Accept': 'application/json'};
    final token = tokenProvider?.call()?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw AppRepositoryException(
        'Layanan laporan Python tidak dapat dihubungi ($_baseUrl). '
        'Pastikan container Docker sudah berjalan.',
      );
    }

    if (response.statusCode == 401) {
      await onUnauthorized?.call();
      throw const AppRepositoryException(
        'Sesi sudah berakhir. Silakan masuk kembali untuk memuat laporan.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppRepositoryException(
        'Layanan laporan mengembalikan HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const AppRepositoryException('Format laporan tidak dikenali.');
    }

    return ReportSummary.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// Mengambil isi CSV rekap modul untuk guru yang sedang login.
  Future<String> fetchModulesCsv() async {
    final headers = <String, String>{'Accept': 'text/csv'};
    final token = tokenProvider?.call()?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      response = await _client
          .get(Uri.parse(csvUrl), headers: headers)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      throw AppRepositoryException(
        'Layanan laporan Python tidak dapat dihubungi ($_baseUrl). '
        'Pastikan container Docker sudah berjalan.',
      );
    }

    if (response.statusCode == 401) {
      await onUnauthorized?.call();
      throw const AppRepositoryException(
        'Sesi sudah berakhir. Silakan masuk kembali untuk mengekspor data.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppRepositoryException(
        'Ekspor CSV gagal (HTTP ${response.statusCode}).',
      );
    }

    return response.body;
  }

  void close() => _client.close();

  static String _normalizeBaseUrl(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
