# sqli_demo.py
# Aşama 5: SQL Injection Testleri ve Korunma Mekanizmaları

import psycopg2

def connect_db():
    try:
        # app_user ile bağlanıyoruz (Sadece SELECT yetkisi var)
        conn = psycopg2.connect(
            dbname="security_demo_db",
            user="app_user",
            password="AppUser123!",
            host="localhost"
        )
        return conn
    except Exception as e:
        print(f"Bağlantı Hatası: {e}")
        return None

def insecure_search(username):
    print(f"\n[!] INSECURE (Zafiyetli) Arama: {username}")
    conn = connect_db()
    if not conn: return
    cur = conn.cursor()
    
    # KÖTÜ PRATİK: String birleştirme
    query = f"SELECT user_id, username FROM company.users WHERE username = '{username}';"
    print(f"Çalıştırılan Sorgu: {query}")
    
    try:
        cur.execute(query)
        results = cur.fetchall()
        for row in results:
            print(f" > Bulunan Kullanıcı: {row}")
    except Exception as e:
        print(f" Hata: {e}")
    finally:
        cur.close()
        conn.close()

def secure_search(username):
    print(f"\n[+] SECURE (Güvenli) Arama: {username}")
    conn = connect_db()
    if not conn: return
    cur = conn.cursor()
    
    # İYİ PRATİK: Parametrik Sorgular (Psycopg2 prepared statements mantığını kullanır)
    query = "SELECT user_id, username FROM company.users WHERE username = %s;"
    print(f"Çalıştırılan Sorgu: {query} | Parametre: {username}")
    
    try:
        cur.execute(query, (username,))
        results = cur.fetchall()
        if not results:
            print(" > Sonuç bulunamadı (Zararlı girdi literal string olarak algılandı).")
        for row in results:
            print(f" > Bulunan Kullanıcı: {row}")
    except Exception as e:
        print(f" Hata: {e}")
    finally:
        cur.close()
        conn.close()


def demonstrate_least_privilege(malicious_input):
    print(f"\n[*] LEAST PRIVILEGE TESTİ (Hasar Kontrolü)")
    print(f"Injection Denemesi: {malicious_input}")
    conn = connect_db()
    if not conn: return
    cur = conn.cursor()
    
    # Kötü yazılmış bir kod düşünelim
    query = f"SELECT user_id, username FROM company.users WHERE username = '{malicious_input}';"
    print("Saldırgan tabloyu silmeyi (DROP) deniyor...")
    
    try:
        # commit() ile DROP TABLE vs kalıcı olmasını simüle edelim.
        cur.execute(query)
        conn.commit()
    except Exception as e:
        print(f"\n>>> VERİTABANI GÜVENLİĞİ DEVREDE! (Yetki Reddedildi) <<<")
        print(f"PostgreSQL Hatası: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    print("--------------------------------------------------")
    print("1. Standart (Normal) Kullanım:")
    insecure_search("ahmet_it")
    
    print("\n--------------------------------------------------")
    print("2. SQL Injection Saldırısı (Tüm Verileri Çekme):")
    # ' OR '1'='1 true döndüreceği için filtre by-pass edilir.
    insecure_search("ahmet_it' OR '1'='1")
    
    print("\n--------------------------------------------------")
    print("3. Korumalı (Parametrik) Sorgu Testi:")
    secure_search("ahmet_it' OR '1'='1")

    print("\n--------------------------------------------------")
    print("4. Least Privilege (En Az Yetki) Prensibi Testi:")
    # İkinci satır olarak "DROP TABLE" gönderilir
    demonstrate_least_privilege("x'; DROP TABLE company.users; --")

    print("\n--------------------------------------------------")
    print("Testler Tamamlandı.")
