# Fix Android Google Maps Issues
Write-Host "🔧 Fix Android Google Maps Issues" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 Current Issue: Android app shows blank map" -ForegroundColor Red
Write-Host "   Web app works, but Android doesn't" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔧 Root Cause: API Key Restrictions" -ForegroundColor Green
Write-Host "   The API key needs to be configured for Android apps" -ForegroundColor White
Write-Host ""

Write-Host "📋 Steps to Fix:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find your API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Configure Application Restrictions:" -ForegroundColor White
Write-Host "   - Set to 'None' (for development)" -ForegroundColor Green
Write-Host "   - OR set to 'Android apps' and add:" -ForegroundColor White
Write-Host "     * Package name: com.snstech.sns_rooster" -ForegroundColor Cyan
Write-Host "     * SHA-1: (get from debug keystore)" -ForegroundColor Cyan
Write-Host ""

Write-Host "4️⃣ Get SHA-1 Certificate Fingerprint:" -ForegroundColor White
Write-Host "   Run this command in PowerShell:" -ForegroundColor Cyan
Write-Host "   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Enable Required APIs:" -ForegroundColor White
Write-Host "   Go to APIs and Services > Library and enable:" -ForegroundColor White
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for Android" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for iOS" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "6️⃣ Configure API Restrictions:" -ForegroundColor White
Write-Host "   - Select 'Restrict key'" -ForegroundColor White
Write-Host "   - Enable all the APIs listed above" -ForegroundColor Green
Write-Host ""

Write-Host "7️⃣ Save Changes and Wait:" -ForegroundColor White
Write-Host "   - Click 'Save'" -ForegroundColor White
Write-Host "   - Wait 5-10 minutes for changes to propagate" -ForegroundColor Yellow
Write-Host ""

Write-Host "8️⃣ Test Android App:" -ForegroundColor White
Write-Host "   flutter run -d android" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "   - Make sure billing is enabled" -ForegroundColor White
Write-Host "   - Grant location permissions on device" -ForegroundColor White
Write-Host "   - Clear app data if needed" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result:" -ForegroundColor Green
Write-Host "   - Android app shows map with content" -ForegroundColor White
Write-Host "   - Location services work" -ForegroundColor White
Write-Host "   - No blank map area" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 