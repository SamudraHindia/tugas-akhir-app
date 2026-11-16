<?php

declare(strict_types=1);

const ACTIVITY_TYPES = [
    'dibuat',
    'diperbarui',
    'dihapus',
    'dipulihkan',
    'diterbitkan',
    'ditarikDraft',
    'diduplikasi',
];

const THEME_MODES = ['system', 'light', 'dark'];
const SESSION_LIFETIME_SECONDS = 60 * 60 * 24 * 30;

function db(): PDO
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $host = getenv('DB_HOST') ?: 'db';
    $port = getenv('DB_PORT') ?: '5432';
    $name = getenv('DB_NAME') ?: 'modulajar';
    $user = getenv('DB_USER') ?: 'modulajar';
    $password = getenv('DB_PASSWORD') ?: 'modulajar123';

    $pdo = new PDO(
        "pgsql:host={$host};port={$port};dbname={$name}",
        $user,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );

    return $pdo;
}

function json_response(mixed $data, int $status = 200): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function json_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        throw new InvalidArgumentException('Body permintaan harus berupa JSON objek.');
    }

    return $decoded;
}

function request_segments(): array
{
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $segments = array_values(array_filter(explode('/', trim($path, '/')), static function (string $part): bool {
        return $part !== '';
    }));

    if (($segments[0] ?? '') === 'api') {
        array_shift($segments);
    }

    return $segments;
}

function route_request(): void
{
    $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    $segments = request_segments();
    $resource = $segments[0] ?? '';
    $id = $segments[1] ?? null;

    switch ($resource) {
        case 'health':
            if ($method !== 'GET') {
                json_response(['error' => 'Metode tidak diizinkan.'], 405);
            }
            db()->query('SELECT 1');
            json_response([
                'status' => 'ok',
                'service' => 'php-api',
                'database' => 'terhubung',
            ]);
            break;

        case 'auth':
            handle_auth($method, $id);
            break;

        case 'bootstrap':
            $session = require_auth();
            $guruId = (int) $session['guru']['id'];
            if ($method === 'GET') {
                json_response(bootstrap_payload($session['guru']));
            }
            if ($method === 'POST') {
                json_response(bootstrap_replace($guruId, json_body()));
            }
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
            break;

        case 'modules':
            $session = require_auth();
            handle_modules($method, $id, (int) $session['guru']['id']);
            break;

        case 'activities':
            $session = require_auth();
            handle_activities($method, $id, (int) $session['guru']['id']);
            break;

        case 'profile':
            $session = require_auth();
            $guruId = (int) $session['guru']['id'];
            if ($method === 'GET') {
                json_response(read_profile($guruId));
            }
            if ($method === 'PUT' || $method === 'PATCH') {
                json_response(write_profile($guruId, json_body()));
            }
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
            break;

        case 'theme':
            $session = require_auth();
            $guruId = (int) $session['guru']['id'];
            if ($method === 'GET') {
                json_response([
                    'themeMode' => (string) ($session['guru']['theme_mode'] ?? 'system'),
                ]);
            }
            if ($method === 'PUT' || $method === 'PATCH') {
                json_response(write_theme($guruId, json_body()));
            }
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
            break;

        default:
            json_response(['error' => 'Endpoint tidak ditemukan.'], 404);
    }
}

function handle_auth(string $method, ?string $action): never
{
    if ($action === 'login') {
        if ($method !== 'POST') {
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
        }
        json_response(login_guru(json_body()));
    }

    if ($action === 'register') {
        if ($method !== 'POST') {
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
        }
        json_response(register_guru(json_body()), 201);
    }

    if ($action === 'me') {
        if ($method !== 'GET') {
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
        }
        $session = require_auth();
        json_response(['user' => guru_payload($session['guru'])]);
    }

    if ($action === 'logout') {
        if ($method !== 'POST') {
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
        }
        $session = require_auth();
        delete_session($session['token_hash']);
        json_response(['ok' => true]);
    }

    if ($action === 'change-password') {
        if ($method !== 'POST') {
            json_response(['error' => 'Metode tidak diizinkan.'], 405);
        }
        $session = require_auth();
        json_response(change_password(
            (int) $session['guru']['id'],
            (string) $session['token_hash'],
            json_body()
        ));
    }

    json_response(['error' => 'Endpoint autentikasi tidak ditemukan.'], 404);
}

