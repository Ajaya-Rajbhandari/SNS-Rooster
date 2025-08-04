# Complete Android Google Maps Fix
Write-Host "🔧 Complete Android Google Maps Fix" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 Current Issue: Android app shows blank map" -ForegroundColor Red
Write-Host "   Web app works, but Android doesn't" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔑 Your API Key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Android App Details:" -ForegroundColor Yellow
Write-Host "   Package Name: com.snstech.sns_rooster" -ForegroundColor White
Write-Host "   SHA-1: C3:1F:7F:09:4D:DB:A5:31:18:29:03:40:E8:E5:78:AE:5A:F8:CE:B4" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Steps to Fix in Google Cloud Console:" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find your API key and click on it" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Configure Application Restrictions:" -ForegroundColor White
Write-Host "   - Set to 'None' (EASIEST for development)" -ForegroundColor Green
Write-Host "   - OR set to 'Android apps' and add:" -ForegroundColor White
Write-Host "     * Package name: com.snstech.sns_rooster" -ForegroundColor Cyan
Write-Host "     * SHA-1: C3:1F:7F:09:4D:DB:A5:31:18:29:03:40:E8:E5:78:AE:5A:F8:CE:B4" -ForegroundColor Cyan
Write-Host ""

Write-Host "4️⃣ Enable Required APIs:" -ForegroundColor White
Write-Host "   Go to APIs and Services > Library and enable:" -ForegroundColor White
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for Android" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for iOS" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Configure API Restrictions:" -ForegroundColor White
Write-Host "   - Select 'Restrict key'" -ForegroundColor White
Write-Host "   - Enable all the APIs listed above" -ForegroundColor Green
Write-Host ""

Write-Host "6️⃣ Save Changes and Wait:" -ForegroundColor White
Write-Host "   - Click 'Save'" -ForegroundColor White
Write-Host "   - Wait 5-10 minutes for changes to propagate" -ForegroundColor Yellow
Write-Host ""

Write-Host "7️⃣ Test Android App:" -ForegroundColor White
Write-Host "   flutter run -d android" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Troubleshooting:" -ForegroundColor Yellow
Write-Host "   - Make sure billing is enabled" -ForegroundColor White
Write-Host "   - Grant location permissions on device" -ForegroundColor White
Write-Host "   - Clear app data if needed" -ForegroundColor White
Write-Host "   - Check device has internet connection" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result:" -ForegroundColor Green
Write-Host "   - Android app shows map with content" -ForegroundColor White
Write-Host "   - Location services work" -ForegroundColor White
Write-Host "   - No blank map area" -ForegroundColor White
Write-Host "   - Current location button works" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Quick Fix (Recommended):" -ForegroundColor Green
Write-Host "   Set Application Restrictions to None for development" -ForegroundColor White
Write-Host "   This will work for both web and Android immediately" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 