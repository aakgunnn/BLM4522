# stage2_backup_types.ps1
# ============================================================
# AŞAMA 2: Tam, Fark ve Artık Yedekleme Stratejileri
# PostgreSQL'de pg_dump ile farklı yedekleme tipleri
# ============================================================

$PgDump   = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
$PgRestore = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
$DbName   = "dr_demo_db"
$DbUser   = "postgres"
$env:PGPASSWORD = "1806"

$ScriptDir  = $PSScriptRoot
$BackupDir  = Join-Path $ScriptDir "Backups"
$LogFile    = Join-Path $ScriptDir "backup_log.txt"
$DateStr    = Get-Date -Format "yyyyMMdd_HHmmss"

# Klasör yoksa oluştur
if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# ==========================================
# 1. TAM YEDEKLEME (Full Backup)
# Tüm veritabanının eksiksiz yedeği
# ==========================================
Log "=========================================="
Log "1. TAM YEDEKLEME (Full Backup) basliyor..."
Log "=========================================="

$FullBackup = Join-Path $BackupDir "full_backup_$DateStr.backup"
$FullTime = Measure-Command {
    & $PgDump -U $DbUser -d $DbName -F c -f $FullBackup
}
$FullSize = [math]::Round((Get-Item $FullBackup).Length / 1KB, 2)
Log "  Dosya: $($FullBackup | Split-Path -Leaf)"
Log "  Boyut: $FullSize KB | Sure: $([math]::Round($FullTime.TotalSeconds, 2)) sn"

# ==========================================
# 2. ŞEMA YEDEKLEME (Schema-Only / Yapısal Yedek)
# Sadece tablo yapıları, indeksler, kısıtlar
# Fark (Differential) yedeğinin temel bileşeni
# ==========================================
Log ""
Log "=========================================="
Log "2. SEMA YEDEKLEME (Schema-Only) basliyor..."
Log "=========================================="

$SchemaBackup = Join-Path $BackupDir "schema_only_$DateStr.sql"
$SchemaTime = Measure-Command {
    & $PgDump -U $DbUser -d $DbName --schema-only -f $SchemaBackup
}
$SchemaSize = [math]::Round((Get-Item $SchemaBackup).Length / 1KB, 2)
Log "  Dosya: $($SchemaBackup | Split-Path -Leaf)"
Log "  Boyut: $SchemaSize KB | Sure: $([math]::Round($SchemaTime.TotalSeconds, 2)) sn"

# ==========================================
# 3. TABLO BAZLI YEDEKLEME (Artık / Incremental Simülasyonu)
# Sadece belirli tabloların yedeği
# ==========================================
Log ""
Log "=========================================="
Log "3. TABLO BAZLI YEDEKLEME (Incremental) basliyor..."
Log "=========================================="

$tables = @("company.employees", "company.projects", "company.customers")

foreach ($tbl in $tables) {
    $safeName = $tbl -replace '\.', '_'
    $tblBackup = Join-Path $BackupDir "table_${safeName}_$DateStr.backup"
    $tblTime = Measure-Command {
        & $PgDump -U $DbUser -d $DbName -t $tbl -F c -f $tblBackup
    }
    $tblSize = [math]::Round((Get-Item $tblBackup).Length / 1KB, 2)
    Log "  [$tbl] Boyut: $tblSize KB | Sure: $([math]::Round($tblTime.TotalSeconds, 2)) sn"
}

# ==========================================
# 4. SADECE VERİ YEDEĞİ (Data-Only)
# Yapı hariç sadece veriyi yedekler
# ==========================================
Log ""
Log "=========================================="
Log "4. SADECE VERI YEDEGI (Data-Only) basliyor..."
Log "=========================================="

$DataBackup = Join-Path $BackupDir "data_only_$DateStr.sql"
$DataTime = Measure-Command {
    & $PgDump -U $DbUser -d $DbName --data-only -f $DataBackup
}
$DataSize = [math]::Round((Get-Item $DataBackup).Length / 1KB, 2)
Log "  Dosya: $($DataBackup | Split-Path -Leaf)"
Log "  Boyut: $DataSize KB | Sure: $([math]::Round($DataTime.TotalSeconds, 2)) sn"

# ==========================================
# 5. YEDEKLEME BOYUT KARŞILAŞTIRMA TABLOSU
# ==========================================
Log ""
Log "=========================================="
Log "YEDEKLEME KARSILASTIRMA OZETI"
Log "=========================================="
Log "  Tam Yedek (Full)     : $FullSize KB"
Log "  Sema Yedek (Schema)  : $SchemaSize KB"
Log "  Veri Yedek (Data)    : $DataSize KB"
Log "  Toplam Tablo Bazli   : $(($tables | ForEach-Object { $safeName = $_ -replace '\.','_'; (Get-Item (Join-Path $BackupDir "table_${safeName}_$DateStr.backup")).Length }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum | ForEach-Object { [math]::Round($_ / 1KB, 2) }) KB"
Log ""
Log "Tum yedeklemeler basariyla tamamlandi!"

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