function login_guru(array $data): array
{
    $email = normalize_email($data['email'] ?? '');
    $password = (string) ($data['password'] ?? '');

    if ($email === '' || $password === '') {
        throw new InvalidArgumentException('Email dan kata sandi wajib diisi.');
    }

    $statement = db()->prepare(
        'SELECT * FROM guru WHERE lower(email) = :email LIMIT 1'
    );
    $statement->execute(['email' => $email]);
    $guru = $statement->fetch();

    if ($guru === false || !password_verify($password, (string) $guru['password_hash'])) {
        json_response(['error' => 'Email atau kata sandi salah.'], 401);
    }

    return create_session($guru);
}

function register_guru(array $data): array
{
    $nama = trim((string) ($data['nama'] ?? ''));
    $sekolah = trim((string) ($data['sekolah'] ?? ''));
    $email = normalize_email($data['email'] ?? '');
    $password = (string) ($data['password'] ?? '');

    if (strlen($nama) < 3) {
        throw new InvalidArgumentException('Nama minimal 3 karakter.');
    }
    if (strlen($sekolah) < 3) {
        throw new InvalidArgumentException('Nama sekolah minimal 3 karakter.');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new InvalidArgumentException('Format email belum benar.');
    }
    if (strlen($password) < 8) {
        throw new InvalidArgumentException('Kata sandi minimal 8 karakter.');
    }

    $statement = db()->prepare(
        'SELECT 1 FROM guru WHERE lower(email) = :email LIMIT 1'
    );
    $statement->execute(['email' => $email]);
    if ($statement->fetchColumn() !== false) {
        json_response(['error' => 'Email sudah terdaftar. Silakan masuk.'], 409);
    }

    try {
        $statement = db()->prepare(
            'INSERT INTO guru (nama, sekolah, email, password_hash)
             VALUES (:nama, :sekolah, :email, :password_hash)
             RETURNING *'
        );
        $statement->execute([
            'nama' => $nama,
            'sekolah' => $sekolah,
            'email' => $email,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
        ]);
        $guru = $statement->fetch();
    } catch (PDOException $exception) {
        if ($exception->getCode() === '23505') {
            json_response(['error' => 'Email sudah terdaftar. Silakan masuk.'], 409);
        }
        throw $exception;
    }

    if ($guru === false) {
        throw new RuntimeException('Akun tidak berhasil dibuat.');
    }

    return create_session($guru);
}

function change_password(int $guruId, string $tokenHash, array $data): array
{
    $currentPassword = (string) ($data['currentPassword'] ?? '');
    $newPassword = (string) ($data['newPassword'] ?? '');

    if ($currentPassword === '' || $newPassword === '') {
        throw new InvalidArgumentException(
            'Kata sandi saat ini dan kata sandi baru wajib diisi.'
        );
    }
    if (strlen($newPassword) < 8) {
        throw new InvalidArgumentException('Kata sandi baru minimal 8 karakter.');
    }
    if ($currentPassword === $newPassword) {
        throw new InvalidArgumentException(
            'Kata sandi baru harus berbeda dari kata sandi saat ini.'
        );
    }

    $guru = find_guru($guruId);
    if (!password_verify($currentPassword, (string) $guru['password_hash'])) {
        json_response(['error' => 'Kata sandi saat ini salah.'], 400);
    }

    $statement = db()->prepare(
        'UPDATE guru
         SET password_hash = :password_hash, updated_at = NOW()
         WHERE id = :id'
    );
    $statement->execute([
        'password_hash' => password_hash($newPassword, PASSWORD_DEFAULT),
        'id' => $guruId,
    ]);

    // Akhiri sesi lain agar kata sandi baru berlaku di semua perangkat.
    $statement = db()->prepare(
        'DELETE FROM sesi
         WHERE guru_id = :guru_id AND token_hash <> :token_hash'
    );
    $statement->execute([
        'guru_id' => $guruId,
        'token_hash' => $tokenHash,
    ]);

    return ['ok' => true];
}

