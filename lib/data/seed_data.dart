import 'models/activity_entry.dart';
import 'models/modul_ajar.dart';

/// Data contoh agar aplikasi langsung terasa hidup saat pertama dibuka.
List<ModulAjar> buildSeedModules(DateTime now) {
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));
  DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));

  return [
    ModulAjar(
      id: 'seed-matematika-kuadrat',
      judul: 'Persamaan dan Fungsi Kuadrat',
      mataPelajaran: 'Matematika',
      kelas: 'X',
      semester: 'Ganjil',
      alokasiJp: 12,
      deskripsi: 'Modul ini membahas bentuk umum persamaan kuadrat, metode penyelesaian, sifat-sifat fungsi kuadrat, serta penerapannya untuk menyelesaikan masalah kontekstual.',
      tujuanPembelajaran: const [
        'Menjelaskan bentuk umum persamaan kuadrat dan komponennya.',
        'Menyelesaikan persamaan kuadrat dengan pemfaktoran, melengkapkan kuadrat sempurna, dan rumus abc.',
        'Menggambar grafik fungsi kuadrat serta menentukan titik puncak dan sumbu simetri.',
        'Menyelesaikan masalah kontekstual yang berkaitan dengan persamaan dan fungsi kuadrat.',
      ],
      materiPokok: const [
        'Bentuk umum persamaan kuadrat',
        'Pemfaktoran',
        'Melengkapkan kuadrat sempurna',
        'Rumus abc',
        'Grafik fungsi kuadrat',
        'Aplikasi dalam masalah nyata',
      ],
      kegiatanPembelajaran:
          'Pertemuan 1: eksplorasi bentuk umum persamaan kuadrat melalui kartu soal dan diskusi kelompok.\n'
          'Pertemuan 2: latihan terbimbing tiga metode penyelesaian persamaan kuadrat.\n'
          'Pertemuan 3: investigasi grafik fungsi kuadrat menggunakan aplikasi grafik.\n'
          'Pertemuan 4: proyek mini analisis lintasan bola dan presentasi hasil.',
      asesmen: 'Asesmen formatif melalui kuis interaktif dan lembar kerja kelompok. Asesmen sumatif berupa tes tertulis serta laporan proyek lintasan parabola.',
      status: ModulStatus.terbit,
      favorit: false,
      createdAt: daysAgo(14),
      updatedAt: hoursAgo(2),
    ),
    ModulAjar(
      id: 'seed-fisika-newton',
      judul: 'Hukum Newton tentang Gerak',
      mataPelajaran: 'Fisika',
      kelas: 'X',
      semester: 'Ganjil',
      alokasiJp: 8,
      deskripsi: 'Peserta didik mempelajari hubungan gaya dan gerak melalui Hukum I, II, dan III Newton serta menerapkannya pada peristiwa sehari-hari.',
      tujuanPembelajaran: const [
        'Membedakan keadaan diam, bergerak lurus beraturan, dan bergerak dipercepat.',
        'Menerapkan Hukum I, II, dan III Newton dalam penyelesaian masalah.',
        'Menganalisis diagram gaya pada sistem benda sederhana.',
      ],
      materiPokok: const [
        'Konsep gaya',
        'Hukum I Newton',
        'Hukum II Newton',
        'Hukum III Newton',
        'Diagram gaya',
      ],
      kegiatanPembelajaran: 'Pembelajaran diawali dengan demonstrasi tarik-meja, dilanjutkan praktikum gaya gesek menggunakan dinamometer. Peserta didik bekerja dalam kelompok untuk menganalisis data dan menyusun kesimpulan.',
      asesmen: 'Observasi kinerja praktikum, laporan hasil percobaan, dan kuis akhir materi.',
      status: ModulStatus.terbit,
      favorit: false,
      createdAt: daysAgo(20),
      updatedAt: daysAgo(1),
    ),
    ModulAjar(
      id: 'seed-biologi-ekskresi',
      judul: 'Sistem Ekskresi pada Manusia',
      mataPelajaran: 'Biologi',
      kelas: 'XI',
      semester: 'Ganjil',
      alokasiJp: 10,
      deskripsi: 'Modul ini mengupas struktur dan fungsi organ ekskresi manusia, mekanisme pembentukan urine, serta gangguan yang dapat terjadi pada sistem ekskresi.',
      tujuanPembelajaran: const [
        'Mengidentifikasi organ-organ penyusun sistem ekskresi manusia.',
        'Menjelaskan proses pembentukan urine pada nefron.',
        'Menganalisis gangguan fungsi ginjal dan upaya menjaga kesehatan sistem ekskresi.',
      ],
      materiPokok: const [
        'Ginjal dan nefron',
        'Proses pembentukan urine',
        'Kulit, paru-paru, dan hati',
        'Gangguan sistem ekskresi',
      ],
      kegiatanPembelajaran: 'Diskusi kelompok tentang organ ekskresi, studi kasus pasien gagal ginjal, dan pembuatan poster edukasi kesehatan ginjal.',
      asesmen: 'Penilaian poster, presentasi kelompok, dan tes formatif pilihan ganda.',
      status: ModulStatus.draft,
      favorit: false,
      createdAt: daysAgo(3),
      updatedAt: daysAgo(3),
    ),
    ModulAjar(
      id: 'seed-bindo-argumentasi',
      judul: 'Teks Argumentasi dan Debat',
      mataPelajaran: 'Bahasa Indonesia',
      kelas: 'XI',
      semester: 'Ganjil',
      alokasiJp: 6,
      deskripsi: 'Peserta didik belajar menyusun argumen yang logis dan santun, mengenali struktur teks argumentasi, serta berlatih berdebat dengan kaidah bahasa yang baik.',
      tujuanPembelajaran: const [
        'Mengidentifikasi struktur dan ciri kebahasaan teks argumentasi.',
        'Menyusun teks argumentasi dengan data pendukung yang relevan.',
        'Berpartisipasi dalam debat dengan argumen yang logis dan santun.',
      ],
      materiPokok: const [
        'Struktur teks argumentasi',
        'Kalimat fakta dan opini',
        'Konjungsi argumentatif',
        'Etika debat',
      ],
      kegiatanPembelajaran: 'Membaca teks model, analisis struktur, latihan menulis argumen, kemudian simulasi debat kelas dengan topik isu lingkungan.',
      asesmen: 'Asesmen formatif melalui draf tulisan, asesmen kinerja debat, dan rubrik penilaian argumen.',
      status: ModulStatus.terbit,
      favorit: false,
      createdAt: daysAgo(12),
      updatedAt: daysAgo(5),
    ),
    ModulAjar(
      id: 'seed-sejarah-pd2',
      judul: 'Perang Dunia II dan Dampaknya bagi Indonesia',
      mataPelajaran: 'Sejarah',
      kelas: 'XII',
      semester: 'Genap',
      alokasiJp: 8,
      deskripsi: 'Modul ini menelusuri latar belakang Perang Dunia II, kedatangan Jepang, masa pendudukan, hingga pengaruhnya terhadap pergerakan kemerdekaan Indonesia.',
      tujuanPembelajaran: const [
        'Menjelaskan latar belakang terjadinya Perang Dunia II.',
        'Menganalisis dampak pendudukan Jepang bagi masyarakat Indonesia.',
        'Menarik pelajaran dari peristiwa sejarah untuk kehidupan masa kini.',
      ],
      materiPokok: const [
        'Latar belakang Perang Dunia II',
        'Kedatangan Jepang',
        'Pendudukan Jepang di Indonesia',
        'Persiapan kemerdekaan',
      ],
      kegiatanPembelajaran: 'Analisis sumber sejarah primer, diskusi timeline, dan pameran mini kronologi peristiwa.',
      asesmen: 'Esai analitis, presentasi timeline, dan penilaian sikap dalam diskusi.',
      status: ModulStatus.draft,
      favorit: false,
      createdAt: daysAgo(18),
      updatedAt: daysAgo(8),
    ),
    ModulAjar(
      id: 'seed-informatika-python',
      judul: 'Dasar-Dasar Pemrograman Python',
      mataPelajaran: 'Informatika',
      kelas: 'X',
      semester: 'Ganjil',
      alokasiJp: 12,
      deskripsi: 'Pengantar berpikir komputasional dan pemrograman Python, mulai dari variabel, struktur kontrol, hingga proyek kecil pengolahan data sederhana.',
      tujuanPembelajaran: const [
        'Menjelaskan konsep variabel, tipe data, dan operator dalam Python.',
        'Menggunakan struktur percabangan dan perulangan untuk menyelesaikan masalah.',
        'Membuat program sederhana yang membaca input dan menampilkan output.',
        'Bekerja kolaboratif dalam proyek mini pemrograman.',
      ],
      materiPokok: const [
        'Variabel dan tipe data',
        'Operator',
        'Percabangan',
        'Perulangan',
        'Fungsi',
        'Proyek mini',
      ],
      kegiatanPembelajaran: 'Setiap pertemuan diawali tantangan kode singkat, dilanjutkan praktik di laboratorium komputer dan sesi berbagi solusi antar kelompok.',
      asesmen:
          'Portofolio kode, kuis daring, dan penilaian proyek mini presentasi.',
      status: ModulStatus.terbit,
      favorit: true,
      createdAt: daysAgo(25),
      updatedAt: hoursAgo(12),
    ),
    ModulAjar(
      id: 'seed-kimia-stoikiometri',
      judul: 'Stoikiometri dan Persamaan Reaksi',
      mataPelajaran: 'Kimia',
      kelas: 'XI',
      semester: 'Ganjil',
      alokasiJp: 10,
      deskripsi: 'Membahas penyetaraan persamaan reaksi, konsep mol, dan perhitungan kuantitatif dalam reaksi kimia melalui percobaan sederhana.',
      tujuanPembelajaran: const [
        'Menyetarakan persamaan reaksi kimia.',
        'Menghubungkan konsep mol dengan massa, volume, dan jumlah partikel.',
        'Menyelesaikan perhitungan stoikiometri pada reaksi sederhana.',
      ],
      materiPokok: const [
        'Persamaan reaksi',
        'Konsep mol',
        'Massa molar',
        'Pereaksi pembatas',
      ],
      kegiatanPembelajaran: 'Praktikum reaksi soda kue dan cuka, analisis data hasil percobaan, serta latihan perhitungan stoikiometri secara bertahap.',
      asesmen: 'Laporan praktikum, latihan soal terstruktur, dan tes sumatif.',
      status: ModulStatus.terbit,
      favorit: false,
      createdAt: daysAgo(40),
      updatedAt: daysAgo(15),
    ),
    ModulAjar(
      id: 'seed-seni-tari',
      judul: 'Kearifan Lokal dalam Seni Tari Nusantara',
      mataPelajaran: 'Seni Budaya',
      kelas: 'XII',
      semester: 'Genap',
      alokasiJp: 6,
      deskripsi: 'Eksplorasi ragam gerak, kostum, dan nilai kearifan lokal pada tari tradisional Nusantara, diakhiri dengan karya koreografi kelompok.',
      tujuanPembelajaran: const [
        'Mengidentifikasi ragam gerak dan makna simbolik tari tradisional.',
        'Menganalisis nilai kearifan lokal dalam seni pertunjukan.',
        'Menampilkan karya tari kelompok yang terinspirasi budaya lokal.',
      ],
      materiPokok: const [
        'Ragam gerak dasar',
        'Rias dan kostum',
        'Makna simbolik tari',
        'Koreografi kelompok',
      ],
      kegiatanPembelajaran: 'Menonton pertunjukan tari, wawancara singkat dengan pelaku seni lokal, latihan gerak, dan pementasan kelas.',
      asesmen: 'Penilaian proses latihan, rubrik pertunjukan, dan refleksi tertulis.',
      status: ModulStatus.draft,
      favorit: true,
      createdAt: daysAgo(32),
      updatedAt: daysAgo(20),
    ),
  ];
}

List<ActivityEntry> buildSeedActivities(List<ModulAjar> modules, DateTime now) {
  if (modules.isEmpty) return const [];

  ActivityEntry entry(
    String id,
    ActivityType type,
    ModulAjar modul,
    DateTime timestamp,
  ) {
    return ActivityEntry(
      id: id,
      type: type,
      modulId: modul.id,
      judulModul: modul.judul,
      timestamp: timestamp,
    );
  }

  return [
    entry(
      'seed-activity-1',
      ActivityType.diperbarui,
      modules[0],
      now.subtract(const Duration(hours: 2)),
    ),
    entry(
      'seed-activity-2',
      ActivityType.diterbitkan,
      modules[5],
      now.subtract(const Duration(hours: 12)),
    ),
    entry(
      'seed-activity-3',
      ActivityType.diperbarui,
      modules[1],
      now.subtract(const Duration(days: 1)),
    ),
    entry(
      'seed-activity-4',
      ActivityType.dibuat,
      modules[2],
      now.subtract(const Duration(days: 3)),
    ),
    entry(
      'seed-activity-5',
      ActivityType.diterbitkan,
      modules[3],
      now.subtract(const Duration(days: 5)),
    ),
  ];
}
