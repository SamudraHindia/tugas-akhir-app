import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_akhir_app/app.dart';
import 'package:tugas_akhir_app/data/app_storage.dart';
import 'package:tugas_akhir_app/screens/modul/modul_list_screen.dart';
import 'package:tugas_akhir_app/state/app_controller.dart';

void _setMobileView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('beranda menampilkan ringkasan dan navigasi ke modul', (
    tester,
  ) async {
    _setMobileView(tester);
    final controller = AppController(InMemoryStorage());
    addTearDown(controller.dispose);

    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('ModulAjar'), findsOneWidget);
    expect(find.text('Total modul'), findsOneWidget);
    expect(find.text('Modul terbaru'), findsOneWidget);
    expect(find.text('Persamaan dan Fungsi Kuadrat'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('nav-modul')));
    await tester.pumpAndSettle();

    final listScreen = find.byType(ModulListScreen);
    expect(
      find.descendant(of: listScreen, matching: find.text('Modul Ajar')),
      findsOneWidget,
    );
    expect(find.text('8 modul · 5 terbit'), findsOneWidget);
    final listTitle = find.descendant(
      of: listScreen,
      matching: find.text('Persamaan dan Fungsi Kuadrat'),
    );
    expect(listTitle, findsOneWidget);

    await tester.tap(listTitle);
    await tester.pumpAndSettle();

    expect(find.text('Detail Modul'), findsOneWidget);
    expect(find.text('Tujuan Pembelajaran'), findsOneWidget);
    expect(find.byKey(const ValueKey('tombol-edit-modul')), findsOneWidget);
  });

  testWidgets('form modul memvalidasi kolom wajib', (tester) async {
    _setMobileView(tester);
    final storage = InMemoryStorage({
      AppController.modulesKey: '[]',
      AppController.activitiesKey: '[]',
    });
    final controller = AppController(storage);
    addTearDown(controller.dispose);

    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-modul')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ModulListScreen),
        matching: find.text('Belum ada modul ajar'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('fab-tambah-modul')));
    await tester.pumpAndSettle();
    expect(find.text('Modul Baru'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tombol-simpan-modul')));
    await tester.pumpAndSettle();

    expect(find.text('Judul modul wajib diisi.'), findsOneWidget);
    expect(find.text('Deskripsi wajib diisi.'), findsOneWidget);
    expect(find.text('Tujuan pembelajaran wajib diisi.'), findsOneWidget);
    expect(find.text('Materi pokok wajib diisi.'), findsOneWidget);
    expect(controller.totalModul, 0);
  });

  testWidgets('pengguna dapat membuat modul baru melalui form', (tester) async {
    _setMobileView(tester);
    final storage = InMemoryStorage({
      AppController.modulesKey: '[]',
      AppController.activitiesKey: '[]',
    });
    final controller = AppController(
      storage,
      now: () => DateTime(2026, 11, 16, 10),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-modul')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fab-tambah-modul')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('field-judul')),
      'Modul Uji Coba',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-deskripsi')),
      'Deskripsi lengkap untuk pengujian modul ajar.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-kegiatan')),
      'Kegiatan pembelajaran uji coba di kelas.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-asesmen')),
      'Asesmen formatif uji coba.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-tujuan-input')),
      'Tujuan pembelajaran pertama',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('field-materi-input')),
      'Materi pokok pertama',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('tombol-simpan-modul')));
    await tester.pumpAndSettle();

    expect(controller.totalModul, 1);
    expect(controller.modules.single.judul, 'Modul Uji Coba');
    expect(controller.modules.single.tujuanPembelajaran, [
      'Tujuan pembelajaran pertama',
    ]);
    expect(find.text('Detail Modul'), findsOneWidget);
    expect(find.text('Modul Uji Coba'), findsWidgets);
  });

  testWidgets('tema dapat diganti dari beranda', (tester) async {
    _setMobileView(tester);
    final controller = AppController(InMemoryStorage());
    addTearDown(controller.dispose);

    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pumpAndSettle();
    expect(controller.themeMode, ThemeMode.system);

    await tester.tap(find.byTooltip('Gunakan tema gelap'));
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Gunakan tema terang'), findsOneWidget);
  });
}
