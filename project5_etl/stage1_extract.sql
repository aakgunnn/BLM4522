-- stage1_extract.sql
-- ============================================================
-- EXTRACT (Veri Çıkarma): Ham verilerin staging tablolarına yüklenmesi
-- ============================================================

-- 1. Staging (Ham) Tabloların Oluşturulması
-- Tüm sütunlar VARCHAR olarak tutulur, çünkü ham veri güvenilmezdir.

DROP TABLE IF EXISTS staging_orders CASCADE;
DROP TABLE IF EXISTS staging_customers CASCADE;

CREATE TABLE staging_customers (
    id VARCHAR(10),
    full_name VARCHAR(200),
    email VARCHAR(200),
    phone VARCHAR(50),
    city VARCHAR(100),
    registration_date VARCHAR(50),
    total_spent VARCHAR(50)
);

CREATE TABLE staging_orders (
    order_id VARCHAR(10),
    customer_id VARCHAR(10),
    product VARCHAR(200),
    quantity VARCHAR(50),
    unit_price VARCHAR(50),
    order_date VARCHAR(50),
    status VARCHAR(50)
);

-- 2. CSV Dosyalarından Veri Yükleme (COPY komutu)
-- Not: Dosya yolunu kendi sisteminize göre ayarlayın.

\copy staging_customers(id, full_name, email, phone, city, registration_date, total_spent) FROM 'raw_data_customers.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

\copy staging_orders(order_id, customer_id, product, quantity, unit_price, order_date, status) FROM 'raw_data_orders.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 3. Ham veri kontrolü
SELECT 'Staging Müşteri Sayısı: ' || COUNT(*) AS sonuc FROM staging_customers
UNION ALL
SELECT 'Staging Sipariş Sayısı: ' || COUNT(*) FROM staging_orders;
