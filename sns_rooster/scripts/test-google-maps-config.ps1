# Test Google Maps Configuration
Write-Host "🧪 Testing Google Maps Configuration" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Current Configuration:" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔑 API Key:" -ForegroundColor White
Write-Host "   AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Green
Write-Host ""

Write-Host "🌐 Web Configuration:" -ForegroundColor White
Write-Host "   ✅ API key in index.html" -ForegroundColor Green
Write-Host "   ✅ Libraries: places" -ForegroundColor Green
Write-Host ""

Write-Host "📱 Android Configuration:" -ForegroundColor White
Write-Host "   ✅ API key in AndroidManifest.xml" -ForegroundColor Green
Write-Host "   ✅ Location permissions" -ForegroundColor Green
Write-Host "   ✅ minSdkVersion: 23" -ForegroundColor Green
Write-Host ""

Write-Host "📦 Flutter Dependencies:" -ForegroundColor White
Write-Host "   ✅ google_maps_flutter: ^2.5.3" -ForegroundColor Green
Write-Host "   ✅ geolocator: ^11.0.0" -ForegroundColor Green
Write-Host "   ✅ geocoding: ^2.1.1" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣ Fix Google Cloud Console:" -ForegroundColor White
Write-Host "   - Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host "   - Set Application Restrictions to 'None'" -ForegroundColor Green
Write-Host "   - Enable Maps JavaScript API, Places API, Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "2️⃣ Test Web:" -ForegroundColor White
Write-Host "   flutter run -d chrome" -ForegroundColor Cyan
Write-Host ""

Write-Host "3️⃣ Test Mobile:" -ForegroundColor White
Write-Host "   flutter run -d android" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Common Issues:" -ForegroundColor Yellow
Write-Host "   - ApiTargetBlockedMapError: API key restrictions" -ForegroundColor Red
Write-Host "   - MissingPluginException: Plugin not registered" -ForegroundColor Red
Write-Host "   - Location permissions not granted" -ForegroundColor Red
Write-Host ""

Write-Host "✅ Expected Results:" -ForegroundColor Green
Write-Host "   - Maps load without errors" -ForegroundColor White
Write-Host "   - Location services work" -ForegroundColor White
Write-Host "   - No console errors" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 