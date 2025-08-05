# Test Production Build Script
Write-Host "🧪 Testing Production Build" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# Check if production build exists
if (-not (Test-Path "build/web/index.html")) {
    Write-Host "❌ Production build not found!" -ForegroundColor Red
    Write-Host "   Run: flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Production build found" -ForegroundColor Green

# Check for exposed API keys in the build
Write-Host "🔍 Checking for exposed API keys..." -ForegroundColor Yellow
$apiKeyFound = Select-String -Path "build/web/index.html" -Pattern "AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -Quiet

if ($apiKeyFound) {
    Write-Host "❌ API key still exposed in production build!" -ForegroundColor Red
    Write-Host "   Security fix not working properly" -ForegroundColor Yellow
} else {
    Write-Host "✅ No API keys exposed in production build" -ForegroundColor Green
}

# Check for secure Firebase loading
Write-Host "🔍 Checking Firebase configuration..." -ForegroundColor Yellow
$secureFirebase = Select-String -Path "build/web/index.html" -Pattern "initializeFirebaseSecurely" -Quiet

if ($secureFirebase) {
    Write-Host "✅ Firebase loads securely from backend" -ForegroundColor Green
} else {
    Write-Host "❌ Firebase not configured securely!" -ForegroundColor Red
}

# Check for relative Google Maps URL
Write-Host "🔍 Checking Google Maps configuration..." -ForegroundColor Yellow
$relativeMapsUrl = Select-String -Path "build/web/index.html" -Pattern "/api/google-maps/script" -Quiet

if ($relativeMapsUrl) {
    Write-Host "✅ Google Maps uses relative URL for production" -ForegroundColor Green
} else {
    Write-Host "❌ Google Maps still using localhost!" -ForegroundColor Red
}

# Test backend connectivity
Write-Host "🔍 Testing backend connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/health" -Method Get -TimeoutSec 10
    Write-Host "✅ Backend is accessible" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend connectivity test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Production Build Test Summary:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

if ((-not $apiKeyFound) -and $secureFirebase -and $relativeMapsUrl) {
    Write-Host "✅ PRODUCTION BUILD IS READY FOR DEPLOYMENT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor White
    Write-Host "   1. Deploy build/web/ folder to your hosting service" -ForegroundColor White
    Write-Host "   2. Configure custom domain and SSL" -ForegroundColor White
    Write-Host "   3. Update Google Cloud Console API key restrictions" -ForegroundColor White
    Write-Host "   4. Test in production environment" -ForegroundColor White
} else {
    Write-Host "❌ PRODUCTION BUILD HAS ISSUES!" -ForegroundColor Red
    Write-Host "   Fix the issues above before deploying" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 To test locally:" -ForegroundColor Cyan
Write-Host "   cd build/web" -ForegroundColor White
Write-Host "   npx serve -s . -l 8080" -ForegroundColor White
Write-Host "   Then open: http://localhost:8080" -ForegroundColor White 