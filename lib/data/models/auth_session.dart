import 'package:flutter/foundation.dart';

import 'teacher_profile.dart';

/// Data akun guru yang sedang masuk.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.nama,
    required this.sekolah,
    required this.nip,
    required this.email,
  });

  final int id;
  final String nama;
  final String sekolah;
  final String nip;
  final String email;

  TeacherProfile get profile => TeacherProfile(
    nama: nama,
    sekolah: sekolah,
    nip: nip,
    email: email,
  );

  AuthUser copyWith({
    String? nama,
    String? sekolah,
    String? nip,
    String? email,
  }) {
    return AuthUser(
      id: id,
      nama: nama ?? this.nama,
      sekolah: sekolah ?? this.sekolah,
      nip: nip ?? this.nip,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'sekolah': sekolah,
      'nip': nip,
      'email': email,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String text(String key, String fallback) {
      final value = (json[key] as String?)?.trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nama: text('nama', 'Guru'),
      sekolah: text('sekolah', ''),
      nip: (json['nip'] as String?) ?? '',
      email: text('email', ''),
    );
  }
}

/// Token sesi yang disimpan di perangkat agar pengguna tidak perlu login
/// ulang setiap membuka aplikasi.
@immutable
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime? expiresAt;
  final AuthUser user;

  bool get isExpired {
    final limit = expiresAt;
    return limit != null && !limit.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt?.toIso8601String(),
      'user': user.toJson(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] as String?)?.trim();
    final user = json['user'];
    if (token == null || token.isEmpty || user is! Map) {
      throw const FormatException('Sesi login tidak valid.');
    }

    return AuthSession(
      token: token,
      expiresAt: DateTime.tryParse((json['expiresAt'] as String?) ?? ''),
      user: AuthUser.fromJson(Map<String, dynamic>.from(user)),
    );
  }
}
