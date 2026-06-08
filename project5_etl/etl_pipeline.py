# etl_pipeline.py
# ============================================================
# Proje 5: Veri Temizleme ve ETL Süreçleri Tasarımı
# Extract -> Transform -> Load Pipeline (PostgreSQL + Python)
# ============================================================

import csv
import re
import os
import psycopg2
from datetime import datetime

# ==================== KONFIGÜRASYON ====================
DB_CONFIG = {
    "dbname": "etl_demo_db",
    "user": "postgres",
    "password": "1806",
    "host": "localhost"
}
PG_DUMP_PATH = r"C:\Program Files\PostgreSQL\18\bin"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPORT_FILE = os.path.join(SCRIPT_DIR, "veri_kalitesi_raporu.txt")

# ==================== YARDIMCI FONKSİYONLAR ====================

def log_report(message):
    """Hem ekrana yazar hem rapor dosyasına ekler."""
    print(message)
    with open(REPORT_FILE, "a", encoding="utf-8") as f:
        f.write(message + "\n")

def connect_db():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        return conn
    except Exception as e:
        log_report(f"[HATA] Veritabanına bağlanılamadı: {e}")
        return None

def validate_email(email):
    """Basit email doğrulaması."""
    if not email:
        return False
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))

def normalize_phone(phone):
    """Telefon numarasını +90 5XX XXX XXXX formatına standartlaştırır."""
    if not phone:
        return None
    digits = re.sub(r'\D', '', phone)
    if digits.startswith('90') and len(digits) == 12:
        return f"+{digits[:2]} {digits[2:5]} {digits[5:8]} {digits[8:]}"
    elif digits.startswith('0') and len(digits) == 11:
        return f"+90 {digits[1:4]} {digits[4:7]} {digits[7:]}"
    elif len(digits) == 10:
        return f"+90 {digits[:3]} {digits[3:6]} {digits[6:]}"
    return None  # Geçersiz format

def normalize_date(date_str):
    """Farklı tarih formatlarını YYYY-MM-DD'ye çevirir."""
    if not date_str:
        return None
    formats = ['%Y-%m-%d', '%d/%m/%Y', '%Y/%m/%d']
    for fmt in formats:
        try:
            return datetime.strptime(date_str.strip(), fmt).strftime('%Y-%m-%d')
        except ValueError:
            continue
    return None  # Geçersiz tarih

def normalize_city(city):
    """Şehir adını standartlaştırır (İlk Harf Büyük)."""
    if not city:
        return None
    return city.strip().title()

def normalize_status(status):
    """Sipariş durumunu standartlaştırır."""
    if not status:
        return None
    mapping = {
        'tamamlandi': 'Tamamlandı',
        'beklemede': 'Beklemede',
        'iptal': 'İptal'
    }
    return mapping.get(status.strip().lower(), status.strip())

# ==================== 1. EXTRACT (Veri Çıkarma) ====================

def extract_csv(filepath):
    """CSV dosyasını okuyarak ham veri listesi döndürür."""
    log_report(f"\n{'='*60}")
    log_report(f"[EXTRACT] Dosya okunuyor: {os.path.basename(filepath)}")
    log_report(f"{'='*60}")
    
    data = []
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Tüm değerlerdeki başındaki/sonundaki boşlukları temizle
            cleaned_row = {k: v.strip() if v else '' for k, v in row.items()}
            data.append(cleaned_row)
    
    log_report(f"  -> Toplam {len(data)} satır okundu.")
    return data

# ==================== 2. TRANSFORM (Veri Dönüştürme) ====================

