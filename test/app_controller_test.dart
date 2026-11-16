import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_akhir_app/data/app_storage.dart';
import 'package:tugas_akhir_app/data/models/activity_entry.dart';
import 'package:tugas_akhir_app/data/models/modul_ajar.dart';
import 'package:tugas_akhir_app/data/models/teacher_profile.dart';
import 'package:tugas_akhir_app/state/app_controller.dart';

ModulAjar _modulBaru({String judul = 'Modul Uji'}) {
  final now = DateTime(2026, 11, 16, 10);
  return ModulAjar(
    id: 'draft',
    judul: judul,
    mataPelajaran: 'Informatika',
    kelas: 'X',
    semester: 'Ganjil',
    alokasiJp: 4,
    deskripsi: 'Deskripsi modul uji yang cukup panjang.',
    tujuanPembelajaran: const ['Tujuan pembelajaran uji'],
    materiPokok: const ['Materi uji'],
    kegiatanPembelajaran: 'Kegiatan pembelajaran uji di kelas.',
    asesmen: 'Asesmen uji.',
    status: ModulStatus.draft,
    favorit: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('AppController', () {
    late InMemoryStorage storage;
    late AppController controller;

    setUp(() async {
      storage = InMemoryStorage();
      controller = AppController(
        storage,
        now: () => DateTime(2026, 11, 16, 10),
      );
      await controller.initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    test('inisialisasi mengisi data contoh saat storage kosong', () {
      expect(controller.isReady, isTrue);
      expect(controller.totalModul, 8);
      expect(controller.totalTerbit, greaterThan(0));
      expect(controller.totalDraft, greaterThan(0));
      expect(controller.activities, isNotEmpty);
      expect(storage.values.containsKey(AppController.modulesKey), isTrue);
    });

    test('CRUD modul tersimpan dan dapat dipulihkan', () async {
      final created = await controller.tambahModul(_modulBaru());
      expect(controller.totalModul, 9);
      expect(controller.cariModul(created.id), isNotNull);
      expect(controller.activities.first.type, ActivityType.dibuat);

      final updated = await controller.perbaruiModul(
        created.copyWith(judul: 'Modul Uji Diperbarui', alokasiJp: 6),
      );
      expect(updated, isNotNull);
      expect(controller.cariModul(created.id)!.judul, 'Modul Uji Diperbarui');
      expect(controller.cariModul(created.id)!.alokasiJp, 6);

      final copy = await controller.duplikatModul(created.id);
      expect(copy, isNotNull);
      expect(copy!.judul, 'Modul Uji Diperbarui (Salinan)');
      expect(copy.status, ModulStatus.draft);
      expect(copy.favorit, isFalse);
      expect(controller.totalModul, 10);

      final removed = await controller.hapusModul(created.id);
      expect(removed, isNotNull);
      expect(controller.cariModul(created.id), isNull);
      expect(controller.totalModul, 9);

      await controller.pulihkanModul(removed!);
      expect(controller.cariModul(created.id), isNotNull);
      expect(controller.totalModul, 10);
      expect(controller.activities.first.type, ActivityType.dipulihkan);
    });

    test('toggle favorit dan status memperbarui data', () async {
      final modul = controller.modules.first;
      final statusAwal = modul.status;

      await controller.toggleFavorit(modul.id);
      expect(controller.cariModul(modul.id)!.favorit, isTrue);

      final updated = await controller.ubahStatus(modul.id);
      expect(updated, isNotNull);
      expect(updated!.status, isNot(statusAwal));
      expect(controller.activities.first.type, anyOf(
        ActivityType.diterbitkan,
        ActivityType.ditarikDraft,
      ));
    });

    test('filter, pencarian, dan pengurutan bekerja', () {
      final matematika = controller.filterModul(mapel: 'Matematika');
      expect(matematika, isNotEmpty);
      expect(
        matematika.every((modul) => modul.mataPelajaran == 'Matematika'),
        isTrue,
      );

      final hasilCari = controller.filterModul(query: 'newton');
      expect(hasilCari.length, 1);
      expect(hasilCari.first.judul, contains('Newton'));

      final terbit = controller.filterModul(filter: ModulFilter.terbit);
      expect(
        terbit.every((modul) => modul.status == ModulStatus.terbit),
        isTrue,
      );

      final berdasarkanJudul = controller.filterModul(sort: ModulSort.judul);
      final judul = berdasarkanJudul.map((modul) => modul.judul).toList();
      final sorted = [...judul]..sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
      expect(judul, sorted);
    });

    test('profil, tema, dan modul tetap ada setelah dibuka ulang', () async {
      await controller.ubahTema(ThemeMode.dark);
      await controller.perbaruiProfil(
        const TeacherProfile(
          nama: 'Guru Penguji',
          sekolah: 'SMA Pengujian',
          nip: '198705122015031004',
          email: 'guru@sekolah.id',
        ),
      );
      final created = await controller.tambahModul(_modulBaru());

      final restored = AppController(
        storage,
        now: () => DateTime(2026, 11, 17),
      );
      await restored.initialize();

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.profile.nama, 'Guru Penguji');
      expect(restored.cariModul(created.id)?.judul, 'Modul Uji');
      expect(restored.totalModul, 9);
      restored.dispose();
    });

    test('menghapus semua modul tidak memunculkan data contoh lagi', () async {
      await controller.hapusSemuaModul();
      expect(controller.totalModul, 0);
      expect(controller.activities, isEmpty);

      final restored = AppController(
        storage,
        now: () => DateTime(2026, 11, 18),
      );
      await restored.initialize();
      expect(restored.totalModul, 0);
      restored.dispose();
    });

    test('aktivitas dibatasi dan bisa dibersihkan', () async {
      for (var i = 0; i < 6; i++) {
        await controller.tambahModul(_modulBaru(judul: 'Modul $i'));
      }
      expect(controller.activities.length, lessThanOrEqualTo(80));
      expect(controller.activities.first.judulModul, 'Modul 5');

      await controller.hapusSemuaAktivitas();
      expect(controller.activities, isEmpty);
    });
  });
}
