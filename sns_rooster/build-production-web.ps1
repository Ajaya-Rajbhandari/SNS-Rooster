# Production Web Build Script for SNS Rooster
# This script builds the Flutter web app with correct production settings

Write-Host "🚀 Building SNS Rooster Web App for Production..." -ForegroundColor Green
Write-Host "Version: 1.0.3+4" -ForegroundColor Cyan

# Build Flutter web app with production environment variables
flutter build web `
  --dart-define=API_URL="https://sns-rooster.onrender.com/api" `
  --dart-define=FIREBASE_API_KEY="AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" `
  --dart-define=FIREBASE_PROJECT_ID="sns-rooster-8cca5" `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="901502276055" `
  --dart-define=FIREBASE_APP_ID="1:901502276055:web:f4f94088120f52dc8f7b92" `
  --dart-define=GOOGLE_MAPS_API_KEY="AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" `
  --dart-define=ENVIRONMENT="production" `
  --dart-define=APP_NAME="SNS HR" `
  --dart-define=APP_VERSION="1.0.3" `
  --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Production web app built successfully!" -ForegroundColor Green
    Write-Host "📁 Output: build/web/" -ForegroundColor Cyan
    Write-Host "🔑 Google Maps API Key: AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc" -ForegroundColor Yellow
    Write-Host "🌐 API URL: https://sns-rooster.onrender.com/api" -ForegroundColor Yellow
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
} 