# ModulAjar

Aplikasi Flutter untuk guru dalam menyusun dan mengelola **modul ajar** Kurikulum Merdeka. Data disimpan terpusat di **PostgreSQL** yang berjalan di Docker. Aplikasi Flutter berkomunikasi dengan **REST API PHP** untuk autentikasi dan operasi CRUD, sedangkan **layanan laporan Python** menyediakan rekap statistik dan ekspor CSV dari database yang sama.

Setiap guru memiliki akun sendiri. Setelah masuk, guru hanya dapat melihat dan mengubah modul, aktivitas, profil, dan preferensi tema miliknya. Sesi login disimpan sebagai token di perangkat dan dikirim melalui header `Authorization: Bearer <token>`.

## Arsitektur

```
Flutter (Android emulator / desktop / web)
        │
        ├── HTTP ──► PHP 8.3 REST API  (port 8080) ──┐
        │                                           ├──► PostgreSQL 16 (port 5433)
        └── HTTP ──► Python FastAPI    (port 8000) ──┘
                              │
                              └── rekap & ekspor CSV
```

| Komponen | Teknologi | Peran |
| --- | --- | --- |
| Aplikasi | Flutter, Material 3 | Antarmuka pengguna |
| API utama | PHP 8.3 native, PDO | Autentikasi, CRUD modul, aktivitas, profil, tema |
| Layanan laporan | Python 3.12, FastAPI | Rekap statistik dan ekspor CSV per guru |
| Database | PostgreSQL 16 | Penyimpanan data utama |
| Pemeriksa database | Adminer | Antarmuka inspeksi tabel |

## Fitur

### Akun dan Keamanan Sesi
- Login dan registrasi akun guru dengan validasi email serta kata sandi minimal 8 karakter.
- Kata sandi disimpan sebagai hash **bcrypt** di database, bukan teks biasa.
- Token sesi acak berlaku 30 hari, disimpan di perangkat, dan divalidasi pada setiap permintaan.
- Logout menghapus token di server dan di perangkat, lalu kembali ke layar login.
- Ubah kata sandi dari halaman profil; sesi di perangkat lain otomatis berakhir.
- Data setiap guru terpisah: modul, aktivitas, profil, dan tema hanya dapat diakses pemiliknya.
- Bila server membalas `401`, aplikasi otomatis kembali ke layar login.

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
- Edit nama, sekolah, NIP (validasi 18 digit), dan email (wajib, dipakai untuk login).
- Statistik kontribusi guru.
- Pilihan tema Sistem/Terang/Gelap yang tersimpan per akun di database.
- Kartu **Laporan server** yang menampilkan rekap dari layanan Python.
- **Ekspor CSV** terautentikasi yang menyalin rekap modul ke clipboard.
- Muat ulang data contoh, hapus semua modul, dialog tentang aplikasi, dan tombol **Keluar**.

### Tampilan Interaktif
- Animasi masuk pada splash, layar login, statistik, dan empty state.
- Kartu modul memberi efek tekan halus dan haptic ringan saat dibuka.
- Banner ide di beranda dapat diketuk untuk berganti saran sesuai kondisi data.
- Progres per mata pelajaran dan angka statistik dianimasikan saat data berubah.

## Teknologi

- Flutter 3.x / Dart 3.x, Material 3.
- `http` untuk komunikasi REST.
- `shared_preferences` untuk menyimpan token sesi di perangkat.
- `ChangeNotifier` + `InheritedNotifier` sebagai state management.
- PHP 8.3 dengan ekstensi `pdo_pgsql` dan `password_hash`/`password_verify`.
- Python 3.12 dengan FastAPI, Uvicorn, dan psycopg2.
- PostgreSQL 16.
- Arsitektur berlapis di Flutter: `data/models` → `data/*_repository.dart` → `state/app_controller.dart` → `screens`/`widgets`.

## Struktur Proyek

