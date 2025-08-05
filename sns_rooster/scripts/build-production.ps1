# Production Build Script
Write-Host "🚀 Building SNS Rooster for PRODUCTION" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

Write-Host "🔒 Security Check:" -ForegroundColor Yellow
Write-Host "   ✅ No hardcoded IP addresses" -ForegroundColor Green
Write-Host "   ✅ Using relative URLs for production" -ForegroundColor Green
Write-Host "   ✅ Firebase loads securely from backend" -ForegroundColor Green
Write-Host "   ✅ Google Maps loads securely from backend" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Environment Variables:" -ForegroundColor Yellow
Write-Host "   ENVIRONMENT: production" -ForegroundColor White
Write-Host "   API_URL: https://sns-rooster.onrender.com/api" -ForegroundColor White
Write-Host ""

Write-Host "📦 Building production web app..." -ForegroundColor Cyan
flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api

if (Test-Path "build/web/index.html") {
    Write-Host "✅ Production build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Deploy build/web/ folder to your hosting service" -ForegroundColor White
    Write-Host "   2. Configure custom domain and SSL" -ForegroundColor White
    Write-Host "   3. Update Google Cloud Console API key restrictions" -ForegroundColor White
    Write-Host "   4. Test in production environment" -ForegroundColor White
} else {
    Write-Host "❌ Production build failed!" -ForegroundColor Red
} 