function create_session(array $guru): array
{
    db()->exec('DELETE FROM sesi WHERE kedaluwarsa_at <= NOW()');

    $token = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:sP', time() + SESSION_LIFETIME_SECONDS);

    $statement = db()->prepare(
        'INSERT INTO sesi (token_hash, guru_id, kedaluwarsa_at)
         VALUES (:token_hash, :guru_id, :kedaluwarsa_at)'
    );
    $statement->execute([
        'token_hash' => hash('sha256', $token),
        'guru_id' => (int) $guru['id'],
        'kedaluwarsa_at' => $expiresAt,
    ]);

    return [
        'token' => $token,
        'expiresAt' => to_iso_time($expiresAt),
        'user' => guru_payload($guru),
    ];
}

function normalize_email(mixed $value): string
{
    return strtolower(trim((string) $value));
}

function require_auth(): array
{
    $token = bearer_token();
    if ($token === null) {
        json_response(['error' => 'Silakan masuk terlebih dahulu.'], 401);
    }

    $tokenHash = hash('sha256', $token);
    $statement = db()->prepare(
        'SELECT g.* FROM sesi s
         JOIN guru g ON g.id = s.guru_id
         WHERE s.token_hash = :token_hash AND s.kedaluwarsa_at > NOW()
         LIMIT 1'
    );
    $statement->execute(['token_hash' => $tokenHash]);
    $guru = $statement->fetch();

    if ($guru === false) {
        json_response(['error' => 'Sesi sudah berakhir. Silakan masuk kembali.'], 401);
    }

    return ['guru' => $guru, 'token_hash' => $tokenHash];
}

function bearer_token(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? '';

    if ($header === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $name => $value) {
            if (strcasecmp($name, 'Authorization') === 0) {
                $header = $value;
                break;
            }
        }
    }

    if (preg_match('/^Bearer\s+(\S+)$/i', trim($header), $matches) !== 1) {
        return null;
    }

    return $matches[1];
}

function delete_session(string $tokenHash): void
{
    $statement = db()->prepare('DELETE FROM sesi WHERE token_hash = :token_hash');
    $statement->execute(['token_hash' => $tokenHash]);
}

function guru_payload(array $row): array
{
    return [
        'id' => (int) $row['id'],
        'nama' => (string) $row['nama'],
        'sekolah' => (string) $row['sekolah'],
        'nip' => (string) $row['nip'],
        'email' => (string) $row['email'],
        'themeMode' => (string) ($row['theme_mode'] ?? 'system'),
        'initialized' => to_bool($row['initialized'] ?? false),
    ];
}

function to_bool(mixed $value): bool
{
    if (is_bool($value)) {
        return $value;
    }
    if (is_int($value) || is_float($value)) {
        return $value !== 0;
    }
    if (is_string($value)) {
        return in_array(strtolower($value), ['1', 't', 'true', 'y', 'yes'], true);
    }
    return false;
}

