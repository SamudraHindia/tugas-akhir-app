/// Konstanta dan pilihan yang dipakai di seluruh aplikasi.
class AppInfo {
  const AppInfo._();

  static const String name = 'ModulAjar';
  static const String version = '1.0.0';
  static const String tagline =
      'Kelola perangkat ajar Kurikulum Merdeka dalam satu tempat.';
}

class ModulOptions {
  const ModulOptions._();

  static const List<String> mapel = [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'Fisika',
    'Kimia',
    'Biologi',
    'Sejarah',
    'Ekonomi',
    'Geografi',
    'Sosiologi',
    'Informatika',
    'Seni Budaya',
    'PJOK',
    'Pendidikan Pancasila',
    'Prakarya',
    'Bahasa Jawa',
  ];

  static const List<String> kelas = ['X', 'XI', 'XII'];
  static const List<String> semester = ['Ganjil', 'Genap'];

  static const int minAlokasiJp = 1;
  static const int maxAlokasiJp = 40;

  /// Fase Kurikulum Merdeka untuk tiap tingkat kelas.
  static String faseUntukKelas(String kelas) {
    return kelas == 'X' ? 'E' : 'F';
  }
}
