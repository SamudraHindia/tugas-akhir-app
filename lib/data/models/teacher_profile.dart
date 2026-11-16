import 'package:flutter/foundation.dart';

import '../../core/formatters.dart';

/// Profil guru yang dapat diperbarui pengguna.
@immutable
class TeacherProfile {
  const TeacherProfile({
    required this.nama,
    required this.sekolah,
    required this.nip,
    required this.email,
  });

  final String nama;
  final String sekolah;
  final String nip;
  final String email;

  static const TeacherProfile contoh = TeacherProfile(
    nama: 'Rizal Pratama',
    sekolah: 'SMA Negeri 1 Bandung',
    nip: '198705122015031004',
    email: 'rizal.pratama@sekolah.id',
  );

  String get inisial => inisialNama(nama);

  String get jabatan => 'Guru · Kurikulum Merdeka';

  TeacherProfile copyWith({
    String? nama,
    String? sekolah,
    String? nip,
    String? email,
  }) {
    return TeacherProfile(
      nama: nama ?? this.nama,
      sekolah: sekolah ?? this.sekolah,
      nip: nip ?? this.nip,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {'nama': nama, 'sekolah': sekolah, 'nip': nip, 'email': email};
  }

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    final nama = (json['nama'] as String?)?.trim();
    return TeacherProfile(
      nama: nama == null || nama.isEmpty ? contoh.nama : nama,
      sekolah: (json['sekolah'] as String?)?.trim().isNotEmpty == true
          ? (json['sekolah'] as String).trim()
          : contoh.sekolah,
      nip: (json['nip'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}
