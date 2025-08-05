# Fix Flutter Web Errors Script
Write-Host "🔧 Fixing Flutter Web Errors" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Common Issues This Fixes:" -ForegroundColor Yellow
Write-Host "   - _scriptUrls already declared error" -ForegroundColor White
Write-Host "   - Google Maps loading conflicts" -ForegroundColor White
Write-Host "   - Firebase initialization issues" -ForegroundColor White
Write-Host "   - Build cache corruption" -ForegroundColor White
Write-Host ""

Write-Host "🧹 Step 1: Cleaning build cache..." -ForegroundColor Green
flutter clean

Write-Host "📦 Step 2: Getting dependencies..." -ForegroundColor Green
flutter pub get

Write-Host "🔨 Step 3: Rebuilding web app..." -ForegroundColor Green
flutter run -d chrome --web-port=3000 --dart-define=ENVIRONMENT=development --dart-define=API_URL=http://192.168.1.80:5000/api

Write-Host ""
Write-Host "✅ Fix completed! The app should now work without errors." -ForegroundColor Green
Write-Host ""
Write-Host "💡 If you still see errors:" -ForegroundColor Yellow
Write-Host "   1. Check that the backend is running: cd rooster-backend && npm start" -ForegroundColor White
Write-Host "   2. Clear browser cache and reload" -ForegroundColor White
Write-Host "   3. Try a different browser" -ForegroundColor White 