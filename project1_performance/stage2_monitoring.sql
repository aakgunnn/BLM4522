-- stage2_monitoring.sql
-- ============================================================
-- AŞAMA 2: Veritabanı İzleme (Monitoring)
-- PostgreSQL'de DMV karşılığı: pg_stat_* sistem görünümleri
-- ============================================================

-- ==========================================
-- 1. TABLO İSTATİSTİKLERİ (pg_stat_user_tables)
-- SQL Server'daki DMV'lerin PostgreSQL karşılığı
-- ==========================================
SELECT '========== TABLO ISTATISTIKLERI (DMV Karsiligi) ==========' AS rapor;

SELECT
    schemaname AS sema,
    relname AS tablo_adi,
    n_live_tup AS canli_satir,
    n_dead_tup AS olü_satir,
    seq_scan AS sirasal_tarama,
    idx_scan AS indeks_tarama,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- ==========================================
-- 2. AKTİF OTURUMLAR (pg_stat_activity)
-- SQL Profiler'ın PostgreSQL karşılığı
-- ==========================================
SELECT '========== AKTIF OTURUMLAR (SQL Profiler Karsiligi) ==========' AS rapor;

SELECT
    pid AS islem_id,
    usename AS kullanici,
    datname AS veritabani,
    state AS durum,
    LEFT(query, 80) AS sorgu_baslangici,
    query_start AS sorgu_baslama,
    NOW() - query_start AS gecen_sure
FROM pg_stat_activity
WHERE datname = 'perf_demo_db'
  AND state IS NOT NULL
ORDER BY query_start DESC
LIMIT 10;

-- ==========================================
-- 3. TABLO BOYUTLARI VE DİSK ALANI YÖNETİMİ
-- ==========================================
SELECT '========== DISK ALANI YONETIMI ==========' AS rapor;

SELECT
    tablename AS tablo,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS toplam_boyut,
    pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS veri_boyutu,
    pg_size_pretty(
        pg_total_relation_size(schemaname || '.' || tablename) -
        pg_relation_size(schemaname || '.' || tablename)
    ) AS indeks_boyutu
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;

-- ==========================================
-- 4. VERITABANI GENEL BOYUTU
-- ==========================================
SELECT '========== VERITABANI BOYUTU ==========' AS rapor;

SELECT
    pg_size_pretty(pg_database_size('perf_demo_db')) AS veritabani_toplam_boyut;

-- ==========================================
-- 5. MEVCUT İNDEKSLER
-- ==========================================
SELECT '========== MEVCUT INDEKSLER ==========' AS rapor;

SELECT
    indexname AS indeks_adi,
    tablename AS tablo,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS indeks_boyutu
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexname::regclass) DESC;
