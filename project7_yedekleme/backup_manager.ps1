# backup_manager.ps1

$DbName = "yedek_demo_db"
$DbUser = "postgres"
$Password = "1806"
$PgDumpPath = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"

$ScriptDir = $PSScriptRoot
$BackupDir = Join-Path $ScriptDir "Backups"
$LogDir = Join-Path $ScriptDir "Logs"

$DateStr = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "backup_$DateStr.backup"
$LogFile = Join-Path $LogDir "backup_audit_log.txt"

# pg_dump komutu PGPASSWORD çevre değişkenini (Environment Variable) otomatik tanır
$env:PGPASSWORD = $Password

# Sahte (Usulen) Mail Atma Fonksiyonu
function Send-MockEmail {
    param ($Subject, $Body)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MailText = "[EMAIL SIMULATION][$Timestamp] TO: dbadmin@company.com | SUBJECT: $Subject | BODY: $Body"
    
    # Gerçekte mail atmıyoruz, ancak sanki atılmış gibi logluyoruz
    Add-Content -Path $LogFile -Value $MailText
    Write-Host $MailText -ForegroundColor Yellow
}

try {
    Write-Host "Yedekleme basliyor ($DbName) -> Hedef: $BackupFile" -ForegroundColor Cyan
    
    # Yedekleme süresini ölçmek için Measure-Command
    $TimeTaken = Measure-Command {
        # -F c: Custom compression format
        $ps = Start-Process -FilePath $PgDumpPath -ArgumentList "-U $DbUser -d $DbName -F c -f `"$BackupFile`"" -Wait -NoNewWindow -PassThru
        
        if ($ps.ExitCode -ne 0) {
            throw "pg_dump işlemi Exit Code $($ps.ExitCode) ile çöktü."
        }
    }
    
    # Yedek alınan dosyanın büyüklüğünü hesaplama
    $FileInfo = Get-Item $BackupFile
    $SizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
    $Duration = [math]::Round($TimeTaken.TotalSeconds, 2)

    # Başarılı Durumu Raporlama / Loglama
    $StatusOk = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [SUCCESS] DB: $DbName | ZAMAN: $Duration sn | BOYUT: $SizeMB MB | DOSYA: $($FileInfo.Name)"
    Add-Content -Path $LogFile -Value $StatusOk
    Write-Host $StatusOk -ForegroundColor Green

} catch {
    # Başarısız Durumu Raporlama / Loglama
    $StatusFail = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [ERROR] DB: $DbName | DETAY: $_"
    Add-Content -Path $LogFile -Value $StatusFail
    Write-Host $StatusFail -ForegroundColor Red
    
    # Otomatik Mail Gönderimini Tetikleme
    Send-MockEmail -Subject "[CRITICAL] Yedekleme Basarisiz ($DbName)!" -Body "Veritabani yedeklemesi tamamlanamadi. Lutfen sunucudaki loglari inceleyin."
    
} finally {
    # İşlem bittikten sonra güvenlik gereği password'ü environment'tan temizliyoruz.
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}
