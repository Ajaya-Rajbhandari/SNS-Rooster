# Check Google Maps APIs Enabled
Write-Host "🔍 Checking Google Maps APIs Status" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Current API Key Settings:" -ForegroundColor Yellow
Write-Host "   ✅ Application Restrictions: None" -ForegroundColor Green
Write-Host "   ✅ API Restrictions: Enabled (30 APIs)" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 ISSUE: Missing Google Maps APIs" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red
Write-Host ""

Write-Host "From your screenshot, I can see Firebase APIs are enabled, but" -ForegroundColor White
Write-Host "the required Google Maps APIs might be missing from the list." -ForegroundColor White
Write-Host ""

Write-Host "🚀 REQUIRED FIX:" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Click on your API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ In API restrictions section, click 'Select APIs'" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ Search for and ENABLE these specific APIs:" -ForegroundColor Red
Write-Host "   🔍 Search: 'Maps JavaScript API' - ENABLE" -ForegroundColor Green
Write-Host "   🔍 Search: 'Maps SDK for Android' - ENABLE" -ForegroundColor Green
Write-Host "   🔍 Search: 'Places API' - ENABLE" -ForegroundColor Green
Write-Host "   🔍 Search: 'Geocoding API' - ENABLE" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Save Changes and Wait 5-10 minutes" -ForegroundColor White
Write-Host ""

Write-Host "6️⃣ Test Android App:" -ForegroundColor White
Write-Host "   flutter run -d 2201117TI" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Why This Happens:" -ForegroundColor Yellow
Write-Host "   - Firebase APIs are enabled but Google Maps APIs are missing" -ForegroundColor White
Write-Host "   - Android app needs Maps SDK for Android specifically" -ForegroundColor White
Write-Host "   - Web app works because Maps JavaScript API might be enabled" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result:" -ForegroundColor Green
Write-Host "   - Android app will show real map with streets and buildings" -ForegroundColor White
Write-Host "   - Web app will continue working" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 