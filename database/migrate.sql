-- Migrasi idempotent dari skema satu-guru ke skema multi-guru.
-- Dijalankan otomatis oleh service `migrate` di docker-compose.yml.
-- Bisa juga dijalankan manual:
--   docker compose exec -T db psql -U modulajar -d modulajar < database/migrate.sql

BEGIN;

-- ---------------------------------------------------------------------------
-- Tabel guru: tambah kolom yang dibutuhkan multi-user.
-- ---------------------------------------------------------------------------
ALTER TABLE guru ADD COLUMN IF NOT EXISTS sekolah VARCHAR(160) NOT NULL DEFAULT '';
ALTER TABLE guru ADD COLUMN IF NOT EXISTS nip VARCHAR(18) NOT NULL DEFAULT '';
ALTER TABLE guru ADD COLUMN IF NOT EXISTS email VARCHAR(160);
ALTER TABLE guru ADD COLUMN IF NOT EXISTS theme_mode VARCHAR(10) NOT NULL DEFAULT 'system';
ALTER TABLE guru ADD COLUMN IF NOT EXISTS initialized BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE guru ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE guru ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE guru ADD COLUMN IF NOT EXISTS password_hash TEXT;

UPDATE guru SET email = '' WHERE email IS NULL;
UPDATE guru
SET password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
WHERE password_hash IS NULL OR password_hash = '';

ALTER TABLE guru ALTER COLUMN email SET NOT NULL;
ALTER TABLE guru ALTER COLUMN password_hash SET NOT NULL;
ALTER TABLE guru DROP CONSTRAINT IF EXISTS guru_satu_baris;

-- Hapus juga CHECK lama yang membatasi id = 1 bila namanya berbeda.
DO $$
DECLARE
    constraint_name RECORD;
BEGIN
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'guru'::regclass
          AND contype = 'c'
          AND pg_get_constraintdef(oid) LIKE '%id = 1%'
    LOOP
        EXECUTE format(
            'ALTER TABLE guru DROP CONSTRAINT %I',
            constraint_name.conname
        );
    END LOOP;
END $$;

-- Guru lama (sebelum ada SERIAL) belum punya sequence. Buat bila perlu lalu
-- sinkronkan dengan id terbesar.
CREATE SEQUENCE IF NOT EXISTS guru_id_seq;
ALTER TABLE guru ALTER COLUMN id SET DEFAULT nextval('guru_id_seq');
SELECT setval(
    'guru_id_seq',
    GREATEST(COALESCE((SELECT MAX(id) FROM guru), 1), 1)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_guru_email_unique
    ON guru (lower(email))
    WHERE email <> '';

-- Pindahkan preferensi global lama (tema + flag initialized) ke guru pertama
-- sebelum tabel pengaturan dihapus.
DO $$
BEGIN
    IF to_regclass('public.pengaturan') IS NOT NULL THEN
        UPDATE guru
        SET theme_mode = COALESCE(
                (SELECT nilai FROM pengaturan WHERE kunci = 'theme'),
                theme_mode
            )
        WHERE id = (SELECT MIN(id) FROM guru);

        UPDATE guru
        SET initialized = COALESCE(
                (SELECT nilai = '1' FROM pengaturan WHERE kunci = 'initialized'),
                initialized
            )
        WHERE id = (SELECT MIN(id) FROM guru);
    END IF;
END $$;

DROP TABLE IF EXISTS pengaturan;

-- Bila database lama sudah berisi modul, jangan seed ulang saat login pertama.
DO $$
BEGIN
    IF to_regclass('public.modul_ajar') IS NOT NULL THEN
        UPDATE guru
        SET initialized = TRUE
        WHERE id = (SELECT MIN(id) FROM guru)
          AND EXISTS (SELECT 1 FROM modul_ajar);
    END IF;
END $$;

-- Akun demo untuk pengujian login. Tidak menimpa akun yang sudah ada.
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

-- ---------------------------------------------------------------------------
-- Tabel modul_ajar: pemilik data + primary key komposit (guru_id, id).
-- ---------------------------------------------------------------------------
ALTER TABLE modul_ajar ADD COLUMN IF NOT EXISTS guru_id INTEGER;
UPDATE modul_ajar
SET guru_id = (SELECT MIN(id) FROM guru)
WHERE guru_id IS NULL;
ALTER TABLE modul_ajar ALTER COLUMN guru_id SET NOT NULL;

DO $$
DECLARE
    pk_cols TEXT;
    pk_name TEXT;
BEGIN
    SELECT
        string_agg(a.attname, ',' ORDER BY a.attnum),
        c.conname
    INTO pk_cols, pk_name
    FROM pg_constraint c
    JOIN pg_attribute a
        ON a.attrelid = c.conrelid
        AND a.attnum = ANY (c.conkey)
    WHERE c.conrelid = 'modul_ajar'::regclass
        AND c.contype = 'p';

    IF pk_cols IS DISTINCT FROM 'guru_id,id' THEN
        IF pk_name IS NOT NULL THEN
            EXECUTE format('ALTER TABLE modul_ajar DROP CONSTRAINT %I', pk_name);
        END IF;
        ALTER TABLE modul_ajar ADD PRIMARY KEY (guru_id, id);
    END IF;
END $$;

ALTER TABLE modul_ajar DROP CONSTRAINT IF EXISTS modul_ajar_guru_fk;
ALTER TABLE modul_ajar
    ADD CONSTRAINT modul_ajar_guru_fk
    FOREIGN KEY (guru_id) REFERENCES guru(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_modul_ajar_guru_updated
    ON modul_ajar (guru_id, updated_at DESC);

-- ---------------------------------------------------------------------------
-- Tabel aktivitas: pemilik data + primary key komposit.
-- ---------------------------------------------------------------------------
ALTER TABLE aktivitas ADD COLUMN IF NOT EXISTS guru_id INTEGER;
UPDATE aktivitas
SET guru_id = (SELECT MIN(id) FROM guru)
WHERE guru_id IS NULL;
ALTER TABLE aktivitas ALTER COLUMN guru_id SET NOT NULL;

DO $$
DECLARE
    pk_cols TEXT;
    pk_name TEXT;
BEGIN
    SELECT
        string_agg(a.attname, ',' ORDER BY a.attnum),
        c.conname
    INTO pk_cols, pk_name
    FROM pg_constraint c
    JOIN pg_attribute a
        ON a.attrelid = c.conrelid
        AND a.attnum = ANY (c.conkey)
    WHERE c.conrelid = 'aktivitas'::regclass
        AND c.contype = 'p';

    IF pk_cols IS DISTINCT FROM 'guru_id,id' THEN
        IF pk_name IS NOT NULL THEN
            EXECUTE format('ALTER TABLE aktivitas DROP CONSTRAINT %I', pk_name);
        END IF;
        ALTER TABLE aktivitas ADD PRIMARY KEY (guru_id, id);
    END IF;
END $$;

ALTER TABLE aktivitas DROP CONSTRAINT IF EXISTS aktivitas_guru_fk;
ALTER TABLE aktivitas
    ADD CONSTRAINT aktivitas_guru_fk
    FOREIGN KEY (guru_id) REFERENCES guru(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_aktivitas_guru_waktu
    ON aktivitas (guru_id, waktu DESC);

COMMIT;
