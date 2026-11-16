const List<String> _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _namaBulanSingkat = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> _namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Contoh: 16 November 2026
String formatTanggal(DateTime date) {
  return '${date.day} ${_namaBulan[date.month - 1]} ${date.year}';
}

/// Contoh: 16 Nov 2026
String formatTanggalSingkat(DateTime date) {
  return '${date.day} ${_namaBulanSingkat[date.month - 1]} ${date.year}';
}

/// Contoh: Senin, 16 November 2026
String formatTanggalLengkap(DateTime date) {
  return '${_namaHari[date.weekday - 1]}, ${formatTanggal(date)}';
}

/// Waktu relatif berbahasa Indonesia.
String formatWaktuRelatif(DateTime time, {DateTime? sekarang}) {
  final now = sekarang ?? DateTime.now();
  final selisih = now.difference(time);

  if (selisih.isNegative) return 'Baru saja';
  if (selisih.inMinutes < 1) return 'Baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays == 1) return 'Kemarin';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
  if (selisih.inDays < 30) return '${selisih.inDays ~/ 7} minggu lalu';
  return formatTanggalSingkat(time);
}

String sapaanWaktu(DateTime time) {
  if (time.hour < 11) return 'Selamat pagi';
  if (time.hour < 15) return 'Selamat siang';
  if (time.hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String inisialNama(String nama) {
  final parts = nama
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// Nama hari singkat untuk header tanggal di beranda.
String formatHariTanggal(DateTime date) {
  return '${_namaHari[date.weekday - 1]}, ${date.day} ${_namaBulanSingkat[date.month - 1]}';
}
