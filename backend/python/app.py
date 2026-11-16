"""Layanan laporan ModulAjar.

API utama (CRUD) ditangani oleh PHP. Layanan Python ini membaca database
PostgreSQL yang sama untuk menghitung rekap dan menyediakan ekspor CSV.
Setiap permintaan wajib membawa token login guru (Authorization: Bearer ...).
"""

import csv
import hashlib
import io
import os

import psycopg2
from fastapi import FastAPI, Header, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from psycopg2.extras import RealDictCursor

app = FastAPI(
    title="ModulAjar Report Service",
    description="Layanan rekap dan ekspor data modul ajar per guru.",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "modulajar"),
        user=os.getenv("DB_USER", "modulajar"),
        password=os.getenv("DB_PASSWORD", "modulajar123"),
    )


def current_guru_id(authorization: str | None) -> int:
    """Validasi bearer token terhadap tabel sesi dan kembalikan id guru."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=401,
            detail="Silakan masuk terlebih dahulu.",
        )

    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(
            status_code=401,
            detail="Silakan masuk terlebih dahulu.",
        )

    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    connection = connect()
    try:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                SELECT guru_id
                FROM sesi
                WHERE token_hash = %s AND kedaluwarsa_at > NOW()
                LIMIT 1
                """,
                (token_hash,),
            )
            row = cursor.fetchone()
    finally:
        connection.close()

    if row is None:
        raise HTTPException(
            status_code=401,
            detail="Sesi sudah berakhir. Silakan masuk kembali.",
        )

    return int(row["guru_id"])


@app.get("/health")
def health():
    connection = connect()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    finally:
        connection.close()
    return {"status": "ok", "service": "python-report"}


@app.get("/report/summary")
def report_summary(authorization: str | None = Header(default=None)):
    guru_id = current_guru_id(authorization)

    connection = connect()
    try:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                SELECT
                    COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE status = 'terbit') AS terbit,
                    COUNT(*) FILTER (WHERE status = 'draft') AS draft,
                    COUNT(*) FILTER (WHERE favorit) AS favorit,
                    COALESCE(SUM(alokasi_jp), 0) AS total_jp
                FROM modul_ajar
                WHERE guru_id = %s
                """,
                (guru_id,),
            )
            totals = cursor.fetchone()

            cursor.execute(
                """
                SELECT
                    mata_pelajaran,
                    COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE status = 'terbit') AS terbit,
                    COALESCE(SUM(alokasi_jp), 0) AS total_jp
                FROM modul_ajar
                WHERE guru_id = %s
                GROUP BY mata_pelajaran
                ORDER BY total DESC, mata_pelajaran ASC
                """,
                (guru_id,),
            )
            per_mapel = cursor.fetchall()

            cursor.execute(
                "SELECT COUNT(*) AS total FROM aktivitas WHERE guru_id = %s",
                (guru_id,),
            )
            activities = cursor.fetchone()["total"]
    finally:
        connection.close()

    return {
        "totalModul": int(totals["total"]),
        "totalTerbit": int(totals["terbit"]),
        "totalDraft": int(totals["draft"]),
        "totalFavorit": int(totals["favorit"]),
        "totalJp": int(totals["total_jp"]),
        "totalAktivitas": int(activities),
        "perMapel": [
            {
                "mataPelajaran": row["mata_pelajaran"],
                "total": int(row["total"]),
                "terbit": int(row["terbit"]),
                "totalJp": int(row["total_jp"]),
            }
            for row in per_mapel
        ],
        "dihasilkanOleh": "python-report",
    }


@app.get("/report/modules.csv")
def report_csv(authorization: str | None = Header(default=None)):
    guru_id = current_guru_id(authorization)

    connection = connect()
    try:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                SELECT
                    id, judul, mata_pelajaran, kelas, semester,
                    alokasi_jp, status, favorit, updated_at
                FROM modul_ajar
                WHERE guru_id = %s
                ORDER BY updated_at DESC
                """,
                (guru_id,),
            )
            rows = cursor.fetchall()
    finally:
        connection.close()

    buffer = io.StringIO()
    writer = csv.writer(buffer, delimiter=";", lineterminator="\n")
    writer.writerow(
        [
            "ID",
            "Judul",
            "Mata Pelajaran",
            "Kelas",
            "Semester",
            "Alokasi JP",
            "Status",
            "Favorit",
            "Diperbarui",
        ]
    )
    for row in rows:
        writer.writerow(
            [
                row["id"],
                row["judul"],
                row["mata_pelajaran"],
                row["kelas"],
                row["semester"],
                row["alokasi_jp"],
                row["status"],
                "Ya" if row["favorit"] else "Tidak",
                row["updated_at"].isoformat(),
            ]
        )

    return Response(
        content=buffer.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": 'attachment; filename="modul_ajar.csv"',
        },
    )
