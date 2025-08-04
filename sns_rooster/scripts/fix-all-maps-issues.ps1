# Comprehensive Fix for All Google Maps Issues
Write-Host "🔧 Comprehensive Google Maps and Geolocator Fix" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Issues to Fix:" -ForegroundColor Yellow
Write-Host "   ❌ Web: ApiTargetBlockedMapError" -ForegroundColor Red
Write-Host "   ❌ Mobile: MissingPluginException for geolocator" -ForegroundColor Red
Write-Host "   ❌ Mobile: Google Maps platform view unregistered" -ForegroundColor Red
Write-Host ""

Write-Host "🔧 STEP 1: Fix Google Cloud Console API Key" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ Configure Application Restrictions:" -ForegroundColor White
Write-Host "   - Set to 'None' (for development)" -ForegroundColor Green
Write-Host "   - OR add these HTTP referrers:" -ForegroundColor White
Write-Host "     * http://localhost:3000/*" -ForegroundColor Cyan
Write-Host "     * http://localhost:*/*" -ForegroundColor Cyan
Write-Host "     * http://127.0.0.1:*/*" -ForegroundColor Cyan
Write-Host ""

Write-Host "4️⃣ Enable Required APIs:" -ForegroundColor White
Write-Host "   Go to APIs and Services > Library and enable:" -ForegroundColor White
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for Android" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for iOS" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Check Billing:" -ForegroundColor White
Write-Host "   - Ensure billing is enabled for your project" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 STEP 2: Fix Mobile Plugin Issues" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

Write-Host "6️⃣ Clean and Rebuild Flutter Project:" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor Cyan
Write-Host "   flutter pub get" -ForegroundColor Cyan
Write-Host "   flutter pub upgrade" -ForegroundColor Cyan
Write-Host ""

Write-Host "7️⃣ For Android, check build.gradle:" -ForegroundColor White
Write-Host "   - Ensure minSdkVersion >= 20" -ForegroundColor Green
Write-Host "   - Ensure targetSdkVersion >= 33" -ForegroundColor Green
Write-Host ""

Write-Host "8️⃣ For iOS, check Info.plist:" -ForegroundColor White
Write-Host "   - Add location usage descriptions" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 STEP 3: Test the Fix" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green
Write-Host ""

Write-Host "9️⃣ Test Web:" -ForegroundColor White
Write-Host "   - Run: flutter run -d chrome" -ForegroundColor Cyan
Write-Host "   - Check browser console for errors" -ForegroundColor White
Write-Host ""

Write-Host "🔟 Test Mobile:" -ForegroundColor White
Write-Host "   - Run: flutter run -d android" -ForegroundColor Cyan
Write-Host "   - Check for location permissions" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "   - Wait 5-10 minutes after API key changes" -ForegroundColor White
Write-Host "   - Clear browser cache for web testing" -ForegroundColor White
Write-Host "   - Grant location permissions on mobile" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Results:" -ForegroundColor Green
Write-Host "   - Web: Google Maps loads without errors" -ForegroundColor White
Write-Host "   - Mobile: Location services work properly" -ForegroundColor White
Write-Host "   - Mobile: Google Maps displays correctly" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to start the fix process..." 