def transform_customers(raw_data):
    """Müşteri verisini temizler ve standartlaştırır."""
    log_report(f"\n{'='*60}")
    log_report("[TRANSFORM] Müşteri verisi dönüştürülüyor...")
    log_report(f"{'='*60}")
    
    cleaned = []
    issues = {
        "eksik_isim": 0,
        "gecersiz_email": 0,
        "gecersiz_telefon": 0,
        "gecersiz_tarih": 0,
        "negatif_tutar": 0,
        "null_tutar": 0,
        "duplicate": 0,
        "bosluk_temizleme": 0
    }
    
    seen_emails = set()
    
    for row in raw_data:
        # --- İsim Kontrolü ---
        name = row.get('full_name', '').strip()
        if not name:
            issues["eksik_isim"] += 1
            log_report(f"  [!] Satir {row['id']}: İsim boş -> Satır atlandı.")
            continue
        
        # Fazla boşlukları temizle
        if name != row.get('full_name', ''):
            issues["bosluk_temizleme"] += 1
            log_report(f"  [~] Satir {row['id']}: İsimdeki fazla boşluklar temizlendi: '{row['full_name']}' -> '{name}'")
        
        # --- Email Kontrolü ---
        email = row.get('email', '').strip().lower()
        if not validate_email(email):
            issues["gecersiz_email"] += 1
            log_report(f"  [!] Satir {row['id']}: Geçersiz email formatı: '{row.get('email', '')}' -> Satır atlandı.")
            continue
        
        # --- Duplicate (Tekrar) Kontrolü ---
        if email in seen_emails:
            issues["duplicate"] += 1
            log_report(f"  [!] Satir {row['id']}: Tekrarlanan kayıt (email: {email}) -> Atlandı.")
            continue
        seen_emails.add(email)
        
        # --- Telefon Standardizasyonu ---
        phone = normalize_phone(row.get('phone', ''))
        if not phone and row.get('phone', ''):
            issues["gecersiz_telefon"] += 1
            log_report(f"  [~] Satir {row['id']}: Telefon formatı düzeltilemedi: '{row.get('phone', '')}'")
        
        # --- Tarih Standardizasyonu ---
        reg_date = normalize_date(row.get('registration_date', ''))
        if not reg_date:
            issues["gecersiz_tarih"] += 1
            log_report(f"  [~] Satir {row['id']}: Tarih formatı düzeltilemedi: '{row.get('registration_date', '')}'")
        
        # --- Şehir Standardizasyonu ---
        city = normalize_city(row.get('city', ''))
        
        # --- Tutar Kontrolü ---
        total_spent = row.get('total_spent', '')
        if total_spent.upper() == 'NULL' or total_spent == '':
            issues["null_tutar"] += 1
            total_spent_val = 0.0
            log_report(f"  [~] Satir {row['id']}: Boş/NULL tutar -> 0.00 olarak atandı.")
        else:
            try:
                total_spent_val = float(total_spent)
                if total_spent_val < 0:
                    issues["negatif_tutar"] += 1
                    log_report(f"  [!] Satir {row['id']}: Negatif tutar ({total_spent_val}) -> 0.00 olarak düzeltildi.")
                    total_spent_val = 0.0
            except ValueError:
                total_spent_val = 0.0
        
        cleaned.append({
            "full_name": name,
            "email": email,
            "phone": phone,
            "city": city,
            "registration_date": reg_date,
            "total_spent": total_spent_val
        })
    
    # Özet Rapor
    log_report(f"\n  --- MÜŞTERİ VERİ KALİTESİ ÖZETİ ---")
    log_report(f"  Ham veri satır sayısı  : {len(raw_data)}")
    log_report(f"  Temiz veri satır sayısı: {len(cleaned)}")
    log_report(f"  Eksik isim (atlandı)   : {issues['eksik_isim']}")
    log_report(f"  Geçersiz email (atlandı): {issues['gecersiz_email']}")
    log_report(f"  Tekrarlanan kayıt       : {issues['duplicate']}")
    log_report(f"  Geçersiz telefon        : {issues['gecersiz_telefon']}")
    log_report(f"  Geçersiz tarih          : {issues['gecersiz_tarih']}")
    log_report(f"  Negatif tutar düzeltme  : {issues['negatif_tutar']}")
    log_report(f"  NULL tutar düzeltme     : {issues['null_tutar']}")
    log_report(f"  Boşluk temizleme        : {issues['bosluk_temizleme']}")
    
    return cleaned