function handle_modules(string $method, ?string $id, int $guruId): never
{
    if ($method === 'GET' && $id === null) {
        json_response(list_modules($guruId));
    }

    if ($method === 'POST' && $id === null) {
        $data = json_body();
        $saved = save_module(
            $data,
            $guruId,
            isset($data['id']) ? (string) $data['id'] : null,
            true
        );
        json_response($saved, 201);
    }

    if ($id === null || $id === '') {
        json_response(['error' => 'ID modul wajib diisi.'], 400);
    }

    if ($method === 'GET') {
        $module = find_module($id, $guruId);
        if ($module === null) {
            json_response(['error' => 'Modul tidak ditemukan.'], 404);
        }
        json_response($module);
    }

    if ($method === 'PUT' || $method === 'PATCH') {
        $existing = find_module($id, $guruId);
        if ($existing === null) {
            json_response(['error' => 'Modul tidak ditemukan.'], 404);
        }
        $data = array_merge($existing, json_body());
        json_response(save_module($data, $guruId, $id, false));
    }

    if ($method === 'DELETE') {
        $statement = db()->prepare(
            'DELETE FROM modul_ajar WHERE id = :id AND guru_id = :guru_id'
        );
        $statement->execute(['id' => $id, 'guru_id' => $guruId]);
        if ($statement->rowCount() === 0) {
            json_response(['error' => 'Modul tidak ditemukan.'], 404);
        }
        json_response(['ok' => true, 'id' => $id]);
    }

    json_response(['error' => 'Metode tidak diizinkan.'], 405);
}

function handle_activities(string $method, ?string $id, int $guruId): never
{
    if ($id !== null) {
        json_response(['error' => 'Endpoint tidak ditemukan.'], 404);
    }

    if ($method === 'GET') {
        json_response(list_activities($guruId));
    }

    if ($method === 'POST') {
        json_response(insert_activity(json_body(), $guruId), 201);
    }

    if ($method === 'DELETE') {
        $statement = db()->prepare('DELETE FROM aktivitas WHERE guru_id = :guru_id');
        $statement->execute(['guru_id' => $guruId]);
        json_response(['ok' => true]);
    }

    json_response(['error' => 'Metode tidak diizinkan.'], 405);
}

function list_modules(int $guruId): array
{
    $statement = db()->prepare(
        'SELECT * FROM modul_ajar
         WHERE guru_id = :guru_id
         ORDER BY updated_at DESC, judul ASC'
    );
    $statement->execute(['guru_id' => $guruId]);

    return array_map('module_from_row', $statement->fetchAll());
}

function find_module(string $id, int $guruId): ?array
{
    $statement = db()->prepare(
        'SELECT * FROM modul_ajar WHERE id = :id AND guru_id = :guru_id'
    );
    $statement->execute(['id' => $id, 'guru_id' => $guruId]);
    $row = $statement->fetch();

    return $row === false ? null : module_from_row($row);
}

