# Medliva local launcher: starts the API and the Flutter web app, then opens the browser.
# Usage: .\run.ps1   (or double-click run.bat)
# This script is for local development only. It reads Supabase settings
# from infra/.env (copy infra/.env.example to infra/.env first) and
# forwards them to the Flutter app, so the web app never silently falls
# back to a different Supabase project than the API.

$root = $PSScriptRoot
$apiDir = Join-Path $root "services\api"
$mobileDir = Join-Path $root "apps\mobile"
$envFile = Join-Path $root "infra\.env"

# --- Prerequisites (fail fast instead of opening a dead browser tab) ---
foreach ($cmd in @("uv", "flutter")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "Missing required tool: $cmd. Install it and run this script again." -ForegroundColor Red
        exit 1
    }
}
if (-not (Test-Path $envFile)) {
    Write-Host "Missing infra\.env. Copy infra\.env.example to infra\.env and fill in your own values first." -ForegroundColor Red
    exit 1
}

# --- Read infra/.env (KEY=VALUE lines; comments and blank lines ignored) ---
$envVars = @{}
foreach ($line in Get-Content $envFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
    $eq = $trimmed.IndexOf("=")
    if ($eq -gt 0) {
        $envVars[$trimmed.Substring(0, $eq).Trim()] = $trimmed.Substring($eq + 1).Trim()
    }
}
$supabaseUrl = $envVars["SUPABASE_URL"]
$supabaseKey = $envVars["SUPABASE_PUBLISHABLE_KEY"]
if ([string]::IsNullOrWhiteSpace($supabaseKey)) { $supabaseKey = $envVars["SUPABASE_ANON_KEY"] }
if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseKey)) {
    Write-Host "infra\.env is missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. Fill them in and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Starting Medliva API on http://localhost:8000 ..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$apiDir'; `$host.UI.RawUI.WindowTitle='Medliva API'; uv run uvicorn app.main:app --reload --port 8000"

Write-Host "Starting Medliva app on http://localhost:5000 ..." -ForegroundColor Cyan
$dartDefines = "--dart-define=API_BASE_URL=http://localhost:8000/api/v1 --dart-define=SUPABASE_URL=$supabaseUrl --dart-define=SUPABASE_PUBLISHABLE_KEY=$supabaseKey"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$mobileDir'; `$host.UI.RawUI.WindowTitle='Medliva App'; flutter run -d web-server --web-port 5000 --web-hostname localhost $dartDefines"

Write-Host "Waiting for the app to be ready (first build can take a few minutes) ..." -ForegroundColor Yellow
$ready = $false
for ($i = 0; $i -lt 300; $i++) {
    try {
        Invoke-WebRequest "http://localhost:5000" -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ready = $true
        break
    } catch { Start-Sleep -Seconds 2 }
}

if (-not $ready) {
    Write-Host "The app did not become ready at http://localhost:5000. Not opening the browser. Check the 'Medliva API' and 'Medliva App' windows for errors, then close them and try again." -ForegroundColor Red
    exit 1
}

Start-Process "http://localhost:5000"
Write-Host "Opened http://localhost:5000  |  API docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host "To stop: close the 'Medliva API' and 'Medliva App' windows."
Write-Host "Note: on a fresh database, run 'alembic upgrade head' from services\api once before first use."
