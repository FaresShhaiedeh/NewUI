# ========================================
# سكربت تشغيل ngrok - PowerShell
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting ngrok tunnel on port 8000" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ngrokPath = "$env:USERPROFILE\ngrok\ngrok.exe"

if (-not (Test-Path $ngrokPath)) {
    Write-Host "ngrok not found. Downloading..." -ForegroundColor Yellow
    $zip = "$env:TEMP\ngrok.zip"
    Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath "$env:USERPROFILE\ngrok" -Force
    Write-Host "ngrok downloaded to: $env:USERPROFILE\ngrok" -ForegroundColor Green
}

Write-Host "Starting ngrok..." -ForegroundColor Green
Write-Host "After ngrok starts, press Ctrl+C here and run the next command to get the public URL" -ForegroundColor Yellow
Write-Host ""

# إذا كان Windows Defender يحظر ngrok، استخدم هذا الأمر لإلغاء الحظر:
# Add-MpPreference -ExclusionPath "$env:USERPROFILE\ngrok"

& $ngrokPath http 8000
