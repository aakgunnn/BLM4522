-- stage2_roles.sql
-- Aşama 2: Kimlik Doğrulama ve Rol/Yetki Yönetimi

-- 1. Yetki Gruplarının (Rol) Oluşturulması
CREATE ROLE readonly_role;
CREATE ROLE admin_role;

-- 2. Login Olabilecek Kullanıcıların Oluşturulması
-- SCRAM-SHA-256 varsayılan olarak desteklenir (PostgreSQL 10+), güvendedir.
CREATE USER app_user WITH PASSWORD 'AppUser123!' LOGIN;
CREATE USER db_admin WITH PASSWORD 'AdminPass123!' LOGIN;

-- 3. Kullanıcıları Gruplara Atama
GRANT readonly_role TO app_user;
GRANT admin_role TO db_admin;

-- 4. Şema Erişim İzinleri
GRANT USAGE ON SCHEMA company TO readonly_role;
GRANT USAGE ON SCHEMA company TO admin_role;

-- 5. Tablo Düzeyinde Yetkilendirme (Least Privilege Prensibi)
-- readonly_role: Sadece veri okuma işlemleri yapabilir.
GRANT SELECT ON ALL TABLES IN SCHEMA company TO readonly_role;

-- admin_role: Tüm CRUD işlemlerini gerçekleştirebilir.
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA company TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA company TO admin_role;
