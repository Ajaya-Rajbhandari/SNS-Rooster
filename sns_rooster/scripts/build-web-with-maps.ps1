# Build Web App with Google Maps API Key Script
# This script builds the Flutter web app with proper API key handling

param(
    [string]$ApiKey = "AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc",
    [switch]$Deploy = $false
)

Write-Host "🌐 Building Flutter Web App with Google Maps API Key..." -ForegroundColor Yellow
Write-Host "API Key: $($ApiKey.Substring(0, 10))..." -ForegroundColor Cyan

# Step 1: Build the Flutter web app with API key
Write-Host "`n📦 Step 1: Building Flutter web app..." -ForegroundColor Green
$buildCommand = "flutter build web --release --dart-define=GOOGLE_MAPS_API_KEY=$ApiKey"
Write-Host "Command: $buildCommand" -ForegroundColor Gray

try {
    Invoke-Expression $buildCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter web build completed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Flutter web build failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error during Flutter build: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Replace API key placeholder in built files
Write-Host "`n🔧 Step 2: Replacing API key placeholder..." -ForegroundColor Green
$indexHtmlPath = "build\web\index.html"

if (Test-Path $indexHtmlPath) {
    Write-Host "📝 Updating $indexHtmlPath..." -ForegroundColor Cyan
    
    try {
        $content = Get-Content $indexHtmlPath -Raw
        $newContent = $content -replace '\{\{GOOGLE_MAPS_API_KEY\}\}', $ApiKey
        Set-Content $indexHtmlPath $newContent -NoNewline
        
        Write-Host "✅ API key placeholder replaced successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error replacing API key: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️ Built index.html not found at $indexHtmlPath" -ForegroundColor Yellow
}

# Step 3: Deploy to Firebase if requested
if ($Deploy) {
    Write-Host "`n🚀 Step 3: Deploying to Firebase..." -ForegroundColor Green
    
    try {
        $deployCommand = "firebase deploy --only hosting"
        Write-Host "Command: $deployCommand" -ForegroundColor Gray
        Invoke-Expression $deployCommand
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Firebase deployment completed successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Firebase deployment failed" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Error during Firebase deployment: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n🎉 Build process completed successfully!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Cyan
Write-Host "  - Flutter web app built with API key" -ForegroundColor White
Write-Host "  - API key placeholder replaced" -ForegroundColor White
if ($Deploy) {
    Write-Host "  - App deployed to Firebase" -ForegroundColor White
}
Write-Host "  - Build files available in build\web\" -ForegroundColor White

if (-not $Deploy) {
    Write-Host "`n💡 To deploy to Firebase, run: .\scripts\build-web-with-maps.ps1 -ApiKey '$ApiKey' -Deploy" -ForegroundColor Yellow
} 