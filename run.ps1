# Medliva local launcher: starts the API and the Flutter web app, then opens the browser.
# Usage: .\run.ps1   (or double-click run.bat)

$root = $PSScriptRoot
$apiDir = Join-Path $root "services\api"
$mobileDir = Join-Path $root "apps\mobile"

Write-Host "Starting Medliva API on http://localhost:8000 ..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$apiDir'; `$host.UI.RawUI.WindowTitle='Medliva API'; uv run uvicorn app.main:app --reload --port 8000"

Write-Host "Starting Medliva app on http://localhost:5000 ..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$mobileDir'; `$host.UI.RawUI.WindowTitle='Medliva App'; flutter run -d web-server --web-port 5000 --web-hostname localhost --dart-define=API_BASE_URL=http://localhost:8000/api/v1"

Write-Host "Waiting for the app to be ready (first build can take a few minutes) ..." -ForegroundColor Yellow
for ($i = 0; $i -lt 300; $i++) {
    try {
        Invoke-WebRequest "http://localhost:5000" -UseBasicParsing -TimeoutSec 2 | Out-Null
        break
    } catch { Start-Sleep -Seconds 2 }
}

Start-Process "http://localhost:5000"
Write-Host "Opened http://localhost:5000  |  API docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "To stop: close the 'Medliva API' and 'Medliva App' windows."
