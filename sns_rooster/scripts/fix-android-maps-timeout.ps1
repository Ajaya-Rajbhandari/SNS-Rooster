# Fix Android Google Maps REQUEST_TIMEOUT Issue
Write-Host "🔧 Fix Android Google Maps REQUEST_TIMEOUT Issue" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 Current Issue: REQUEST_TIMEOUT on Android" -ForegroundColor Red
Write-Host "   Error: m140.iaf failed with Status bvm{errorCode=REQUEST_TIMEOUT}" -ForegroundColor Yellow
Write-Host "   Web works, Android times out" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔍 Root Cause Analysis:" -ForegroundColor Yellow
Write-Host "   - Google Play Services timeout" -ForegroundColor White
Write-Host "   - API key restrictions blocking Android" -ForegroundColor White
Write-Host "   - Network connectivity issues" -ForegroundColor White
Write-Host ""

Write-Host "🔧 IMMEDIATE FIXES REQUIRED:" -ForegroundColor Red
Write-Host "=============================" -ForegroundColor Red
Write-Host ""

Write-Host "1️⃣ GOOGLE CLOUD CONSOLE - API KEY SETTINGS:" -ForegroundColor White
Write-Host "   URL: https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host "   Find key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Green
Write-Host ""
Write-Host "   CRITICAL: Set Application Restrictions to 'None'" -ForegroundColor Red
Write-Host "   - This allows both web and Android to work" -ForegroundColor Green
Write-Host "   - Current restrictions are blocking Android SDK" -ForegroundColor Yellow
Write-Host ""

Write-Host "2️⃣ ENABLE REQUIRED APIs:" -ForegroundColor White
Write-Host "   Go to APIs & Services > Library and enable:" -ForegroundColor White
Write-Host "   ✅ Maps SDK for Android" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for iOS" -ForegroundColor Green
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "3️⃣ ANDROID DEVICE FIXES:" -ForegroundColor White
Write-Host "   - Clear Google Play Services cache" -ForegroundColor Yellow
Write-Host "   - Restart device" -ForegroundColor Yellow
Write-Host "   - Check internet connection" -ForegroundColor Yellow
Write-Host ""

Write-Host "4️⃣ ALTERNATIVE: CREATE NEW API KEY:" -ForegroundColor White
Write-Host "   If above doesn't work, create a new API key:" -ForegroundColor White
Write-Host "   - Go to Google Cloud Console > Credentials" -ForegroundColor Blue
Write-Host "   - Create new API key" -ForegroundColor Green
Write-Host "   - Set restrictions to 'None' initially" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ TEST STEPS:" -ForegroundColor White
Write-Host "   - Clean build: flutter clean && flutter pub get" -ForegroundColor Green
Write-Host "   - Rebuild: flutter run" -ForegroundColor Green
Write-Host "   - Check Android logs for timeout errors" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "   - The timeout suggests API key restrictions" -ForegroundColor White
Write-Host "   - Web works because it uses different API endpoints" -ForegroundColor White
Write-Host "   - Android SDK requires proper API key configuration" -ForegroundColor White
Write-Host ""

Write-Host "🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "   - Google Cloud Console: https://console.cloud.google.com/" -ForegroundColor Blue
Write-Host "   - Maps SDK for Android: https://developers.google.com/maps/documentation/android-sdk" -ForegroundColor Blue
Write-Host "   - API Key Restrictions: https://developers.google.com/maps/api-security" -ForegroundColor Blue 