def transform_orders(raw_data, valid_customer_ids):
    """Sipariş verisini temizler ve standartlaştırır."""
    log_report(f"\n{'='*60}")
    log_report("[TRANSFORM] Sipariş verisi dönüştürülüyor...")
    log_report(f"{'='*60}")
    
    cleaned = []
    issues = {
        "gecersiz_musteri": 0,
        "gecersiz_miktar": 0,
        "eksik_fiyat": 0,
        "gecersiz_tarih": 0,
        "duplicate": 0,
        "durum_standart": 0
    }
    
    seen_orders = set()
    
    for row in raw_data:
        order_id = row.get('order_id', '')
        
        # --- Duplicate Kontrolü ---
        order_key = f"{row.get('customer_id', '')}_{row.get('product', '')}_{row.get('order_date', '')}"
        if order_key in seen_orders:
            issues["duplicate"] += 1
            log_report(f"  [!] Sipariş {order_id}: Tekrarlanan sipariş -> Atlandı.")
            continue
        seen_orders.add(order_key)
        
        # --- Müşteri ID Kontrolü ---
        try:
            cust_id = int(row.get('customer_id', 0))
        except ValueError:
            cust_id = 0
        
        if cust_id not in valid_customer_ids:
            issues["gecersiz_musteri"] += 1
            log_report(f"  [!] Sipariş {order_id}: Geçersiz müşteri ID ({cust_id}) -> Atlandı.")
            continue
        
        # --- Miktar Kontrolü ---
        try:
            quantity = int(row.get('quantity', 0))
            if quantity <= 0:
                issues["gecersiz_miktar"] += 1
                log_report(f"  [!] Sipariş {order_id}: Geçersiz miktar ({quantity}) -> Atlandı.")
                continue
        except ValueError:
            issues["gecersiz_miktar"] += 1
            log_report(f"  [!] Sipariş {order_id}: Sayısal olmayan miktar ('{row.get('quantity', '')}') -> Atlandı.")
            continue
        
        # --- Fiyat Kontrolü ---
        unit_price = row.get('unit_price', '')
        if not unit_price:
            issues["eksik_fiyat"] += 1
            log_report(f"  [~] Sipariş {order_id}: Fiyat bilgisi eksik -> 0.00 atandı.")
            unit_price_val = 0.0
        else:
            unit_price_val = float(unit_price)
        
        # --- Tarih Standardizasyonu ---
        order_date = normalize_date(row.get('order_date', ''))
        if not order_date:
            issues["gecersiz_tarih"] += 1
            log_report(f"  [~] Sipariş {order_id}: Tarih formatı düzeltilemedi: '{row.get('order_date', '')}'")
        
        # --- Durum Standardizasyonu ---
        original_status = row.get('status', '')
        status = normalize_status(original_status)
        if status != original_status:
            issues["durum_standart"] += 1
        
        cleaned.append({
            "order_id": int(order_id),
            "customer_id": cust_id,
            "product": row.get('product', '').strip(),
            "quantity": quantity,
            "unit_price": unit_price_val,
            "order_date": order_date,
            "status": status
        })
    
    log_report(f"\n  --- SİPARİŞ VERİ KALİTESİ ÖZETİ ---")
    log_report(f"  Ham veri satır sayısı  : {len(raw_data)}")
    log_report(f"  Temiz veri satır sayısı: {len(cleaned)}")
    log_report(f"  Geçersiz müşteri ID    : {issues['gecersiz_musteri']}")
    log_report(f"  Geçersiz miktar         : {issues['gecersiz_miktar']}")
    log_report(f"  Eksik fiyat             : {issues['eksik_fiyat']}")
    log_report(f"  Geçersiz tarih          : {issues['gecersiz_tarih']}")
    log_report(f"  Tekrarlanan sipariş     : {issues['duplicate']}")
    log_report(f"  Durum standartlaştırma  : {issues['durum_standart']}")
    
    return cleaned

# ==================== 3. LOAD (Veri Yükleme) ====================

def create_target_tables(conn):
    """Hedef veritabanında temiz tabloları oluşturur."""
    log_report(f"\n{'='*60}")
    log_report("[LOAD] Hedef tablolar oluşturuluyor...")
    log_report(f"{'='*60}")
    
    cur = conn.cursor()
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS clean_customers (
            customer_id SERIAL PRIMARY KEY,
            full_name VARCHAR(100) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            phone VARCHAR(20),
            city VARCHAR(50),
            registration_date DATE,
            total_spent NUMERIC(12,2) DEFAULT 0.00
        );
    """)
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS clean_orders (
            order_id INTEGER PRIMARY KEY,
            customer_id INTEGER REFERENCES clean_customers(customer_id),
            product VARCHAR(100),
            quantity INTEGER CHECK (quantity > 0),
            unit_price NUMERIC(12,2),
            order_date DATE,
            status VARCHAR(20)
        );
    """)
    
    # Önceki verileri temizle (tekrar çalıştırma durumunda)
    cur.execute("TRUNCATE TABLE clean_orders CASCADE;")
    cur.execute("TRUNCATE TABLE clean_customers CASCADE;")
    
    log_report("  -> Tablolar başarıyla oluşturuldu / temizlendi.")

def load_customers(conn, data):
    """Temizlenmiş müşteri verisini veritabanına yükler."""
    cur = conn.cursor()
    loaded = 0
    
    for row in data:
        try:
            cur.execute("""
                INSERT INTO clean_customers (full_name, email, phone, city, registration_date, total_spent)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING customer_id;
            """, (
                row['full_name'], row['email'], row['phone'],
                row['city'], row['registration_date'], row['total_spent']
            ))
            row['customer_id'] = cur.fetchone()[0]
            loaded += 1
        except Exception as e:
            log_report(f"  [HATA] Müşteri yüklenemedi ({row['email']}): {e}")
    
    log_report(f"  -> {loaded}/{len(data)} müşteri kaydı yüklendi.")
    return data

