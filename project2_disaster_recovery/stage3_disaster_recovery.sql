-- stage3_disaster_recovery.sql
-- ============================================================
-- AŞAMA 3: Felaketten Kurtarma Senaryoları
-- Kazayla silinen verilerin geri getirilmesi
-- ============================================================

-- ==========================================
-- SENARYO 1: Kazayla silinen satırların kurtarılması
-- ==========================================

-- Önce mevcut durumu kaydet
SELECT '========== FELAKET ONCESI DURUM ==========' AS rapor;
SELECT 'employees' AS tablo, COUNT(*) AS kayit FROM company.employees
UNION ALL SELECT 'projects', COUNT(*) FROM company.projects
UNION ALL SELECT 'customers', COUNT(*) FROM company.customers;

-- !!! FELAKET: IT departmanı çalışanları yanlışlıkla siliniyor !!!
SELECT '========== !!! FELAKET: IT DEPARTMANI SILINIYOR !!! ==========' AS rapor;

DELETE FROM company.employees WHERE department = 'IT';

-- Silme sonrası durum
SELECT 'Silme sonrasi employees sayisi: ' || COUNT(*) AS sonuc FROM company.employees;
SELECT 'Silinen IT calisanlari geri getirilemiyor (Mevcut tablo uzerinden).' AS uyari;

-- ==========================================
-- SENARYO 2: Kazayla DROP edilen tablonun kurtarılması
-- ==========================================
SELECT '========== !!! FELAKET: CUSTOMERS TABLOSU DROP EDILIYOR !!! ==========' AS rapor;

DROP TABLE company.customers CASCADE;

-- Kontrol: Tablo artık yok
SELECT '========== DROP SONRASI TABLO LISTESI ==========' AS rapor;
SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema = 'company' 
ORDER BY table_name;
