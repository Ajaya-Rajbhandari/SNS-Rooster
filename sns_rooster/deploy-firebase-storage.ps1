# Deploy Firebase Storage Rules
Write-Host "🚀 Deploying Firebase Storage Rules..." -ForegroundColor Green

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Login to Firebase (if not already logged in)
Write-Host "🔐 Checking Firebase login status..." -ForegroundColor Yellow
try {
    firebase projects:list
    Write-Host "✅ Already logged in to Firebase" -ForegroundColor Green
} catch {
    Write-Host "🔐 Please login to Firebase..." -ForegroundColor Yellow
    firebase login
}

# Deploy storage rules
Write-Host "📤 Deploying storage rules..." -ForegroundColor Yellow
firebase deploy --only storage

Write-Host "✅ Firebase Storage rules deployed successfully!" -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your Flutter app" -ForegroundColor White
Write-Host "2. Try loading the logo again" -ForegroundColor White
Write-Host "3. The certificate issue should be resolved" -ForegroundColor White 