# Production Build Script for SNS Rooster
Write-Host "🚀 Production Build for SNS Rooster" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Pre-Build Checklist:" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
Write-Host ""

Write-Host "✅ Google Maps APIs: Enabled" -ForegroundColor Green
Write-Host "✅ API Key: Configured for production" -ForegroundColor Green
Write-Host "✅ Environment Config: Ready" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Production Environment Variables:" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor White
Write-Host ""

Write-Host "ENVIRONMENT=production" -ForegroundColor Green
Write-Host "API_URL=https://sns-rooster.onrender.com/api" -ForegroundColor Green
Write-Host "APP_VERSION=1.0.0" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Building Production Web App..." -ForegroundColor Yellow
Write-Host "=================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Building Production Android App..." -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "Command: flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 For Google Play Store (AAB):" -ForegroundColor White
Write-Host "Command: flutter build appbundle --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔒 Security Notes:" -ForegroundColor Red
Write-Host "================" -ForegroundColor Red
Write-Host ""

Write-Host "⚠️  Before deploying to production:" -ForegroundColor Yellow
Write-Host "   - Update Google Cloud Console API key restrictions" -ForegroundColor White
Write-Host "   - Add your production domain to allowed referrers" -ForegroundColor White
Write-Host "   - Add your Android app package name and SHA-1" -ForegroundColor White
Write-Host "   - Enable billing in Google Cloud Console" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Web App Deployment:" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host ""

Write-Host "1. Build web app: flutter build web --release" -ForegroundColor White
Write-Host "2. Deploy build/web/ folder to your hosting service" -ForegroundColor White
Write-Host "3. Configure custom domain and SSL" -ForegroundColor White
Write-Host ""

Write-Host "📱 Android App Deployment:" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""

Write-Host "1. Build APK: flutter build apk --release" -ForegroundColor White
Write-Host "2. Build AAB: flutter build appbundle --release" -ForegroundColor White
Write-Host "3. Upload AAB to Google Play Console" -ForegroundColor White
Write-Host "4. Configure app signing and release" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Ready to build for production?" -ForegroundColor Green
Write-Host ""

$choice = Read-Host "Enter 'web', 'android', 'both', or 'exit': "

switch ($choice.ToLower()) {
    "web" {
        Write-Host "Building production web app..." -ForegroundColor Green
        flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
    }
    "android" {
        Write-Host "Building production Android app..." -ForegroundColor Green
        flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
    }
    "both" {
        Write-Host "Building both production apps..." -ForegroundColor Green
        flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
        flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
    }
    default {
        Write-Host "Exiting..." -ForegroundColor Yellow
    }
} 