```
lib/
├── app.dart                       # MaterialApp, tema, bootstrap controller
├── app_scope.dart                 # InheritedNotifier untuk AppController
├── main.dart
├── core/
│   ├── api_config.dart            # Alamat API PHP dan layanan laporan
│   ├── app_theme.dart             # Tema terang/gelap
│   ├── constants.dart
│   ├── formatters.dart
│   └── subject_visual.dart
├── data/
│   ├── api_app_repository.dart    # Klien REST API PHP (dengan bearer token)
│   ├── auth_repository.dart       # Klien login/register/me/logout
│   ├── auth_session_store.dart    # Penyimpanan token sesi di perangkat
│   ├── app_repository.dart        # Kontrak repository & snapshot
│   ├── local_app_repository.dart  # Mode lokal untuk pengujian
│   ├── app_storage.dart           # SharedPreferences (mode lokal)
│   ├── report_service.dart        # Klien layanan laporan Python
│   ├── seed_data.dart             # 8 modul contoh
│   └── models/
│       ├── auth_session.dart      # AuthUser & AuthSession
│       └── ...
├── state/
│   └── app_controller.dart        # Sesi login, CRUD, filter, statistik, sinkronisasi
├── screens/
│   ├── auth/                      # Login dan registrasi
│   ├── home/
│   ├── modul/                     # daftar, detail, form CRUD
│   ├── search/
│   ├── activity/
│   ├── profile/
│   ├── root_shell.dart
│   └── splash_screen.dart
└── widgets/

backend/
├── php/
│   ├── Dockerfile
│   ├── public/index.php           # Entry point, CORS, error handling
│   └── src/api.php                # Autentikasi dan logika REST API
└── python/
    ├── Dockerfile
    ├── requirements.txt
    └── app.py                     # Layanan rekap & ekspor CSV per guru

database/
├── init.sql                       # Skema multi-guru + akun demo (volume baru)
└── migrate.sql                    # Migrasi idempotent untuk volume lama

.env.example
docker-compose.yml
```

## Menjalankan

### 1. Prasyarat
- Docker Desktop (dalam keadaan berjalan).
- Flutter SDK dan Android emulator (atau perangkat/desktop/web).

### 2. Siapkan variabel lingkungan (opsional)

```bash
copy .env.example .env      # Windows
# cp .env.example .env      # Linux/macOS
```

Sesuaikan `DB_PASSWORD` bila perlu. Untuk produksi, ganti `CORS_ALLOW_ORIGIN=*` dengan origin aplikasi Flutter web.

### 3. Jalankan backend

```bash
docker compose up -d --build
docker compose ps
```

Compose menjalankan lima service: `db`, `migrate`, `api`, `report`, dan `adminer`. Service `migrate` menjalankan `database/migrate.sql` secara idempotent setiap stack dinyalakan, sehingga volume database lama ikut dimigrasikan ke skema multi-guru. Tunggu hingga `modulajar-db` berstatus `healthy` dan `modulajar-migrate` selesai dengan kode `0`, lalu `api` serta `report` berstatus `Up`.

### 4. Masuk ke aplikasi

Gunakan akun demo:

| Field | Nilai |
| --- | --- |
| Email | `demo@modulajar.local` |
| Kata sandi | `password` |

Akun baru juga dapat dibuat dari layar **Daftar** di aplikasi.

### 5. Jalankan aplikasi Flutter

```bash
flutter pub get
flutter run
```

Nilai bawaan alamat server sudah disesuaikan untuk **Android emulator**:

- API PHP: `http://10.0.2.2:8080`
- Layanan laporan: `http://10.0.2.2:8000`

Untuk **desktop, web, atau emulator yang memakai localhost**, jalankan:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080 \
  --dart-define=REPORT_BASE_URL=http://localhost:8000
```

Untuk **HP fisik**, ganti `localhost` dengan alamat IP komputer di jaringan yang sama, misalnya:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.10:8080 \
  --dart-define=REPORT_BASE_URL=http://192.168.1.10:8000
```

## Layanan dan Port

