-- stage1_schema.sql
-- Aşama 1: Şema ve Tabloların Oluşturulması

-- Örnek veri ayrımı için özel bir şema oluşturuyoruz
CREATE SCHEMA company;

-- 1. Çalışanlar Tablosu
CREATE TABLE company.employees (
    emp_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    salary NUMERIC(10, 2)
);

-- 2. Sistem Kullanıcıları Tablosu (Uygulamanın veritabanı kullanıcılarını simüle eder)
CREATE TABLE company.users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Finansal Kayıtlar Tablosu (Hassas Veriler - Aşama 3'te şifreleme örneği için kullanılacak)
CREATE TABLE company.financial_records (
    record_id SERIAL PRIMARY KEY,
    transaction_title VARCHAR(150),
    amount NUMERIC(12, 2),
    credit_card_info VARCHAR(255) -- Hassas Bilgi (Baştan düz metin olarak eklenecek, sonra şifrelenecek)
);

-- ÖRNEK VERİLERİN EKLENMESİ

INSERT INTO company.employees (full_name, department, salary) VALUES 
('Ahmet Akgun', 'Developer', 150000.00),
('Ayşe Kaya', 'HR', 38000.00),
('Mehmet Demir', 'Finance', 42000.00),
('Elif Çelik', 'Engineering', 55000.00);

INSERT INTO company.users (username, email, password_hash) VALUES 
('ahmet_it', 'ahmet.akgun@company.com', 'hashed_pass_1'),
('ayse_hr', 'ayse.kaya@company.com', 'hashed_pass_2');

INSERT INTO company.financial_records (transaction_title, amount, credit_card_info) VALUES 
('Aylık Sunucu Gideri', 15000.00, '4242-4242-4242-4242'),
('Danışmanlık Faturası', 25000.00, '5555-4444-3333-2222'),
('Personel Avansı', 5000.00, '1234-5678-9012-3456');
