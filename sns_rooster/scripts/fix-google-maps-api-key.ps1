# Fix Google Maps API Key Script
# This script replaces hardcoded API keys with environment variables

param(
    [string]$ApiKey = ""
)

Write-Host "🔧 Fixing Google Maps API Key Configuration..." -ForegroundColor Yellow

# Check if API key is provided
if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "❌ No API key provided. Please provide the Google Maps API key." -ForegroundColor Red
    Write-Host "Usage: .\fix-google-maps-api-key.ps1 -ApiKey 'YOUR_API_KEY'" -ForegroundColor Yellow
    exit 1
}

# Files to update
$files = @(
    "web\index.html",
    "web\index.template.html"
)

$apiKeyPattern = 'AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc'
$replacementText = '{{GOOGLE_MAPS_API_KEY}}'

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "📝 Updating $file..." -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content $file -Raw
        
        # Replace hardcoded API key with placeholder
        $newContent = $content -replace $apiKeyPattern, $replacementText
        
        # Write back to file
        Set-Content $file $newContent -NoNewline
        
        Write-Host "✅ Updated $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️ File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "🎉 Google Maps API key configuration updated!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Set GOOGLE_MAPS_API_KEY environment variable" -ForegroundColor White
Write-Host "   2. Build web app with: flutter build web --dart-define=GOOGLE_MAPS_API_KEY='$ApiKey'" -ForegroundColor White
Write-Host "   3. Deploy to Firebase" -ForegroundColor White 