| Layanan | URL / Port | Keterangan |
| --- | --- | --- |
| API PHP | `http://localhost:8080` | Autentikasi dan CRUD utama aplikasi |
| Layanan laporan Python | `http://localhost:8000` | Rekap dan ekspor CSV |
| PostgreSQL | `localhost:5433` | Port host, di dalam Docker memakai `5432` |
| Adminer | `http://localhost:8081` | Antarmuka pemeriksaan database |

### Login Adminer

| Field | Nilai |
| --- | --- |
| System | PostgreSQL |
| Server | `db` |
| Username | `modulajar` |
| Password | `modulajar123` |
| Database | `modulajar` |

## Endpoint API

### PHP — `http://localhost:8080`

Endpoint `/api/health`, `/api/auth/login`, dan `/api/auth/register` tidak memerlukan token. Endpoint lain wajib menyertakan header:

```
Authorization: Bearer <token>
```

| Metode | Endpoint | Fungsi |
| --- | --- | --- |
| GET | `/api/health` | Cek koneksi API dan database |
| POST | `/api/auth/register` | Buat akun guru baru dan langsung membuat sesi |
| POST | `/api/auth/login` | Masuk dan dapatkan token sesi |
| GET | `/api/auth/me` | Ambil data akun pemilik token |
| POST | `/api/auth/logout` | Hapus token sesi |
| POST | `/api/auth/change-password` | Ubah kata sandi dan akhiri sesi lain |
| GET | `/api/bootstrap` | Ambil seluruh data awal milik guru yang login |
| POST | `/api/bootstrap` | Ganti seluruh data milik guru (seed / hapus semua) |
| GET | `/api/modules` | Daftar modul milik guru |
| POST | `/api/modules` | Tambah modul |
| GET | `/api/modules/{id}` | Detail modul milik guru |
| PUT / PATCH | `/api/modules/{id}` | Perbarui modul milik guru |
| DELETE | `/api/modules/{id}` | Hapus modul milik guru |
| GET | `/api/activities` | Daftar aktivitas milik guru |
| POST | `/api/activities` | Catat aktivitas |
| DELETE | `/api/activities` | Bersihkan aktivitas milik guru |
| GET | `/api/profile` | Profil guru yang login |
| PUT / PATCH | `/api/profile` | Simpan profil guru |
| GET | `/api/theme` | Preferensi tema guru |
| PUT / PATCH | `/api/theme` | Simpan preferensi tema |

### Python — `http://localhost:8000`

| Metode | Endpoint | Fungsi |
| --- | --- | --- |
| GET | `/health` | Cek koneksi layanan dan database |
| GET | `/report/summary` | Rekap modul, status, JP, dan per mata pelajaran milik guru |
| GET | `/report/modules.csv` | Unduh modul milik guru dalam format CSV |

Kedua endpoint laporan juga memerlukan header `Authorization: Bearer <token>`.

Di aplikasi, rekap dapat dibuka dari **Profil → Laporan server → Muat rekap data**.
Tombol **Ekspor CSV** mengambil berkas CSV terautentikasi lalu menyalinnya ke
clipboard, sehingga bisa ditempel ke Excel atau Google Sheets tanpa menambah
dependency perizinan berkas.

Contoh login dan pemakaian token:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@modulajar.local","password":"password"}'

curl http://localhost:8080/api/bootstrap \
  -H "Authorization: Bearer <token-dari-respons-login>"

