# Production Build Script for SNS Rooster Web App
Write-Host "🚀 Building SNS Rooster Web App for Production..." -ForegroundColor Green

# Set environment variables for production build
$env:API_URL = "https://sns-rooster.onrender.com/api"
$env:FIREBASE_API_KEY = "AIzaSyBWg9ySUE_XSpPF4T5Og1FLoazIZR8Orqg"
$env:FIREBASE_PROJECT_ID = "sns-rooster-8cca5"
$env:FIREBASE_MESSAGING_SENDER_ID = "901502276055"
$env:FIREBASE_APP_ID = "1:901502276055:web:f4f94088120f52dc8f7b92"
$env:GOOGLE_MAPS_API_KEY = "AIzaSyCjFtMPrWvzlLcOZHhHAvNpVMwGVAFtcAo"
$env:ENVIRONMENT = "production"
$env:APP_NAME = "SNS HR"
$env:APP_VERSION = "1.0.0"

Write-Host "📋 Environment Variables Set:" -ForegroundColor Cyan
Write-Host "   API_URL: $env:API_URL" -ForegroundColor White
Write-Host "   ENVIRONMENT: $env:ENVIRONMENT" -ForegroundColor White
Write-Host "   FIREBASE_PROJECT_ID: $env:FIREBASE_PROJECT_ID" -ForegroundColor White

# Build the web app
Write-Host "🔨 Building Flutter Web App..." -ForegroundColor Yellow
flutter build web --release --dart-define=API_URL="$env:API_URL" --dart-define=FIREBASE_API_KEY="$env:FIREBASE_API_KEY" --dart-define=FIREBASE_PROJECT_ID="$env:FIREBASE_PROJECT_ID" --dart-define=FIREBASE_MESSAGING_SENDER_ID="$env:FIREBASE_MESSAGING_SENDER_ID" --dart-define=FIREBASE_APP_ID="$env:FIREBASE_APP_ID" --dart-define=GOOGLE_MAPS_API_KEY="$env:GOOGLE_MAPS_API_KEY" --dart-define=ENVIRONMENT="$env:ENVIRONMENT" --dart-define=APP_NAME="$env:APP_NAME" --dart-define=APP_VERSION="$env:APP_VERSION"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "📁 Build output: build/web/" -ForegroundColor Cyan
    Write-Host "🚀 Ready to deploy to Firebase!" -ForegroundColor Green
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
} 