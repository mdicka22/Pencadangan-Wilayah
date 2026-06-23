-- =====================================================================
-- SIMADAT — Skema Database Supabase
-- =====================================================================
-- Jalankan file ini di Supabase Dashboard -> SQL Editor -> New Query
-- =====================================================================


-- =====================================================================
-- BAGIAN A — SETUP BARU (tabel belum pernah dibuat sebelumnya)
-- =====================================================================
-- Jalankan blok ini jika Anda BELUM punya tabel "pengajuan" di Supabase.
-- Jika tabel sudah ada, lewati bagian ini dan langsung ke BAGIAN B.

create table if not exists pengajuan (
    id bigint generated always as identity primary key,
    name text not null,
    kab text not null,
    komoditas text,
    luas numeric not null default 0,
    tanggal date not null,
    status text not null default 'Belum Lengkap',
    kelengkapan int not null default 0,
    nib text,
    lat double precision,
    lng double precision,
    docs jsonb not null default '[]',
    created_at timestamptz default now()
);

-- Aktifkan Row Level Security
alter table pengajuan enable row level security;

-- Policy dasar: izinkan semua operasi (baca/tulis/edit/hapus) tanpa login.
-- INI HANYA UNTUK PROTOTIPE / DEMO. Untuk produksi, ganti dengan policy
-- yang lebih ketat (lihat BAGIAN D di bawah, terkait rencana role admin/checker).
create policy "allow all" on pengajuan
    for all
    using (true)
    with check (true);


-- =====================================================================
-- BAGIAN B — MIGRASI (tabel "pengajuan" sudah ada sebelumnya)
-- =====================================================================
-- Jalankan blok ini jika tabel "pengajuan" SUDAH ada dari setup sebelumnya,
-- supaya kolom baru (komoditas) ikut ditambahkan tanpa menghapus data lama.
-- Aman dijalankan berulang kali (tidak akan error jika kolom sudah ada).

alter table pengajuan add column if not exists komoditas text;


-- =====================================================================
-- BAGIAN C — CATATAN TENTANG KOLOM "docs" (jsonb)
-- =====================================================================
-- Kolom "docs" menyimpan seluruh checklist dokumen sebagai array JSON,
-- contoh struktur satu item dokumen:
--
-- {
--   "name": "Surat Permohonan",
--   "status": true,
--   "link": "https://drive.google.com/...",
--   "date": "2026-06-23",
--   "keterangan": "Sudah diverifikasi oleh tim lapangan"
-- }
--
-- Karena tipe data jsonb fleksibel, penambahan field baru di dalam setiap
-- item dokumen (seperti "keterangan") TIDAK memerlukan migrasi tabel —
-- otomatis tertampung tanpa perlu ALTER TABLE.
--
-- Daftar nama dokumen (DOC_NAMES) saat ini didefinisikan di index.html:
--   Surat Permohonan, Rekomendasi Bupati, Rekomendasi PKKPR,
--   Rekomendasi Camat, Rekomendasi Geuchik, AHU, KTP & NPWP, NIB,
--   Beneficial Ownership, Surat Pernyataan, RKAB Disetujui,
--   Peta dan Koordinat
--
-- Jika daftar ini berubah lagi di kemudian hari, perusahaan yang sudah
-- tersimpan akan otomatis disesuaikan oleh fungsi ensureDocsComplete()
-- di index.html saat data dimuat — TIDAK perlu migrasi SQL manual.


-- =====================================================================
-- BAGIAN D — CATATAN UNTUK RENCANA SISTEM AKUN (Admin & Checker)
-- =====================================================================
-- Jika nanti sistem login (Supabase Auth) dan role admin/checker
-- diimplementasikan, BAGIAN A perlu disesuaikan:
--
-- 1. Policy "allow all" di atas HARUS diganti dengan policy berbasis role,
--    misalnya:
--      - Admin: bisa insert/update/delete/select
--      - Checker: hanya bisa select + update kolom docs (checklist saja)
--
-- 2. Akan dibutuhkan tabel tambahan "profiles" untuk menyimpan role user:
--
--    create table profiles (
--        id uuid references auth.users(id) primary key,
--        email text not null,
--        role text not null default 'checker' check (role in ('admin', 'checker')),
--        created_at timestamptz default now()
--    );
--    alter table profiles enable row level security;
--
-- Bagian ini BELUM dijalankan — hanya catatan rencana, menunggu konfirmasi
-- sebelum dieksekusi sebagai tahap terpisah.
