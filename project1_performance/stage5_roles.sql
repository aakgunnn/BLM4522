-- stage5_roles.sql
-- ============================================================
-- AŞAMA 5: Veri Yöneticisi Rolleri ve Erişim Yönetimi
-- Farklı roller için yetki tanımlama
-- ============================================================

-- ==========================================
-- 1. ROLLERİN OLUŞTURULMASI
-- ==========================================

-- Performans izleme rolü (sadece okuma + sistem görünümleri)
CREATE ROLE perf_monitor;
GRANT CONNECT ON DATABASE perf_demo_db TO perf_monitor;
GRANT USAGE ON SCHEMA public TO perf_monitor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO perf_monitor;

-- Veri analisti rolü (okuma + sınırlı yazma)
CREATE ROLE data_analyst;
GRANT CONNECT ON DATABASE perf_demo_db TO data_analyst;
GRANT USAGE ON SCHEMA public TO data_analyst;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO data_analyst;
-- Analist sadece raporlama tabloları oluşturabilir
GRANT CREATE ON SCHEMA public TO data_analyst;

-- DBA (Veritabanı Yöneticisi) rolü (tam yetki)
CREATE ROLE dba_admin;
GRANT ALL PRIVILEGES ON DATABASE perf_demo_db TO dba_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dba_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dba_admin;

-- ==========================================
-- 2. KULLANICILARIN OLUŞTURULMASI
-- ==========================================

CREATE USER monitor_user WITH PASSWORD 'Monitor123!' LOGIN;
GRANT perf_monitor TO monitor_user;

CREATE USER analyst_user WITH PASSWORD 'Analyst123!' LOGIN;
GRANT data_analyst TO analyst_user;

CREATE USER admin_user WITH PASSWORD 'Admin123!' LOGIN;
GRANT dba_admin TO admin_user;

-- ==========================================
-- 3. YETKİ KONTROLÜ
-- ==========================================
SELECT '========== ROL VE YETKI OZETI ==========' AS rapor;

SELECT
    r.rolname AS rol_adi,
    r.rolcanlogin AS giris_yapabilir,
    r.rolsuper AS super_user,
    r.rolcreatedb AS db_olusturabilir,
    ARRAY(
        SELECT b.rolname
        FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles b ON m.roleid = b.oid
        WHERE m.member = r.oid
    ) AS uye_oldugu_roller
FROM pg_catalog.pg_roles r
WHERE r.rolname IN ('monitor_user', 'analyst_user', 'admin_user',
                     'perf_monitor', 'data_analyst', 'dba_admin')
ORDER BY r.rolname;