def load_orders(conn, orders_data, customers_data):
    """Temizlenmiş sipariş verisini veritabanına yükler."""
    cur = conn.cursor()
    loaded = 0
    
    # Eski CSV customer_id -> yeni DB customer_id eşleştirmesi
    # CSV'deki id sırasıyla DB'deki customer_id'yi eşleştiriyoruz
    id_map = {}
    for i, c in enumerate(customers_data):
        id_map[i + 1] = c.get('customer_id', i + 1)
    
    for row in orders_data:
        new_cust_id = id_map.get(row['customer_id'])
        if not new_cust_id:
            continue
        try:
            cur.execute("""
                INSERT INTO clean_orders (order_id, customer_id, product, quantity, unit_price, order_date, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s);
            """, (
                row['order_id'], new_cust_id, row['product'],
                row['quantity'], row['unit_price'], row['order_date'], row['status']
            ))
            loaded += 1
        except Exception as e:
            log_report(f"  [HATA] Sipariş yüklenemedi (ID: {row['order_id']}): {e}")
    
    log_report(f"  -> {loaded}/{len(orders_data)} sipariş kaydı yüklendi.")

# ==================== 4. DOĞRULAMA ====================

def verify_loaded_data(conn):
    """Yüklenen verileri doğrulama sorguları çalıştırır."""
    log_report(f"\n{'='*60}")
    log_report("[DOĞRULAMA] Yüklenen veriler kontrol ediliyor...")
    log_report(f"{'='*60}")
    
    cur = conn.cursor()
    
    cur.execute("SELECT COUNT(*) FROM clean_customers;")
    cust_count = cur.fetchone()[0]
    
    cur.execute("SELECT COUNT(*) FROM clean_orders;")
    order_count = cur.fetchone()[0]
    
    cur.execute("SELECT city, COUNT(*) FROM clean_customers GROUP BY city ORDER BY COUNT(*) DESC;")
    city_dist = cur.fetchall()
    
    cur.execute("SELECT SUM(quantity * unit_price) FROM clean_orders WHERE status = 'Tamamlandı';")
    total_revenue = cur.fetchone()[0] or 0
    
    log_report(f"\n  Toplam müşteri : {cust_count}")
    log_report(f"  Toplam sipariş : {order_count}")
    log_report(f"  Toplam ciro (Tamamlandı): {total_revenue:,.2f} TL")
    log_report(f"\n  Şehir Dağılımı:")
    for city, count in city_dist:
        log_report(f"    {city}: {count} müşteri")

# ==================== ANA PIPELINE ====================

def main():
    # Rapor dosyasını sıfırla
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        f.write(f"{'='*60}\n")
        f.write(f"  VERİ KALİTESİ RAPORU\n")
        f.write(f"  Tarih: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"{'='*60}\n")
    
    # 1. EXTRACT
    raw_customers = extract_csv(os.path.join(SCRIPT_DIR, "raw_data_customers.csv"))
    raw_orders = extract_csv(os.path.join(SCRIPT_DIR, "raw_data_orders.csv"))
    
    # 2. TRANSFORM
    clean_customers = transform_customers(raw_customers)
    
    # Geçerli müşteri ID listesi (CSV'deki orijinal id'ler, temiz kayıtlar bazında)
    valid_ids = set()
    for c in clean_customers:
        # Email bazında orijinal id'yi bul
        for raw in raw_customers:
            if raw.get('email', '').strip().lower() == c['email']:
                valid_ids.add(int(raw['id']))
                break
    
    clean_orders = transform_orders(raw_orders, valid_ids)
    
    # 3. LOAD
    conn = connect_db()
    if not conn:
        return
    
    create_target_tables(conn)
    loaded_customers = load_customers(conn, clean_customers)
    load_orders(conn, clean_orders, loaded_customers)
    
    # 4. DOĞRULAMA
    verify_loaded_data(conn)
    
    conn.close()
    
    log_report(f"\n{'='*60}")
    log_report("[TAMAMLANDI] ETL Pipeline başarıyla tamamlandı!")
    log_report(f"Rapor dosyası: {REPORT_FILE}")
    log_report(f"{'='*60}")

if __name__ == "__main__":
    main()
