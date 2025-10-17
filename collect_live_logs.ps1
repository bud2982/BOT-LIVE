# Script per raccogliere i log della sezione Live
# Uso: .\collect_live_logs.ps1

Write-Host "🔍 Raccolta log della sezione Live..." -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Assicurati che:" -ForegroundColor Yellow
Write-Host "  1. Il dispositivo Android sia collegato via USB" -ForegroundColor Yellow
Write-Host "  2. Il debug USB sia abilitato" -ForegroundColor Yellow
Write-Host "  3. L'app sia aperta sulla sezione Live" -ForegroundColor Yellow
Write-Host ""
Write-Host "Premi CTRL+C per fermare la raccolta log" -ForegroundColor Green
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# Verifica che adb sia disponibile
try {
    $adbVersion = adb version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ADB non trovato. Installa Android SDK Platform Tools" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ ADB non trovato. Installa Android SDK Platform Tools" -ForegroundColor Red
    exit 1
}

# Verifica che ci sia un dispositivo collegato
$devices = adb devices | Select-String "device$"
if ($devices.Count -eq 0) {
    Write-Host "❌ Nessun dispositivo Android collegato" -ForegroundColor Red
    Write-Host "   Collega il dispositivo e abilita il debug USB" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Dispositivo collegato" -ForegroundColor Green
Write-Host ""

# Pulisci i log precedenti
adb logcat -c

# Raccogli i log filtrati
Write-Host "📊 Log in tempo reale:" -ForegroundColor Cyan
Write-Host ""

adb logcat | Select-String -Pattern "LiveScore|LiveScreen|HybridFootball" | ForEach-Object {
    $line = $_.Line
    
    # Colora i log in base al contenuto
    if ($line -match "❌|ERRORE|ERROR|Failed|fallito") {
        Write-Host $line -ForegroundColor Red
    } elseif ($line -match "⚠️|WARNING|WARN") {
        Write-Host $line -ForegroundColor Yellow
    } elseif ($line -match "✅|SUCCESS|Trovate|Recuperate") {
        Write-Host $line -ForegroundColor Green
    } elseif ($line -match "🔍|DEBUG|Analisi") {
        Write-Host $line -ForegroundColor Cyan
    } elseif ($line -match "📊|Partita") {
        Write-Host $line -ForegroundColor Magenta
    } else {
        Write-Host $line -ForegroundColor White
    }
}