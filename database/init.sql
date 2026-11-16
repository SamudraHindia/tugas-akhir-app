-- Skema basis data ModulAjar (multi-guru).
-- File ini dijalankan otomatis oleh container PostgreSQL saat volume masih kosong.
-- Untuk volume lama, jalankan database/migrate.sql (service `migrate` pada
-- docker-compose akan menjalankannya setiap kali `docker compose up`).

CREATE TABLE IF NOT EXISTS guru (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(120) NOT NULL,
    sekolah VARCHAR(160) NOT NULL DEFAULT '',
    nip VARCHAR(18) NOT NULL DEFAULT '',
    email VARCHAR(160) NOT NULL,
    password_hash TEXT NOT NULL,
    theme_mode VARCHAR(10) NOT NULL DEFAULT 'system'
        CHECK (theme_mode IN ('system', 'light', 'dark')),
    initialized BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Email login harus unik. Indeks parsial agar baris lama dengan email kosong
-- tidak saling bentrok.
CREATE UNIQUE INDEX IF NOT EXISTS idx_guru_email_unique
    ON guru (lower(email))
    WHERE email <> '';

-- Akun demo. Password: "password" (hash bcrypt di bawah).
-- Ganti atau hapus akun demo sebelum dipakai di produksi.
INSERT INTO guru (nama, sekolah, nip, email, password_hash)
SELECT
    'Rizal Pratama',
    'SMA Negeri 1 Bandung',
    '198705122015031004',
    'demo@modulajar.local',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
WHERE NOT EXISTS (
    SELECT 1 FROM guru WHERE lower(email) = 'demo@modulajar.local'
);

CREATE TABLE IF NOT EXISTS modul_ajar (
    guru_id INTEGER NOT NULL CONSTRAINT modul_ajar_guru_fk
        REFERENCES guru(id) ON DELETE CASCADE,
    id VARCHAR(64) NOT NULL,
    judul VARCHAR(200) NOT NULL,
    mata_pelajaran VARCHAR(100) NOT NULL,
    kelas VARCHAR(5) NOT NULL,
    semester VARCHAR(10) NOT NULL,
    alokasi_jp INTEGER NOT NULL DEFAULT 2,
    deskripsi TEXT NOT NULL DEFAULT '',
    tujuan_pembelajaran JSONB NOT NULL DEFAULT '[]'::jsonb,
    materi_pokok JSONB NOT NULL DEFAULT '[]'::jsonb,
    kegiatan_pembelajaran TEXT NOT NULL DEFAULT '',
    asesmen TEXT NOT NULL DEFAULT '',
    status VARCHAR(10) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'terbit')),
    favorit BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (guru_id, id)
);

CREATE INDEX IF NOT EXISTS idx_modul_ajar_guru_updated
    ON modul_ajar (guru_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS aktivitas (
    guru_id INTEGER NOT NULL CONSTRAINT aktivitas_guru_fk
        REFERENCES guru(id) ON DELETE CASCADE,
    id VARCHAR(64) NOT NULL,
    tipe VARCHAR(30) NOT NULL,
    modul_id VARCHAR(64) NOT NULL DEFAULT '',
    judul_modul VARCHAR(200) NOT NULL,
    waktu TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (guru_id, id)
);

CREATE INDEX IF NOT EXISTS idx_aktivitas_guru_waktu
    ON aktivitas (guru_id, waktu DESC);

CREATE TABLE IF NOT EXISTS sesi (
    token_hash VARCHAR(64) PRIMARY KEY,
    guru_id INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    dibuat_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    kedaluwarsa_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sesi_kedaluwarsa
    ON sesi (kedaluwarsa_at);