function save_module(
    array $data,
    int $guruId,
    ?string $id = null,
    bool $allowUpsert = true
): array {
    $id = $id !== null && trim($id) !== '' ? trim($id) : generate_id('modul');
    $judul = trim((string) ($data['judul'] ?? ''));
    if ($judul === '') {
        throw new InvalidArgumentException('Judul modul wajib diisi.');
    }

    $mataPelajaran = trim((string) ($data['mataPelajaran'] ?? ''));
    if ($mataPelajaran === '') {
        throw new InvalidArgumentException('Mata pelajaran wajib diisi.');
    }

    $kelas = trim((string) ($data['kelas'] ?? 'X'));
    if (!in_array($kelas, ['X', 'XI', 'XII'], true)) {
        $kelas = 'X';
    }

    $semester = trim((string) ($data['semester'] ?? 'Ganjil'));
    if (!in_array($semester, ['Ganjil', 'Genap'], true)) {
        $semester = 'Ganjil';
    }

    $alokasi = max(1, min(40, (int) ($data['alokasiJp'] ?? 2)));
    $status = (string) ($data['status'] ?? 'draft');
    if (!in_array($status, ['draft', 'terbit'], true)) {
        $status = 'draft';
    }

    $values = [
        'guru_id' => $guruId,
        'id' => $id,
        'judul' => $judul,
        'mata_pelajaran' => $mataPelajaran,
        'kelas' => $kelas,
        'semester' => $semester,
        'alokasi_jp' => $alokasi,
        'deskripsi' => (string) ($data['deskripsi'] ?? ''),
        'tujuan_pembelajaran' => json_encode(clean_list($data['tujuanPembelajaran'] ?? [])),
        'materi_pokok' => json_encode(clean_list($data['materiPokok'] ?? [])),
        'kegiatan_pembelajaran' => (string) ($data['kegiatanPembelajaran'] ?? ''),
        'asesmen' => (string) ($data['asesmen'] ?? ''),
        'status' => $status,
        'favorit' => !empty($data['favorit']) ? 'true' : 'false',
        'updated_at' => to_database_time($data['updatedAt'] ?? null),
    ];

    if (!$allowUpsert) {
        $statement = db()->prepare(
            'UPDATE modul_ajar SET
                judul = :judul,
                mata_pelajaran = :mata_pelajaran,
                kelas = :kelas,
                semester = :semester,
                alokasi_jp = :alokasi_jp,
                deskripsi = :deskripsi,
                tujuan_pembelajaran = :tujuan_pembelajaran,
                materi_pokok = :materi_pokok,
                kegiatan_pembelajaran = :kegiatan_pembelajaran,
                asesmen = :asesmen,
                status = :status,
                favorit = :favorit,
                updated_at = :updated_at
             WHERE id = :id AND guru_id = :guru_id'
        );
        $statement->execute($values);

        return find_module($id, $guruId) ?? [];
    }

    $conflict = 'ON CONFLICT (guru_id, id) DO UPDATE SET
            judul = EXCLUDED.judul,
            mata_pelajaran = EXCLUDED.mata_pelajaran,
            kelas = EXCLUDED.kelas,
            semester = EXCLUDED.semester,
            alokasi_jp = EXCLUDED.alokasi_jp,
            deskripsi = EXCLUDED.deskripsi,
            tujuan_pembelajaran = EXCLUDED.tujuan_pembelajaran,
            materi_pokok = EXCLUDED.materi_pokok,
            kegiatan_pembelajaran = EXCLUDED.kegiatan_pembelajaran,
            asesmen = EXCLUDED.asesmen,
            status = EXCLUDED.status,
            favorit = EXCLUDED.favorit,
            updated_at = EXCLUDED.updated_at';

    $sql = "INSERT INTO modul_ajar (
                guru_id, id, judul, mata_pelajaran, kelas, semester, alokasi_jp,
                deskripsi, tujuan_pembelajaran, materi_pokok,
                kegiatan_pembelajaran, asesmen, status, favorit,
                created_at, updated_at
            ) VALUES (
                :guru_id, :id, :judul, :mata_pelajaran, :kelas, :semester, :alokasi_jp,
                :deskripsi, :tujuan_pembelajaran, :materi_pokok,
                :kegiatan_pembelajaran, :asesmen, :status, :favorit,
                :created_at, :updated_at
            ) {$conflict}";

    $statement = db()->prepare($sql);
    $values['created_at'] = to_database_time($data['createdAt'] ?? null);
    $statement->execute($values);

    return find_module($id, $guruId) ?? [];
}

function module_from_row(array $row): array
{
    return [
        'id' => (string) $row['id'],
        'judul' => (string) $row['judul'],
        'mataPelajaran' => (string) $row['mata_pelajaran'],
        'kelas' => (string) $row['kelas'],
        'semester' => (string) $row['semester'],
        'alokasiJp' => (int) $row['alokasi_jp'],
        'deskripsi' => (string) $row['deskripsi'],
        'tujuanPembelajaran' => decode_list($row['tujuan_pembelajaran']),
        'materiPokok' => decode_list($row['materi_pokok']),
        'kegiatanPembelajaran' => (string) $row['kegiatan_pembelajaran'],
        'asesmen' => (string) $row['asesmen'],
        'status' => (string) $row['status'],
        'favorit' => to_bool($row['favorit']),
        'createdAt' => to_iso_time($row['created_at']),
        'updatedAt' => to_iso_time($row['updated_at']),
    ];
}

