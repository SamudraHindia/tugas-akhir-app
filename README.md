# ModulAjar

Aplikasi Flutter untuk guru dalam menyusun dan mengelola **modul ajar** Kurikulum Merdeka. Aplikasi bekerja sepenuhnya secara lokal: data disimpan di perangkat menggunakan `shared_preferences`, tanpa memerlukan backend.

## Fitur

### CRUD Modul Ajar
- **Create** — form modul baru dengan validasi judul, deskripsi, mata pelajaran, kelas/fase, semester, alokasi JP, tujuan pembelajaran, materi pokok, kegiatan pembelajaran, asesmen, dan status publikasi.
- **Read** — daftar modul dengan pencarian, filter status/mapel/kelas, serta pengurutan. Halaman detail menampilkan seluruh isi modul.
- **Update** — edit seluruh field modul, tandai favorit, dan ubah status draft/terbit langsung dari halaman detail.
- **Delete** — hapus melalui menu atau geser kartu, lengkap dengan dialog konfirmasi dan aksi **Urungkan**.
- Duplikat modul sebagai draft baru.

### Beranda
- Sapaan personal, tanggal, dan ringkasan statistik (total modul, terbit, draft, total JP).
- Aksi cepat: buat modul, cari modul, dan edit profil.
- Modul terbaru, ringkasan progres per mata pelajaran, serta aktivitas terakhir.
- Toggle tema terang/gelap.

### Modul
- Pencarian judul, mata pelajaran, deskripsi, tujuan, dan materi.
- Filter cepat status serta filter lanjutan mapel/kelas.
- Empat opsi pengurutan.
- Tampilan responsif untuk ponsel dan layar lebar.

### Aktivitas
- Riwayat otomatis pembuatan, perubahan, publikasi, duplikasi, penghapusan, dan pemulihan modul.
- Dikelompokkan per hari dan dapat dibersihkan.

### Profil
- Edit nama, sekolah, NIP (validasi 18 digit), dan email.
- Statistik kontribusi guru.
- Pilihan tema Sistem/Terang/Gelap yang tersimpan.
- Muat ulang data contoh, hapus semua modul, dan dialog tentang aplikasi.

## Teknologi
- Flutter 3.47 / Dart 3.13, Material 3.
- `shared_preferences` untuk persistensi lokal.
- `ChangeNotifier` + `InheritedNotifier` sebagai state management tanpa dependensi tambahan.
- Font **Plus Jakarta Sans** (SIL Open Font License, lihat `assets/fonts/OFL.txt`).
- Arsitektur berlapis: `data/models` → `data/app_storage.dart` → `state/app_controller.dart` → `screens`/`widgets`.

## Struktur Proyek

```
lib/
├── app.dart                 # MaterialApp, tema, bootstrap controller
├── app_scope.dart           # InheritedNotifier untuk AppController
├── main.dart
├── core/                    # tema, konstanta, formatter, visual mapel
├── data/
│   ├── app_storage.dart     # SharedPreferences + InMemoryStorage
│   ├── models/              # ModulAjar, ActivityEntry, TeacherProfile
│   ├── seed_data.dart       # 8 modul contoh
│   └── ...
├── state/
│   └── app_controller.dart  # CRUD, filter, statistik, persistensi
├── screens/
│   ├── home/
│   ├── modul/               # daftar, detail, form CRUD
│   ├── search/
│   ├── activity/
│   ├── profile/
│   ├── root_shell.dart
│   └── splash_screen.dart
└── widgets/                 # komponen UI reusable
```

## Menjalankan

```bash
flutter pub get
flutter run
```

Build:

```bash
flutter build apk --release
flutter build web --release
```

## Ikon Aplikasi

Ikon launcher dibuat dari sumber tunggal di `assets/icon/`:

- `app_icon.png` — ikon penuh (Android legacy, iOS, web, macOS, Windows).
- `app_icon_background.png` — latar gradient untuk ikon adaptive Android.
- `app_icon_foreground.png` — lapisan depan buku untuk ikon adaptive Android.

Untuk membuat ulang ikon di semua platform:

```bash
dart run flutter_launcher_icons
```

Konfigurasinya ada di blok `flutter_launcher_icons` pada `pubspec.yaml`.

## Pengujian

```bash
flutter analyze
flutter test
```

Cakupan pengujian:
- Serialisasi/deserialisasi model dan penanganan data rusak.
- CRUD controller, filter, statistik, undo, persistensi, dan pemulihan data.
- Widget test beranda, navigasi, validasi form, pembuatan modul, dan penggantian tema.

## Penyimpanan Data

| Key | Isi |
| --- | --- |
| `modulajar.modules.v1` | Daftar modul ajar |
| `modulajar.activities.v1` | Riwayat aktivitas |
| `modulajar.profile.v1` | Profil guru |
| `modulajar.theme.v1` | Preferensi tema |

Data contoh dimuat otomatis saat aplikasi pertama kali dibuka. Data contoh juga dapat dimuat ulang dari halaman Profil.

---

Dibuat untuk keperluan Tugas Akhir.
