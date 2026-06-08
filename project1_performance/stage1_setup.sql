-- stage1_setup.sql
-- ============================================================
-- AŞAMA 1: Büyük Veritabanı Ortamının Hazırlanması
-- Performans testleri için yüz binlerce satırlık veri üretimi
-- ============================================================

-- 1. Müşteriler tablosu (100.000 kayıt)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(50),
    registration_date DATE,
    is_active BOOLEAN DEFAULT true
);

-- 2. Ürünler tablosu (1.000 kayıt)
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price NUMERIC(10,2),
    stock_quantity INTEGER
);

-- 3. Siparişler tablosu (500.000 kayıt)
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date DATE,
    total_amount NUMERIC(12,2),
    status VARCHAR(20)
);

-- 4. Sipariş detayları tablosu (1.000.000 kayıt)
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    unit_price NUMERIC(10,2)
);

-- ============================================================
-- VERİ ÜRETİMİ (generate_series ile toplu veri)
-- ============================================================

-- Müşteri verisi üretimi (100.000 adet)
INSERT INTO customers (first_name, last_name, email, city, registration_date, is_active)
SELECT
    'Musteri_' || i,
    'Soyad_' || (i % 500),
    'musteri_' || i || '@firma.com',
    (ARRAY['Ankara','Istanbul','Izmir','Bursa','Antalya','Trabzon','Konya','Adana'])[1 + (i % 8)],
    '2020-01-01'::DATE + (i % 1500),
    (i % 10 != 0)  -- %10'u pasif
FROM generate_series(1, 100000) AS s(i);

-- Ürün verisi üretimi (1.000 adet)
INSERT INTO products (product_name, category, price, stock_quantity)
SELECT
    'Urun_' || i,
    (ARRAY['Elektronik','Giyim','Gida','Mobilya','Kitap','Spor','Oyuncak','Kozmetik'])[1 + (i % 8)],
    ROUND((RANDOM() * 5000 + 10)::NUMERIC, 2),
    (RANDOM() * 1000)::INTEGER
FROM generate_series(1, 1000) AS s(i);

-- Sipariş verisi üretimi (500.000 adet)
INSERT INTO orders (customer_id, order_date, total_amount, status)
SELECT
    1 + (i % 100000),
    '2022-01-01'::DATE + (i % 1095),
    ROUND((RANDOM() * 10000 + 50)::NUMERIC, 2),
    (ARRAY['Tamamlandi','Beklemede','Iptal','Kargoda'])[1 + (i % 4)]
FROM generate_series(1, 500000) AS s(i);

-- Sipariş detay verisi üretimi (1.000.000 adet)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    1 + (i % 500000),
    1 + (i % 1000),
    1 + (i % 10),
    ROUND((RANDOM() * 2000 + 5)::NUMERIC, 2)
FROM generate_series(1, 1000000) AS s(i);

-- İstatistikleri güncelle
ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;

-- Kontrol
SELECT 'customers' AS tablo, COUNT(*) AS kayit_sayisi FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
