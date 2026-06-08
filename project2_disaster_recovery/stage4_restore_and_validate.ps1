# stage4_restore_and_validate.ps1
# ============================================================
# AŞAMA 4: Yedekten Kurtarma ve Doğrulama
# Felaketten sonra verileri geri yükleme + backup test
# ============================================================

$PgDump    = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
$PgRestore = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
$Psql      = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$DbName    = "dr_demo_db"
$DbUser    = "postgres"
$env:PGPASSWORD = "1806"

$ScriptDir = $PSScriptRoot
$BackupDir = Join-Path $ScriptDir "Backups"
$LogFile   = Join-Path $ScriptDir "restore_log.txt"

function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# ==========================================
# 1. YEDEK DOĞRULAMA (Backup Validation)
# Yedeğin bozuk olmadığını kontrol et
# ==========================================
Log "=========================================="
Log "1. YEDEK DOGRULAMA (Backup Validation)"
Log "=========================================="

# En son full backup dosyasını bul
$FullBackup = Get-ChildItem -Path $BackupDir -Filter "full_backup_*.backup" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $FullBackup) {
    Log "[HATA] Full backup dosyasi bulunamadi! Once stage2_backup_types.ps1 calistirilmali."
    exit 1
}

Log "  Dogrulanan dosya: $($FullBackup.Name)"

# pg_restore --list ile yedeğin içeriğini listele (bozuksa hata verir)
$ListOutput = & $PgRestore --list $FullBackup.FullName 2>&1
if ($LASTEXITCODE -eq 0) {
    $tableCount = ($ListOutput | Select-String "TABLE DATA").Count
    Log "  [BASARILI] Yedek dosyasi gecerli ve okunabilir."
    Log "  Yedekte bulunan tablo verisi sayisi: $tableCount"
} else {
    Log "  [HATA] Yedek dosyasi bozuk veya okunamiyor!"
    Log "  Detay: $ListOutput"
}

# ==========================================
# 2. FELAKETTEN KURTARMA: Tam Yedekten Geri Yükleme
# ==========================================
Log ""
Log "=========================================="
Log "2. FELAKETTEN KURTARMA: Full Restore"
Log "=========================================="

Log "  Mevcut veritabani siliniyor ve yedekten geri yukleniyor..."

# Veritabanını sil ve yeniden oluştur
& $Psql -U $DbUser -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DbName' AND pid <> pg_backend_pid();" 2>$null
& $Psql -U $DbUser -c "DROP DATABASE IF EXISTS $DbName;"
& $Psql -U $DbUser -c "CREATE DATABASE $DbName;"

# Full backup'tan geri yükle
$RestoreTime = Measure-Command {
    & $PgRestore -U $DbUser -d $DbName --no-owner --no-privileges $FullBackup.FullName 2>$null
}

Log "  Geri yukleme suresi: $([math]::Round($RestoreTime.TotalSeconds, 2)) sn"

# ==========================================
# 3. KURTARMA SONRASI DOĞRULAMA
# ==========================================
Log ""
Log "=========================================="
Log "3. KURTARMA SONRASI DOGRULAMA"
Log "=========================================="

# Tablo sayılarını kontrol et
$VerifyResult = & $Psql -U $DbUser -d $DbName -t -c "
SELECT 'employees: ' || COUNT(*) FROM company.employees
UNION ALL SELECT 'projects: ' || COUNT(*) FROM company.projects
UNION ALL SELECT 'customers: ' || COUNT(*) FROM company.customers;
"

foreach ($line in $VerifyResult) {
    $trimmed = $line.Trim()
    if ($trimmed) { Log "  $trimmed" }
}

# ==========================================
# 4. TABLO BAZLI KURTARMA TESTİ
# (Sadece tek bir tabloyu yedekten geri yükleme)
# ==========================================
Log ""
Log "=========================================="
Log "4. TABLO BAZLI KURTARMA TESTI"
Log "=========================================="

# Önce customers tablosunu kasıtlı olarak sil
& $Psql -U $DbUser -d $DbName -c "DROP TABLE IF EXISTS company.customers CASCADE;" 2>$null
Log "  customers tablosu kasten silindi (DROP)."

# Tablo bazlı yedekten geri yükle
$TblBackup = Get-ChildItem -Path $BackupDir -Filter "table_company_customers_*.backup" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($TblBackup) {
    & $PgRestore -U $DbUser -d $DbName --no-owner --no-privileges $TblBackup.FullName 2>$null
    $CustCount = & $Psql -U $DbUser -d $DbName -t -c "SELECT COUNT(*) FROM company.customers;"
    Log "  customers tablosu tablo bazli yedekten geri yuklendi."
    Log "  Kurtarilan kayit sayisi: $($CustCount.Trim())"
} else {
    Log "  [UYARI] Tablo bazli yedek bulunamadi, full backup'tan yukleniyor..."
    & $PgRestore -U $DbUser -d $DbName --no-owner --no-privileges -t customers $FullBackup.FullName 2>$null
}

# ==========================================
# 5. SONUÇ RAPORU
# ==========================================
Log ""
Log "=========================================="
Log "KURTARMA ISLEMLERI TAMAMLANDI"
Log "=========================================="

$FinalResult = & $Psql -U $DbUser -d $DbName -t -c "
SELECT 'employees: ' || COUNT(*) FROM company.employees
UNION ALL SELECT 'projects: ' || COUNT(*) FROM company.projects
UNION ALL SELECT 'customers: ' || COUNT(*) FROM company.customers;
"

Log "  NIHAI TABLO DURUMLARI:"
foreach ($line in $FinalResult) {
    $trimmed = $line.Trim()
    if ($trimmed) { Log "    $trimmed" }
}

Log ""
Log "Tum felaket kurtarma ve dogrulama islemleri basariyla tamamlandi!"

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
