import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_akhir_app/core/constants.dart';
import 'package:tugas_akhir_app/data/models/modul_ajar.dart';

ModulAjar _contohModul() {
  return ModulAjar(
    id: 'modul-1',
    judul: 'Persamaan Kuadrat',
    mataPelajaran: 'Matematika',
    kelas: 'X',
    semester: 'Ganjil',
    alokasiJp: 8,
    deskripsi: 'Deskripsi modul untuk pengujian serialisasi data.',
    tujuanPembelajaran: const ['Tujuan satu', 'Tujuan dua'],
    materiPokok: const ['Materi satu'],
    kegiatanPembelajaran: 'Kegiatan pembelajaran di kelas.',
    asesmen: 'Asesmen formatif.',
    status: ModulStatus.terbit,
    favorit: true,
    createdAt: DateTime(2026, 11, 1, 8, 30),
    updatedAt: DateTime(2026, 11, 16, 9, 45),
  );
}

void main() {
  group('ModulAjar', () {
    test('serialisasi JSON bolak-balik tetap sama', () {
      final modul = _contohModul();
      final hasil = ModulAjar.fromJson(modul.toJson());

      expect(hasil, modul);
      expect(hasil.fase, 'E');
      expect(hasil.kelasFase, 'Kelas X · Fase E');
    });

    test('data JSON yang tidak lengkap tetap dibaca dengan aman', () {
      final hasil = ModulAjar.fromJson({
        'id': 'modul-2',
        'judul': '  Modul Minimal  ',
        'alokasiJp': 9999,
        'kelas': 'XIII',
        'semester': 'Tidak diketahui',
        'status': 'status-aneh',
        'tujuanPembelajaran': ['  Tujuan  ', '', 12, null],
        'materiPokok': null,
      });

      expect(hasil.judul, 'Modul Minimal');
      expect(hasil.alokasiJp, ModulOptions.maxAlokasiJp);
      expect(hasil.kelas, 'X');
      expect(hasil.semester, 'Ganjil');
      expect(hasil.status, ModulStatus.draft);
      expect(hasil.tujuanPembelajaran, ['Tujuan']);
      expect(hasil.materiPokok, isEmpty);
      expect(hasil.deskripsi, isEmpty);
      expect(hasil.favorit, isFalse);
    });

    test('modul tanpa id ditolak', () {
      expect(
        () => ModulAjar.fromJson({'id': '  ', 'judul': 'Tanpa id'}),
        throwsFormatException,
      );
    });

    test('pencarian mencakup judul, mapel, dan materi', () {
      final modul = _contohModul();

      expect(modul.cocokDengan('kuadrat'), isTrue);
      expect(modul.cocokDengan('matematika'), isTrue);
      expect(modul.cocokDengan('materi satu'), isTrue);
      expect(modul.cocokDengan('biologi'), isFalse);
      expect(modul.cocokDengan('   '), isTrue);
    });
  });
}
