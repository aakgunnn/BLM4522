-- stage4_audit.sql
-- Aşama 4: Audit Logları (Denetim Günlükleri)

-- PostgreSQL'in yerleşik log mekanizmasını kullanarak tüm SQL komutlarını, 
-- bağlantı ve kopmaları kaydetmesini sağlıyoruz.
-- (Büyük sistemlerde log_statement = 'all' yerine 'mod' veya 'ddl' önerilir, 
--  fakat biz test/audit aracı olarak kullanacağımız için 'all' yapıyoruz.)

ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';

-- pgaudit eklentisi standart Windows kurulumlarında varsayılan gelmediği için 
-- Native PostgreSQL Audit özelliklerini kullandık.

-- Yapılan değişikliklerin (yeniden başlatmadan yüklenebilenlerin) devreye girmesi için:
SELECT pg_reload_conf();

-- Not: Log dosyaları genellikle C:\Program Files\PostgreSQL\18\data\log\ klasörü altında oluşur.
