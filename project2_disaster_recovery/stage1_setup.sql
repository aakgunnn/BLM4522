-- stage1_setup.sql
-- ============================================================
-- AŞAMA 1: Test Veritabanı ve Tabloların Hazırlanması
-- Felaketten kurtarma senaryoları için örnek veri ortamı
-- ============================================================

-- Şirket şeması
CREATE SCHEMA IF NOT EXISTS company;

-- 1. Çalışanlar Tablosu
CREATE TABLE company.employees (
    emp_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE DEFAULT CURRENT_DATE
);

-- 2. Projeler Tablosu
CREATE TABLE company.projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget NUMERIC(12,2),
    start_date DATE,
    status VARCHAR(20) DEFAULT 'Aktif'
);

-- 3. Müşteriler Tablosu (Kritik Veri)
CREATE TABLE company.customers (
    customer_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    city VARCHAR(50),
    total_revenue NUMERIC(12,2) DEFAULT 0
);

-- Örnek veri üretimi
INSERT INTO company.employees (full_name, department, salary, hire_date)
SELECT
    'Calisan_' || i,
    (ARRAY['IT','HR','Finance','Engineering','Marketing'])[1 + (i % 5)],
    ROUND((30000 + RANDOM() * 70000)::NUMERIC, 2),
    '2020-01-01'::DATE + (i % 1500)
FROM generate_series(1, 10000) AS s(i);

INSERT INTO company.projects (project_name, budget, start_date, status)
SELECT
    'Proje_' || i,
    ROUND((50000 + RANDOM() * 500000)::NUMERIC, 2),
    '2023-01-01'::DATE + (i % 730),
    (ARRAY['Aktif','Tamamlandi','Beklemede','Iptal'])[1 + (i % 4)]
FROM generate_series(1, 500) AS s(i);

INSERT INTO company.customers (company_name, contact_email, city, total_revenue)
SELECT
    'Firma_' || i,
    'firma_' || i || '@email.com',
    (ARRAY['Ankara','Istanbul','Izmir','Bursa','Antalya'])[1 + (i % 5)],
    ROUND((10000 + RANDOM() * 1000000)::NUMERIC, 2)
FROM generate_series(1, 5000) AS s(i);

-- Kontrol
SELECT 'employees' AS tablo, COUNT(*) AS kayit FROM company.employees
UNION ALL SELECT 'projects', COUNT(*) FROM company.projects
UNION ALL SELECT 'customers', COUNT(*) FROM company.customers;
