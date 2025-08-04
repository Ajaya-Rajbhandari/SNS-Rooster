# Test Update Alert System
# This script tests the update alert system in the Flutter app

Write-Host "Testing Update Alert System" -ForegroundColor Green
Write-Host ""

$baseUrl = "https://sns-rooster.onrender.com"

Write-Host "Step 1: Checking Current Version Info..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/app/version/check" -Method GET
    Write-Host "Current Version: $($response.current_version)" -ForegroundColor Cyan
    Write-Host "Latest Version: $($response.latest_version)" -ForegroundColor Cyan
    Write-Host "Update Available: $($response.update_available)" -ForegroundColor Cyan
    Write-Host "Update Required: $($response.update_required)" -ForegroundColor Cyan
} catch {
    Write-Host "Error checking version: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 2: Testing Update Alert System..." -ForegroundColor Yellow
Write-Host ""
Write-Host "To test the update alert system:" -ForegroundColor White
Write-Host ""
Write-Host "1. Open the Flutter app in your browser (should be running on http://localhost:3000)" -ForegroundColor Cyan
Write-Host "2. Open browser developer tools (F12)" -ForegroundColor Cyan
Write-Host "3. Check the Console tab for update service logs" -ForegroundColor Cyan
Write-Host "4. Look for messages like:" -ForegroundColor White
Write-Host "   - 'Checking for app updates...'" -ForegroundColor Gray
Write-Host "   - 'Update check completed'" -ForegroundColor Gray
Write-Host "   - 'No update available'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. The app should check for updates 3 seconds after startup" -ForegroundColor White
Write-Host "6. If versions match, no alert should appear" -ForegroundColor White
Write-Host ""

Write-Host "Step 3: Simulating Update Scenario..." -ForegroundColor Yellow
Write-Host ""
Write-Host "To simulate an update scenario, you can:" -ForegroundColor White
Write-Host ""
Write-Host "Option A: Modify the backend version (requires backend access)" -ForegroundColor Cyan
Write-Host "Option B: Test with a different version in the app" -ForegroundColor Cyan
Write-Host "Option C: Check the update service logs for functionality" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 4: Manual Testing Steps..." -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start the Flutter app:" -ForegroundColor Cyan
Write-Host "   flutter run -d chrome --web-port=3000" -ForegroundColor White
Write-Host ""
Write-Host "2. Open browser developer tools (F12)" -ForegroundColor Cyan
Write-Host "3. Go to Console tab" -ForegroundColor Cyan
Write-Host "4. Refresh the page" -ForegroundColor Cyan
Write-Host "5. Look for update service logs" -ForegroundColor Cyan
Write-Host "6. Check if update check is triggered" -ForegroundColor Cyan
Write-Host ""

Write-Host "Expected Console Logs:" -ForegroundColor Yellow
Write-Host "- 'Starting SNS Rooster application'" -ForegroundColor Gray
Write-Host "- 'Checking for app updates...'" -ForegroundColor Gray
Write-Host "- 'Update check completed'" -ForegroundColor Gray
Write-Host "- 'No update available' or 'Update available'" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 5: Testing Direct Download System..." -ForegroundColor Yellow
Write-Host ""
Write-Host "To test the direct download system:" -ForegroundColor White
Write-Host ""
Write-Host "1. Build an APK:" -ForegroundColor Cyan
Write-Host "   flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "2. Upload APK to backend:" -ForegroundColor Cyan
Write-Host "   - Copy APK to rooster-backend/uploads/apk/sns-rooster.apk" -ForegroundColor White
Write-Host "   - Update download URL in backend" -ForegroundColor White
Write-Host "   - Deploy backend changes" -ForegroundColor White
Write-Host ""
Write-Host "3. Test download endpoints:" -ForegroundColor Cyan
Write-Host "   ./scripts/test-direct-download.ps1" -ForegroundColor White
Write-Host ""

Write-Host "Ready for testing!" -ForegroundColor Green
Write-Host "Check the browser console for update service activity." -ForegroundColor Cyan 