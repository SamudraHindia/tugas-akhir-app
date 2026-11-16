import 'package:flutter/foundation.dart';

import '../../core/constants.dart';

enum ModulStatus {
  draft('Draft'),
  terbit('Terbit');

  const ModulStatus(this.label);

  final String label;

  bool get isTerbit => this == ModulStatus.terbit;

  static ModulStatus fromKey(String? key) {
    return ModulStatus.values.firstWhere(
      (status) => status.name == key,
      orElse: () => ModulStatus.draft,
    );
  }
}

/// Model utama aplikasi: satu dokumen modul ajar.
@immutable
class ModulAjar {
  const ModulAjar({
    required this.id,
    required this.judul,
    required this.mataPelajaran,
    required this.kelas,
    required this.semester,
    required this.alokasiJp,
    required this.deskripsi,
    required this.tujuanPembelajaran,
    required this.materiPokok,
    required this.kegiatanPembelajaran,
    required this.asesmen,
    required this.status,
    required this.favorit,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String judul;
  final String mataPelajaran;
  final String kelas;
  final String semester;
  final int alokasiJp;
  final String deskripsi;
  final List<String> tujuanPembelajaran;
  final List<String> materiPokok;
  final String kegiatanPembelajaran;
  final String asesmen;
  final ModulStatus status;
  final bool favorit;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fase => ModulOptions.faseUntukKelas(kelas);

  String get kelasFase => 'Kelas $kelas · Fase $fase';

  bool get isDraft => status == ModulStatus.draft;

  ModulAjar copyWith({
    String? id,
    String? judul,
    String? mataPelajaran,
    String? kelas,
    String? semester,
    int? alokasiJp,
    String? deskripsi,
    List<String>? tujuanPembelajaran,
    List<String>? materiPokok,
    String? kegiatanPembelajaran,
    String? asesmen,
    ModulStatus? status,
    bool? favorit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModulAjar(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      kelas: kelas ?? this.kelas,
      semester: semester ?? this.semester,
      alokasiJp: alokasiJp ?? this.alokasiJp,
      deskripsi: deskripsi ?? this.deskripsi,
      tujuanPembelajaran: tujuanPembelajaran ?? this.tujuanPembelajaran,
      materiPokok: materiPokok ?? this.materiPokok,
      kegiatanPembelajaran: kegiatanPembelajaran ?? this.kegiatanPembelajaran,
      asesmen: asesmen ?? this.asesmen,
      status: status ?? this.status,
      favorit: favorit ?? this.favorit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'mataPelajaran': mataPelajaran,
      'kelas': kelas,
      'semester': semester,
      'alokasiJp': alokasiJp,
      'deskripsi': deskripsi,
      'tujuanPembelajaran': tujuanPembelajaran,
      'materiPokok': materiPokok,
      'kegiatanPembelajaran': kegiatanPembelajaran,
      'asesmen': asesmen,
      'status': status.name,
      'favorit': favorit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ModulAjar.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    if (id == null || id.isEmpty) {
      throw const FormatException('Modul tanpa id tidak dapat dibaca.');
    }

    final now = DateTime.now();

    DateTime readDate(String key, DateTime fallback) {
      return DateTime.tryParse(json[key] as String? ?? '') ?? fallback;
    }

    List<String> readList(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final alokasi = (json['alokasiJp'] as num?)?.toInt() ?? 2;
    final kelas = (json['kelas'] as String?) ?? 'X';

    return ModulAjar(
      id: id,
      judul: (json['judul'] as String?)?.trim().isNotEmpty == true
          ? (json['judul'] as String).trim()
          : 'Modul tanpa judul',
      mataPelajaran:
          (json['mataPelajaran'] as String?)?.trim().isNotEmpty == true
          ? (json['mataPelajaran'] as String).trim()
          : 'Umum',
      kelas: ModulOptions.kelas.contains(kelas) ? kelas : 'X',
      semester: const ['Ganjil', 'Genap'].contains(json['semester'])
          ? json['semester'] as String
          : 'Ganjil',
      alokasiJp: alokasi.clamp(
        ModulOptions.minAlokasiJp,
        ModulOptions.maxAlokasiJp,
      ),
      deskripsi: (json['deskripsi'] as String?) ?? '',
      tujuanPembelajaran: readList('tujuanPembelajaran'),
      materiPokok: readList('materiPokok'),
      kegiatanPembelajaran: (json['kegiatanPembelajaran'] as String?) ?? '',
      asesmen: (json['asesmen'] as String?) ?? '',
      status: ModulStatus.fromKey(json['status'] as String?),
      favorit: json['favorit'] == true,
      createdAt: readDate('createdAt', now),
      updatedAt: readDate('updatedAt', now),
    );
  }

  bool cocokDengan(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return judul.toLowerCase().contains(q) ||
        mataPelajaran.toLowerCase().contains(q) ||
        kelas.toLowerCase().contains(q) ||
        deskripsi.toLowerCase().contains(q) ||
        tujuanPembelajaran.any((t) => t.toLowerCase().contains(q)) ||
        materiPokok.any((m) => m.toLowerCase().contains(q));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ModulAjar &&
            other.id == id &&
            other.judul == judul &&
            other.mataPelajaran == mataPelajaran &&
            other.kelas == kelas &&
            other.semester == semester &&
            other.alokasiJp == alokasiJp &&
            other.deskripsi == deskripsi &&
            listEquals(other.tujuanPembelajaran, tujuanPembelajaran) &&
            listEquals(other.materiPokok, materiPokok) &&
            other.kegiatanPembelajaran == kegiatanPembelajaran &&
            other.asesmen == asesmen &&
            other.status == status &&
            other.favorit == favorit &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    judul,
    mataPelajaran,
    kelas,
    semester,
    alokasiJp,
    deskripsi,
    Object.hashAll(tujuanPembelajaran),
    Object.hashAll(materiPokok),
    kegiatanPembelajaran,
    asesmen,
    status,
    favorit,
    createdAt,
    updatedAt,
  );
}
