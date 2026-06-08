-- stage2_transform.sql
-- ============================================================
-- TRANSFORM (Veri Dönüştürme): Temizleme, doğrulama ve standartlaştırma
-- ============================================================

-- ==========================================
-- A) MÜŞTERİ VERİSİ TEMİZLEME
-- ==========================================

-- 1. Hedef temiz tabloyu oluştur
DROP TABLE IF EXISTS clean_orders CASCADE;
DROP TABLE IF EXISTS clean_customers CASCADE;

CREATE TABLE clean_customers (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    city VARCHAR(50),
    registration_date DATE,
    total_spent NUMERIC(12,2) DEFAULT 0.00
);

-- 2. Veri dönüştürme ve temizleme ile yükleme
-- Kurallar:
--   a) İsim boş olan satırları atla (full_name IS NULL veya '')
--   b) Email formatı geçersiz olanları atla (@ ve . içermeli)
--   c) Duplicate kayıtları atla (email bazında ilk kaydı al)
--   d) Şehir adlarını standartlaştır (INITCAP)
--   e) Email'leri küçük harfe çevir (LOWER)
--   f) İsimlerdeki fazla boşlukları temizle (TRIM + REGEXP_REPLACE)
--   g) Negatif tutarları 0'a çek (GREATEST)
--   h) NULL / 'NULL' tutarları 0'a çek (COALESCE + CASE)
--   i) Farklı tarih formatlarını standartlaştır

INSERT INTO clean_customers (full_name, email, phone, city, registration_date, total_spent)
SELECT
    -- İsim: Baştaki/sondaki ve çift boşlukları temizle
    REGEXP_REPLACE(TRIM(full_name), '\s+', ' ', 'g') AS full_name,
    
    -- Email: Küçük harfe çevir
    LOWER(TRIM(email)) AS email,
    
    -- Telefon: Sadece rakamları al ve +90 formatına çevir
    CASE
        WHEN phone IS NULL OR TRIM(phone) = '' THEN NULL
        WHEN LENGTH(REGEXP_REPLACE(phone, '\D', '', 'g')) = 12 
            THEN '+' || SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 1, 2) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 3, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 6, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 9, 4)
        WHEN LENGTH(REGEXP_REPLACE(phone, '\D', '', 'g')) = 11 
            THEN '+90 ' || SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 2, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 5, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 8, 4)
        WHEN LENGTH(REGEXP_REPLACE(phone, '\D', '', 'g')) = 10 
            THEN '+90 ' || SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 1, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 4, 3) || ' ' ||
                 SUBSTRING(REGEXP_REPLACE(phone, '\D', '', 'g'), 7, 4)
        ELSE NULL
    END AS phone,
    
    -- Şehir: İlk harf büyük standardı
    INITCAP(TRIM(city)) AS city,
    
    -- Tarih: Farklı formatları standartlaştır
    CASE
        WHEN registration_date ~ '^\d{4}-\d{2}-\d{2}$' 
            THEN TO_DATE(registration_date, 'YYYY-MM-DD')
        WHEN registration_date ~ '^\d{2}/\d{2}/\d{4}$' 
            THEN TO_DATE(registration_date, 'DD/MM/YYYY')
        WHEN registration_date ~ '^\d{4}/\d{2}/\d{2}$' 
            THEN TO_DATE(registration_date, 'YYYY/MM/DD')
        ELSE NULL
    END AS registration_date,
    
    -- Tutar: Negatif ve NULL değerleri düzelt
    GREATEST(
        COALESCE(
            CASE 
                WHEN UPPER(TRIM(total_spent)) = 'NULL' OR TRIM(total_spent) = '' THEN 0
                ELSE CAST(total_spent AS NUMERIC(12,2))
            END,
            0
        ),
        0
    ) AS total_spent

FROM (
    -- Duplicate kontrolü: Her email için sadece ilk kaydı al (en küçük id)
    SELECT DISTINCT ON (LOWER(TRIM(email))) *
    FROM staging_customers
    WHERE 
        -- İsim boş olmamalı
        TRIM(COALESCE(full_name, '')) != ''
        -- Email geçerli formatta olmalı (en az bir @ ve bir . içermeli)
        AND TRIM(email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ORDER BY LOWER(TRIM(email)), id::INTEGER
) AS deduplicated;

-- ==========================================
-- B) SİPARİŞ VERİSİ TEMİZLEME
-- ==========================================

CREATE TABLE clean_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES clean_customers(customer_id),
    product VARCHAR(100) NOT NULL,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC(12,2) DEFAULT 0.00,
    order_date DATE,
    status VARCHAR(20)
);

-- Sipariş verisini temizle ve yükle
-- Kurallar:
--   a) Miktar sayısal olmalı ve > 0
--   b) Müşteri ID, staging_customers'ta bulunmalı (referans bütünlüğü)
--   c) Duplicate siparişleri atla
--   d) Sipariş durumunu standartlaştır
--   e) Tarih formatını standartlaştır

INSERT INTO clean_orders (order_id, customer_id, product, quantity, unit_price, order_date, status)
SELECT
    so.order_id::INTEGER,
    cc.customer_id,
    TRIM(so.product),
    so.quantity::INTEGER,
    COALESCE(NULLIF(TRIM(so.unit_price), '')::NUMERIC(12,2), 0.00),
    
    -- Tarih standardizasyonu
    CASE
        WHEN so.order_date ~ '^\d{4}-\d{2}-\d{2}$' 
            THEN TO_DATE(so.order_date, 'YYYY-MM-DD')
        WHEN so.order_date ~ '^\d{2}/\d{2}/\d{4}$' 
            THEN TO_DATE(so.order_date, 'DD/MM/YYYY')
        ELSE NULL
    END,
    
    -- Durum standardizasyonu
    CASE LOWER(TRIM(so.status))
        WHEN 'tamamlandi' THEN 'Tamamlandı'
        WHEN 'beklemede'  THEN 'Beklemede'
        WHEN 'iptal'      THEN 'İptal'
        ELSE TRIM(so.status)
    END

FROM (
    -- Duplicate sipariş kontrolü (müşteri + ürün + tarih bazında ilk kayıt)
    SELECT DISTINCT ON (customer_id, product, order_date) *
    FROM staging_orders
    WHERE
        -- Miktar sayısal ve pozitif olmalı
        quantity ~ '^\d+$' AND quantity::INTEGER > 0
    ORDER BY customer_id, product, order_date, order_id
) AS so
-- Sadece staging'de var olan ve temiz tabloya geçmiş müşterileri eşleştir
INNER JOIN staging_customers sc ON sc.id = so.customer_id
    AND TRIM(COALESCE(sc.full_name, '')) != ''
    AND TRIM(sc.email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
INNER JOIN clean_customers cc ON LOWER(TRIM(sc.email)) = cc.email;