curl http://localhost:8080/api/health
curl http://localhost:8000/health
```

## Data Awal

Database dibuat otomatis dari `database/init.sql` saat volume PostgreSQL masih kosong. Skema menyimpan akun guru di tabel `guru`, dengan flag `initialized` dan preferensi `theme_mode` per akun. Token sesi disimpan di tabel `sesi`.

- Akun demo `demo@modulajar.local` / `password` dibuat otomatis.
- Setiap akun baru mulai dengan flag `initialized = false`. Saat login pertama, aplikasi mengisi **8 modul contoh** beserta aktivitasnya melalui `POST /api/bootstrap`.
- Data contoh juga dapat dimuat ulang dari halaman **Profil → Muat ulang data contoh**.
- Seluruh data tersimpan di PostgreSQL, bukan di `shared_preferences`. `shared_preferences` hanya dipakai untuk menyimpan token sesi di perangkat.

### Mengosongkan dan mengulang data

Hapus container beserta volume database:

```bash
docker compose down -v
docker compose up -d --build
```

Atau kosongkan data tanpa menghapus container (berlaku untuk semua akun):

```bash
docker exec modulajar-db psql -U modulajar -d modulajar \
  -c "DELETE FROM aktivitas; DELETE FROM modul_ajar; UPDATE guru SET initialized = FALSE;"
```

Setelah itu buka ulang aplikasi agar data contoh dimuat kembali.

### Migrasi volume lama

`database/migrate.sql` bersifat idempotent dan dijalankan otomatis oleh service `migrate`. Untuk menjalankannya manual:

```bash
docker compose exec -T db psql -U modulajar -d modulajar < database/migrate.sql
```

Catatan migrasi: akun guru lama tetap memakai email lamanya dan diberi kata sandi awal `password` agar datanya tetap dapat diakses. Setelah masuk, ubah kata sandi melalui **Profil → Akun → Ubah kata sandi**.

## Pengujian

```bash
flutter analyze
flutter test
```

Cakupan pengujian:
- Serialisasi/deserialisasi model, termasuk `AuthSession` dan penanganan data rusak.
- CRUD controller, filter, statistik, undo, dan pemulihan data.
- Widget test beranda, navigasi, validasi form, pembuatan modul, dan penggantian tema.

Pengujian Flutter memakai `LocalAppRepository` dan `AppStorage` in-memory sehingga tidak memerlukan container Docker. Mode lokal otomatis memakai sesi demo, jadi widget test tidak melewati layar login.

## Build

```bash
flutter build apk --release
flutter build web --release
```

Untuk build yang menunjuk server tertentu, sertakan `--dart-define`:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=REPORT_BASE_URL=http://10.0.2.2:8000
```

## Catatan Keamanan

Konfigurasi ini ditujukan untuk pengembangan dan demonstrasi tugas akhir:

- Kata sandi disimpan sebagai hash bcrypt. Akun demo sengaja memakai kata sandi `password`; ganti atau hapus akun demo sebelum produksi. Kata sandi dapat diubah dari **Profil → Akun → Ubah kata sandi**, dan sesi lain otomatis berakhir.
- Token sesi disimpan di `shared_preferences` tanpa enkripsi tambahan. Untuk produksi, gunakan `flutter_secure_storage`.
- Kredensial database dapat dioverride lewat `.env`; nilai bawaan hanya untuk pengembangan.
- REST API memakai bearer token dan membatasi setiap query berdasarkan `guru_id` pemilik sesi.
- CORS dapat dibatasi melalui `CORS_ALLOW_ORIGIN`. Nilai bawaan `*` hanya cocok untuk pengembangan.
- Android mengizinkan **cleartext HTTP** melalui `android:usesCleartextTraffic="true"` agar emulator dapat mengakses `http://10.0.2.2`.

Untuk produksi, gunakan HTTPS, secret manager, `flutter_secure_storage`, rotasi token, pembatasan CORS, dan hapus akun demo.

## Ikon Aplikasi

Ikon launcher dibuat dari sumber tunggal di `assets/icon/`:

- `app_icon.png` — ikon penuh (Android legacy, iOS, web, macOS, Windows).
- `app_icon_background.png` — latar ikon adaptive Android.
- `app_icon_foreground.png` — lapisan depan buku untuk ikon adaptive Android.

Untuk membuat ulang ikon di semua platform:

```bash
dart run flutter_launcher_icons
```

Konfigurasinya ada di blok `flutter_launcher_icons` pada `pubspec.yaml`.

---

Dibuat untuk keperluan Tugas Akhir.
