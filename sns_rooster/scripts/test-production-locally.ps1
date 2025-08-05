# Test Production Build Locally
Write-Host "🧪 Testing Production Build Locally" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Steps:" -ForegroundColor Yellow
Write-Host "1. Building production web app..." -ForegroundColor White
Write-Host "2. Starting local server..." -ForegroundColor White
Write-Host "3. Opening browser..." -ForegroundColor White
Write-Host ""

# Build production web app
Write-Host "🚀 Building production web app..." -ForegroundColor Green
flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api

if (-not (Test-Path "build/web/index.html")) {
    Write-Host "❌ Production build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Production build completed" -ForegroundColor Green

# Navigate to build directory
Set-Location "build/web"

Write-Host ""
Write-Host "🌐 Starting local server..." -ForegroundColor Green
Write-Host "   URL: http://localhost:8080" -ForegroundColor White
Write-Host "   Network: http://192.168.1.80:8080" -ForegroundColor White
Write-Host ""

# Start local server
npx serve -s . -l 8080 