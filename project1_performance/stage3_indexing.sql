-- stage3_indexing.sql
-- ============================================================
-- AŞAMA 3: İndeks Yönetimi
-- İndeks öncesi/sonrası performans karşılaştırması
-- ============================================================

-- ==========================================
-- 1. İNDEKS ÖNCESİ SORGU PERFORMANSI (EXPLAIN ANALYZE)
-- ==========================================
SELECT '========== INDEKS ONCESI PERFORMANS ==========' AS rapor;

-- Test 1: Şehre göre müşteri arama (İndekssiz - Full Table Scan)
EXPLAIN ANALYZE
SELECT * FROM customers WHERE city = 'Ankara' AND is_active = true;

-- Test 2: Tarih aralığında sipariş arama (İndekssiz)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-06-30' AND status = 'Tamamlandi';

-- Test 3: Ürün kategorisine göre arama (İndekssiz)
EXPLAIN ANALYZE
SELECT * FROM products WHERE category = 'Elektronik' AND price > 1000;

-- Test 4: Büyük JOIN sorgusu (İndekssiz)
EXPLAIN ANALYZE
SELECT c.first_name, c.city, o.order_date, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.city = 'Istanbul' AND o.status = 'Tamamlandi'
LIMIT 100;

-- ==========================================
-- 2. İNDEKS OLUŞTURMA
-- ==========================================
SELECT '========== INDEKS OLUSTURMA ==========' AS rapor;

-- Müşteri tablosu: Şehir + aktiflik durumu için bileşik indeks
CREATE INDEX idx_customers_city_active ON customers(city, is_active);

-- Sipariş tablosu: Tarih + durum için bileşik indeks
CREATE INDEX idx_orders_date_status ON orders(order_date, status);

-- Sipariş tablosu: customer_id için indeks (JOIN hızlandırma)
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Ürün tablosu: Kategori + fiyat için bileşik indeks
CREATE INDEX idx_products_category_price ON products(category, price);

-- Sipariş detay: order_id için indeks
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- İstatistikleri güncelle
ANALYZE;

-- ==========================================
-- 3. İNDEKS SONRASI SORGU PERFORMANSI (EXPLAIN ANALYZE)
-- ==========================================
SELECT '========== INDEKS SONRASI PERFORMANS ==========' AS rapor;

-- Test 1 (Tekrar): Şehre göre müşteri arama (İndeksli)
EXPLAIN ANALYZE
SELECT * FROM customers WHERE city = 'Ankara' AND is_active = true;

-- Test 2 (Tekrar): Tarih aralığında sipariş arama (İndeksli)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-06-30' AND status = 'Tamamlandi';

-- Test 3 (Tekrar): Ürün kategorisine göre arama (İndeksli)
EXPLAIN ANALYZE
SELECT * FROM products WHERE category = 'Elektronik' AND price > 1000;

-- Test 4 (Tekrar): Büyük JOIN sorgusu (İndeksli)
EXPLAIN ANALYZE
SELECT c.first_name, c.city, o.order_date, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.city = 'Istanbul' AND o.status = 'Tamamlandi'
LIMIT 100;

-- ==========================================
-- 4. İNDEKS KULLANIM ANALİZİ
-- Gereksiz indekslerin tespiti
-- ==========================================
SELECT '========== INDEKS KULLANIM ANALIZI ==========' AS rapor;

SELECT
    schemaname AS sema,
    relname AS tablo,
    indexrelname AS indeks_adi,
    idx_scan AS kullanim_sayisi,
    pg_size_pretty(pg_relation_size(indexrelid)) AS boyut,
    CASE
        WHEN idx_scan = 0 THEN '!! KULLANILMIYOR - Silinebilir'
        WHEN idx_scan < 10 THEN '! Az kullaniliyor'
        ELSE 'Aktif kullaniliyor'
    END AS durum
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;
