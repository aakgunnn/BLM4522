-- stage3_encryption.sql
-- Aşama 3: Veri Şifreleme (TDE / Sütun Bazlı Kriptolama)
-- PostgreSQL'de Transparent Data Encryption (TDE) yerleşik olarak bulunmaz. 
-- Ancak disk şifreleme veya pgcrypto eklentisiyle veri tabanı/sütun düzeyinde kriptolama çözümleri yaygındır.

-- 1. pgcrypto eklentisinin aktifleştirilmesi
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Mevcut açık (Düz Metin) veriyi şifreleyerek sütun tipini bytea (binary) formatına çevirme.
-- "SüperGizliAnahtar_123" ifadesi bizim Master Key / Encryption Password'umuz olacak.
ALTER TABLE company.financial_records
    ALTER COLUMN credit_card_info TYPE bytea 
    USING pgp_sym_encrypt(credit_card_info, 'SüperGizliAnahtar_123');

-- 3. Rollerin pgcrypto fonksiyonlarını kullanabilmesi için yetkilendirilmesi
-- (Adminler veya yetkili db_admin encrypt/decrypt yapabilir)
GRANT EXECUTE ON FUNCTION pgp_sym_encrypt(text, text) TO admin_role;
GRANT EXECUTE ON FUNCTION pgp_sym_decrypt(bytea, text) TO admin_role;

-- 4. Uygulamanın/Admin'in veriyi şifreli eklemesi örneği:
INSERT INTO company.financial_records (transaction_title, amount, credit_card_info) 
VALUES ('Yeni Donanım Alımı', 8500.00, pgp_sym_encrypt('1111-2222-3333-4444', 'SüperGizliAnahtar_123'));
