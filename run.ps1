# Medliva local launcher: starts the Flutter web app and opens the browser.
# Usage: .\run.ps1   (or double-click run.bat)

$root = $PSScriptRoot
$mobileDir = Join-Path $root "apps\mobile"

Write-Host "Starting Medliva app on http://localhost:5000 ..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$mobileDir'; `$host.UI.RawUI.WindowTitle='Medliva App'; flutter run -d web-server --web-port 5000 --web-hostname localhost"

Write-Host "Waiting for the app to be ready (first build can take a few minutes) ..." -ForegroundColor Yellow
for ($i = 0; $i -lt 300; $i++) {
    try {
        Invoke-WebRequest "http://localhost:5000" -UseBasicParsing -TimeoutSec 2 | Out-Null
        break
    } catch { Start-Sleep -Seconds 2 }
}

Start-Process "http://localhost:5000"
Write-Host "Opened http://localhost:5000. The app connects directly to Supabase." -ForegroundColor Green
Write-Host "To stop: close the 'Medliva App' window."
