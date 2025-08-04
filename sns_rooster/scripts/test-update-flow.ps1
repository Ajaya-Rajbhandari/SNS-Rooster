# Test Update Flow
# This script tests the complete update system with proper version configuration

Write-Host "Testing Complete Update Flow" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""

Write-Host "Current Configuration:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "App Version: 0.9.0+1 (current)" -ForegroundColor Cyan
Write-Host "Backend Latest: 1.0.1+2 (available)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Expected Flow:" -ForegroundColor Yellow
Write-Host "==============" -ForegroundColor Yellow
Write-Host "1. App (v0.9.0) checks for updates" -ForegroundColor White
Write-Host "2. Backend says v1.0.1 is available" -ForegroundColor White
Write-Host "3. Update alert appears" -ForegroundColor White
Write-Host "4. User clicks Update" -ForegroundColor White
Write-Host "5. APK downloads and installs" -ForegroundColor White
Write-Host "6. New app (v1.0.1) checks for updates" -ForegroundColor White
Write-Host "7. Backend says you're up to date" -ForegroundColor White
Write-Host ""

Write-Host "Testing Backend Response:" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow

# Test Android version check
$headers = @{'User-Agent'='SNS-Rooster/0.9.0 (Android)'}
try {
    $response = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers
    Write-Host "✅ Backend Response:" -ForegroundColor Green
    Write-Host "   Current: $($response.current_version)" -ForegroundColor White
    Write-Host "   Latest: $($response.latest_version)" -ForegroundColor White
    Write-Host "   Update Available: $($response.update_available)" -ForegroundColor White
    Write-Host "   Download URL: $($response.download_url)" -ForegroundColor White
} catch {
    Write-Host "❌ Backend test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "===========" -ForegroundColor Yellow
Write-Host "1. Install the v0.9.0 APK on your device" -ForegroundColor Cyan
Write-Host "2. Open the app and check for updates" -ForegroundColor Cyan
Write-Host "3. The update alert should appear" -ForegroundColor Cyan
Write-Host "4. Click Update to test the download" -ForegroundColor Cyan
Write-Host ""

Write-Host "Install Command:" -ForegroundColor Yellow
Write-Host "flutter install --release" -ForegroundColor Gray
Write-Host ""

Write-Host "Ready to test the update flow!" -ForegroundColor Green 