function list_activities(int $guruId): array
{
    $statement = db()->prepare(
        'SELECT * FROM aktivitas
         WHERE guru_id = :guru_id
         ORDER BY waktu DESC, id DESC
         LIMIT 80'
    );
    $statement->execute(['guru_id' => $guruId]);

    return array_map('activity_from_row', $statement->fetchAll());
}

function insert_activity(array $data, int $guruId): array
{
    $id = trim((string) ($data['id'] ?? ''));
    if ($id === '') {
        $id = generate_id('aktivitas');
    }

    $type = (string) ($data['type'] ?? 'diperbarui');
    if (!in_array($type, ACTIVITY_TYPES, true)) {
        $type = 'diperbarui';
    }

    $judul = trim((string) ($data['judulModul'] ?? ''));
    if ($judul === '') {
        $judul = 'Modul ajar';
    }

    $sql = 'INSERT INTO aktivitas (guru_id, id, tipe, modul_id, judul_modul, waktu)
            VALUES (:guru_id, :id, :tipe, :modul_id, :judul_modul, :waktu)
            ON CONFLICT (guru_id, id) DO UPDATE SET
                tipe = EXCLUDED.tipe,
                modul_id = EXCLUDED.modul_id,
                judul_modul = EXCLUDED.judul_modul,
                waktu = EXCLUDED.waktu';

    $statement = db()->prepare($sql);
    $statement->execute([
        'guru_id' => $guruId,
        'id' => $id,
        'tipe' => $type,
        'modul_id' => (string) ($data['modulId'] ?? ''),
        'judul_modul' => $judul,
        'waktu' => to_database_time($data['timestamp'] ?? null),
    ]);

    $statement = db()->prepare(
        'SELECT * FROM aktivitas WHERE id = :id AND guru_id = :guru_id'
    );
    $statement->execute(['id' => $id, 'guru_id' => $guruId]);
    $row = $statement->fetch();

    if ($row === false) {
        throw new RuntimeException('Aktivitas tidak berhasil disimpan.');
    }

    return activity_from_row($row);
}

function activity_from_row(array $row): array
{
    return [
        'id' => (string) $row['id'],
        'type' => (string) $row['tipe'],
        'modulId' => (string) $row['modul_id'],
        'judulModul' => (string) $row['judul_modul'],
        'timestamp' => to_iso_time($row['waktu']),
    ];
}

function read_profile(int $guruId): array
{
    $guru = find_guru($guruId);

    return [
        'nama' => (string) $guru['nama'],
        'sekolah' => (string) $guru['sekolah'],
        'nip' => (string) $guru['nip'],
        'email' => (string) $guru['email'],
    ];
}

function write_profile(int $guruId, array $data): array
{
    $nama = trim((string) ($data['nama'] ?? ''));
    if ($nama === '') {
        throw new InvalidArgumentException('Nama guru wajib diisi.');
    }

    $sekolah = trim((string) ($data['sekolah'] ?? ''));
    if ($sekolah === '') {
        throw new InvalidArgumentException('Nama sekolah wajib diisi.');
    }

    $current = find_guru($guruId);
    $email = normalize_email($data['email'] ?? '');
    if ($email === '') {
        $email = normalize_email($current['email']);
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new InvalidArgumentException('Format email belum benar.');
    }

    $statement = db()->prepare(
        'SELECT 1 FROM guru WHERE lower(email) = :email AND id <> :id LIMIT 1'
    );
    $statement->execute(['email' => $email, 'id' => $guruId]);
    if ($statement->fetchColumn() !== false) {
        throw new InvalidArgumentException('Email sudah dipakai akun lain.');
    }

    $statement = db()->prepare(
        'UPDATE guru
         SET nama = :nama, sekolah = :sekolah, nip = :nip, email = :email,
             updated_at = NOW()
         WHERE id = :id'
    );
    $statement->execute([
        'nama' => $nama,
        'sekolah' => $sekolah,
        'nip' => (string) ($data['nip'] ?? ''),
        'email' => $email,
        'id' => $guruId,
    ]);

    return read_profile($guruId);
}

