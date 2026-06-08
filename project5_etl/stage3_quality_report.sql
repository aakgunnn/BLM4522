-- stage3_quality_report.sql
-- ============================================================
-- VERİ KALİTESİ RAPORU: Temizleme ve yükleme sonrası denetim sorguları
-- ============================================================

-- ==========================================
-- 1. GENEL ÖZET
-- ==========================================
SELECT '========== GENEL OZET ==========' AS rapor;

SELECT 'Ham Musteri Sayisi' AS metrik, COUNT(*)::TEXT AS deger FROM staging_customers
UNION ALL
SELECT 'Temiz Musteri Sayisi', COUNT(*)::TEXT FROM clean_customers
UNION ALL
SELECT 'Ham Siparis Sayisi', COUNT(*)::TEXT FROM staging_orders
UNION ALL
SELECT 'Temiz Siparis Sayisi', COUNT(*)::TEXT FROM clean_orders;

-- ==========================================
-- 2. ATLANAN KAYITLAR (Müşteri)
-- ==========================================
SELECT '========== ATLANAN MUSTERILER ==========' AS rapor;

-- İsmi boş olanlar
SELECT 'Eksik isim' AS neden, id, email
FROM staging_customers
WHERE TRIM(COALESCE(full_name, '')) = '';

-- Geçersiz email
SELECT 'Gecersiz email' AS neden, id, email
FROM staging_customers
WHERE TRIM(COALESCE(full_name, '')) != ''
  AND NOT (TRIM(email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Duplicate (tekrar eden)
SELECT 'Duplicate kayit' AS neden, id, email
FROM staging_customers
WHERE LOWER(TRIM(email)) IN (
    SELECT LOWER(TRIM(email))
    FROM staging_customers
    WHERE TRIM(COALESCE(full_name, '')) != ''
      AND TRIM(email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    GROUP BY LOWER(TRIM(email))
    HAVING COUNT(*) > 1
)
AND id::INTEGER NOT IN (
    SELECT MIN(id::INTEGER)
    FROM staging_customers
    WHERE TRIM(COALESCE(full_name, '')) != ''
      AND TRIM(email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    GROUP BY LOWER(TRIM(email))
);

-- ==========================================
-- 3. ATLANAN KAYITLAR (Sipariş)
-- ==========================================
SELECT '========== ATLANAN SIPARISLER ==========' AS rapor;

-- Geçersiz miktar (sayısal değil veya <= 0)
SELECT 'Gecersiz miktar' AS neden, order_id, quantity
FROM staging_orders
WHERE NOT (quantity ~ '^\d+$') OR quantity::INTEGER <= 0;

-- Sistemde olmayan müşteri
SELECT 'Gecersiz musteri ID' AS neden, order_id, customer_id
FROM staging_orders
WHERE quantity ~ '^\d+$' AND quantity::INTEGER > 0
  AND customer_id::INTEGER NOT IN (
      SELECT id::INTEGER FROM staging_customers
      WHERE TRIM(COALESCE(full_name, '')) != ''
        AND TRIM(email) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  );

-- ==========================================
-- 4. DÖNÜŞTÜRME DETAYLARI
-- ==========================================
SELECT '========== DONUSTURME DETAYLARI ==========' AS rapor;

-- Negatif tutar düzeltmeleri
SELECT 'Negatif tutar duzeltildi' AS islem, id, full_name, total_spent AS orijinal_deger
FROM staging_customers
WHERE total_spent ~ '^-' AND TRIM(COALESCE(full_name, '')) != '';

-- NULL tutar düzeltmeleri
SELECT 'NULL tutar duzeltildi' AS islem, id, full_name, total_spent AS orijinal_deger
FROM staging_customers
WHERE (UPPER(TRIM(total_spent)) = 'NULL' OR TRIM(COALESCE(total_spent, '')) = '')
  AND TRIM(COALESCE(full_name, '')) != '';

-- ==========================================
-- 5. TEMİZ VERİ DOĞRULAMA
-- ==========================================
SELECT '========== TEMIZ VERI DOGRULAMA ==========' AS rapor;

-- Temiz müşteri listesi
SELECT customer_id, full_name, email, phone, city, registration_date, total_spent
FROM clean_customers
ORDER BY customer_id;

-- Temiz sipariş listesi
SELECT o.order_id, c.full_name AS musteri, o.product, o.quantity, o.unit_price, o.order_date, o.status
FROM clean_orders o
JOIN clean_customers c ON o.customer_id = c.customer_id
ORDER BY o.order_id;

-- ==========================================
-- 6. İSTATİSTİKLER
-- ==========================================
SELECT '========== ISTATISTIKLER ==========' AS rapor;

-- Şehir bazlı müşteri dağılımı
SELECT city AS sehir, COUNT(*) AS musteri_sayisi
FROM clean_customers
GROUP BY city
ORDER BY musteri_sayisi DESC;

-- Durum bazlı sipariş dağılımı
SELECT status AS durum, COUNT(*) AS siparis_sayisi, SUM(quantity * unit_price) AS toplam_ciro
FROM clean_orders
GROUP BY status
ORDER BY toplam_ciro DESC;

-- Toplam ciro
SELECT 'TOPLAM CIRO (Tamamlandi)' AS metrik,
       TO_CHAR(SUM(quantity * unit_price), 'FM999,999.00') || ' TL' AS deger
FROM clean_orders
WHERE status = 'Tamamlandı';
