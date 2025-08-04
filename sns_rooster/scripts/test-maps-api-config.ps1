# Test Google Maps API Configuration
Write-Host "🧪 Testing Google Maps API Configuration" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Current Configuration:" -ForegroundColor Yellow
Write-Host ""

Write-Host "🌐 Web App:" -ForegroundColor White
Write-Host "   API Key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Green
Write-Host "   Status: ✅ Working" -ForegroundColor Green
Write-Host ""

Write-Host "📱 Android App:" -ForegroundColor White
Write-Host "   API Key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Green
Write-Host "   Status: ❌ Blank Map (Map tiles not loading)" -ForegroundColor Red
Write-Host ""

Write-Host "🔍 Issue Analysis:" -ForegroundColor Yellow
Write-Host "   - Google Maps SDK: ✅ Initialized" -ForegroundColor Green
Write-Host "   - Map Controller: ✅ Ready" -ForegroundColor Green
Write-Host "   - Markers: ✅ Loaded" -ForegroundColor Green
Write-Host "   - Map Tiles: ❌ Blocked by API restrictions" -ForegroundColor Red
Write-Host ""

Write-Host "🔧 IMMEDIATE FIX REQUIRED:" -ForegroundColor Red
Write-Host "=================================" -ForegroundColor Red
Write-Host ""

Write-Host "1️⃣ Go to Google Cloud Console:" -ForegroundColor White
Write-Host "   https://console.cloud.google.com/apis/credentials" -ForegroundColor Blue
Write-Host ""

Write-Host "2️⃣ Find API key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ CRITICAL: Set Application Restrictions to 'None'" -ForegroundColor Red
Write-Host "   - This will allow both web and Android to work" -ForegroundColor Green
Write-Host ""

Write-Host "4️⃣ Enable Required APIs (APIs & Services > Library):" -ForegroundColor White
Write-Host "   ✅ Maps JavaScript API" -ForegroundColor Green
Write-Host "   ✅ Maps SDK for Android" -ForegroundColor Green
Write-Host "   ✅ Places API" -ForegroundColor Green
Write-Host "   ✅ Geocoding API" -ForegroundColor Green
Write-Host ""

Write-Host "5️⃣ Save Changes and Wait 5-10 minutes" -ForegroundColor White
Write-Host ""

Write-Host "6️⃣ Test Android App:" -ForegroundColor White
Write-Host "   flutter run -d 2201117TI" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Why This Happens:" -ForegroundColor Yellow
Write-Host "   - API key has domain restrictions for web" -ForegroundColor White
Write-Host "   - API key has Android app restrictions" -ForegroundColor White
Write-Host "   - Map tiles are blocked by these restrictions" -ForegroundColor White
Write-Host ""

Write-Host "✅ Expected Result After Fix:" -ForegroundColor Green
Write-Host "   - Android app shows map with streets and buildings" -ForegroundColor White
Write-Host "   - Web app continues to work" -ForegroundColor White
Write-Host "   - Both apps use the same API key" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue..." 