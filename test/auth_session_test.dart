import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_akhir_app/data/models/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('serialisasi bolak-balik mempertahankan data sesi', () {
      final session = AuthSession(
        token: 'token-uji',
        expiresAt: DateTime.utc(2026, 12, 1, 8, 30),
        user: const AuthUser(
          id: 7,
          nama: 'Guru Penguji',
          sekolah: 'SMA Pengujian',
          nip: '198705122015031004',
          email: 'guru@sekolah.id',
        ),
      );

      final restored = AuthSession.fromJson(session.toJson());

      expect(restored.token, 'token-uji');
      expect(restored.expiresAt, DateTime.utc(2026, 12, 1, 8, 30));
      expect(restored.user.id, 7);
      expect(restored.user.nama, 'Guru Penguji');
      expect(restored.user.sekolah, 'SMA Pengujian');
      expect(restored.user.nip, '198705122015031004');
      expect(restored.user.email, 'guru@sekolah.id');
    });

    test('user diturunkan menjadi profil guru', () {
      const user = AuthUser(
        id: 1,
        nama: 'Rizal Pratama',
        sekolah: 'SMA Negeri 1 Bandung',
        nip: '198705122015031004',
        email: 'demo@modulajar.local',
      );

      final profile = user.profile;
      expect(profile.nama, 'Rizal Pratama');
      expect(profile.sekolah, 'SMA Negeri 1 Bandung');
      expect(profile.email, 'demo@modulajar.local');
    });

    test('sesi tanpa token dianggap tidak valid', () {
      expect(
        () => AuthSession.fromJson({
          'token': '',
          'user': {'nama': 'Guru'},
        }),
        throwsFormatException,
      );
      expect(
        () => AuthSession.fromJson({'token': 'abc'}),
        throwsFormatException,
      );
    });

    test('isExpired mengikuti waktu kedaluwarsa', () {
      final expired = AuthSession(
        token: 'abc',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        user: const AuthUser(
          id: 1,
          nama: 'Guru',
          sekolah: 'Sekolah',
          nip: '',
          email: 'guru@sekolah.id',
        ),
      );
      final aktif = AuthSession(
        token: 'abc',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        user: expired.user,
      );

      expect(expired.isExpired, isTrue);
      expect(aktif.isExpired, isFalse);
    });

    test('copyWith hanya mengganti data yang diberikan', () {
      const user = AuthUser(
        id: 2,
        nama: 'Nama Lama',
        sekolah: 'Sekolah Lama',
        nip: '',
        email: 'lama@sekolah.id',
      );

      final updated = user.copyWith(nama: 'Nama Baru');

      expect(updated.id, 2);
      expect(updated.nama, 'Nama Baru');
      expect(updated.sekolah, 'Sekolah Lama');
      expect(updated.email, 'lama@sekolah.id');
    });
  });
}
