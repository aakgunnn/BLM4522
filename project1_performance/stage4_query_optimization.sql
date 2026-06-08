-- stage4_query_optimization.sql
-- ============================================================
-- AŞAMA 4: Sorgu İyileştirme (Query Optimization)
-- Uzun süren sorguları analiz etme ve optimize etme
-- ============================================================

-- ==========================================
-- 1. YAVAŞ SORGU: Alt Sorgu (Subquery) Kullanımı
-- ==========================================
SELECT '========== YAVAS SORGU: Alt Sorgu ==========' AS rapor;

-- KÖTÜ: Her müşteri için alt sorgu (N+1 problemi simülasyonu)
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.first_name,
    c.city,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS siparis_sayisi,
    (SELECT SUM(total_amount) FROM orders o WHERE o.customer_id = c.customer_id) AS toplam_harcama
FROM customers c
WHERE c.city = 'Ankara' AND c.is_active = true
LIMIT 100;

-- OPTİMİZE: JOIN + GROUP BY ile tek sorguda
SELECT '========== OPTIMIZE: JOIN + GROUP BY ==========' AS rapor;

EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.first_name,
    c.city,
    COUNT(o.order_id) AS siparis_sayisi,
    COALESCE(SUM(o.total_amount), 0) AS toplam_harcama
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE c.city = 'Ankara' AND c.is_active = true
GROUP BY c.customer_id, c.first_name, c.city
LIMIT 100;

-- ==========================================
-- 2. YAVAŞ SORGU: SELECT * Kullanımı
-- ==========================================
SELECT '========== YAVAS SORGU: SELECT * ==========' AS rapor;

-- KÖTÜ: Tüm sütunları çekme (gereksiz veri transferi)
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'Tamamlandi'
ORDER BY order_date DESC
LIMIT 1000;

-- OPTİMİZE: Sadece gerekli sütunları çekme
SELECT '========== OPTIMIZE: Sadece Gerekli Sutunlar ==========' AS rapor;

EXPLAIN ANALYZE
SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE status = 'Tamamlandi'
ORDER BY order_date DESC
LIMIT 1000;

-- ==========================================
-- 3. YAVAŞ SORGU: Fonksiyon Kullanımı (Index Bypass)
-- ==========================================
SELECT '========== YAVAS SORGU: Fonksiyon ile Index Bypass ==========' AS rapor;

-- KÖTÜ: WHERE'de fonksiyon kullanımı (indeks devre dışı kalır)
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE UPPER(city) = 'ANKARA';

-- OPTİMİZE: Doğrudan değer karşılaştırması (indeks kullanılır)
SELECT '========== OPTIMIZE: Dogrudan Karsilastirma ==========' AS rapor;

EXPLAIN ANALYZE
SELECT * FROM customers
WHERE city = 'Ankara';

-- ==========================================
-- 4. KARMAŞIK RAPOR SORGUSU OPTİMİZASYONU
-- ==========================================
SELECT '========== KARMASIK RAPOR: Sehir Bazli Ciro ==========' AS rapor;

-- Şehir bazlı aylık ciro raporu (optimize edilmiş)
EXPLAIN ANALYZE
SELECT
    c.city AS sehir,
    DATE_TRUNC('month', o.order_date) AS ay,
    COUNT(o.order_id) AS siparis_sayisi,
    ROUND(SUM(o.total_amount), 2) AS toplam_ciro,
    ROUND(AVG(o.total_amount), 2) AS ortalama_siparis
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'Tamamlandi'
  AND o.order_date >= '2024-01-01'
GROUP BY c.city, DATE_TRUNC('month', o.order_date)
ORDER BY toplam_ciro DESC
LIMIT 20;