function write_theme(int $guruId, array $data): array
{
    $mode = (string) ($data['themeMode'] ?? 'system');
    if (!in_array($mode, THEME_MODES, true)) {
        $mode = 'system';
    }

    $statement = db()->prepare(
        'UPDATE guru SET theme_mode = :theme_mode, updated_at = NOW() WHERE id = :id'
    );
    $statement->execute(['theme_mode' => $mode, 'id' => $guruId]);

    return ['themeMode' => $mode];
}

function find_guru(int $guruId): array
{
    $statement = db()->prepare('SELECT * FROM guru WHERE id = :id');
    $statement->execute(['id' => $guruId]);
    $row = $statement->fetch();

    if ($row === false) {
        throw new InvalidArgumentException('Pengguna tidak ditemukan.');
    }

    return $row;
}

function bootstrap_payload(array $guru): array
{
    $guruId = (int) $guru['id'];

    return [
        'initialized' => to_bool($guru['initialized'] ?? false),
        'modules' => list_modules($guruId),
        'activities' => list_activities($guruId),
        'profile' => read_profile($guruId),
        'themeMode' => (string) ($guru['theme_mode'] ?? 'system'),
    ];
}

function bootstrap_replace(int $guruId, array $data): array
{
    $pdo = db();
    $pdo->beginTransaction();

    try {
        $statement = $pdo->prepare('DELETE FROM aktivitas WHERE guru_id = :guru_id');
        $statement->execute(['guru_id' => $guruId]);
        $statement = $pdo->prepare('DELETE FROM modul_ajar WHERE guru_id = :guru_id');
        $statement->execute(['guru_id' => $guruId]);

        foreach (($data['modules'] ?? []) as $module) {
            if (!is_array($module)) {
                continue;
            }
            save_module(
                $module,
                $guruId,
                isset($module['id']) ? (string) $module['id'] : null,
                true
            );
        }

        foreach (($data['activities'] ?? []) as $activity) {
            if (is_array($activity)) {
                insert_activity($activity, $guruId);
            }
        }

        if (isset($data['profile']) && is_array($data['profile'])) {
            write_profile($guruId, $data['profile']);
        }

        if (isset($data['themeMode'])) {
            write_theme($guruId, ['themeMode' => $data['themeMode']]);
        }

        $statement = $pdo->prepare(
            'UPDATE guru SET initialized = TRUE, updated_at = NOW() WHERE id = :id'
        );
        $statement->execute(['id' => $guruId]);
        $pdo->commit();
    } catch (Throwable $exception) {
        $pdo->rollBack();
        throw $exception;
    }

    return bootstrap_payload(find_guru($guruId));
}

function clean_list(mixed $value): array
{
    if (!is_array($value)) {
        return [];
    }

    $items = [];
    foreach ($value as $item) {
        if (!is_scalar($item)) {
            continue;
        }
        $text = trim((string) $item);
        if ($text !== '') {
            $items[] = $text;
        }
    }

    return array_values(array_unique($items));
}

function decode_list(mixed $value): array
{
    if (is_string($value)) {
        $decoded = json_decode($value, true);
        return is_array($decoded) ? array_values($decoded) : [];
    }

    return is_array($value) ? array_values($value) : [];
}

function to_database_time(mixed $value): string
{
    if (is_string($value) && trim($value) !== '') {
        $timestamp = strtotime($value);
        if ($timestamp !== false) {
            return date('Y-m-d H:i:sP', $timestamp);
        }
    }

    return date('Y-m-d H:i:sP');
}

function to_iso_time(mixed $value): string
{
    if (!is_string($value) || $value === '') {
        return date('c');
    }

    $timestamp = strtotime($value);
    return $timestamp === false ? date('c') : date('c', $timestamp);
}

function generate_id(string $prefix): string
{
    return $prefix . '_' . (int) round(microtime(true) * 1000000) . '_' . random_int(10000, 99999);
}
