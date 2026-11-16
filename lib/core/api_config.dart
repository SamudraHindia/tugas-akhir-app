/// Alamat layanan backend.
///
/// Nilai bawaan memakai 10.0.2.2 karena aplikasi dijalankan di Android
/// emulator. Untuk web/desktop atau HP fisik, jalankan Flutter dengan:
///
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080 \
///               --dart-define=REPORT_BASE_URL=http://localhost:8000
class ApiConfig {
  const ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String reportBaseUrl = String.fromEnvironment(
    'REPORT_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
