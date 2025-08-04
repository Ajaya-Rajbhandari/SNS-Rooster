# Build and Deploy APK for Direct Download System
# This script builds the Android APK and prepares it for the direct download system

Write-Host "Building and Deploying APK for Direct Download System" -ForegroundColor Green
Write-Host ""

# Check if we're in the correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: pubspec.yaml not found. Please run this script from the Flutter project root." -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Building Android APK..." -ForegroundColor Yellow
try {
    # Build the APK
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to build APK" -ForegroundColor Red
        exit 1
    }
    Write-Host "APK built successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error building APK: $_" -ForegroundColor Red
    exit 1
}

# Check if APK was created
$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "Error: APK file not found at $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: APK File Information..." -ForegroundColor Yellow
$apkInfo = Get-Item $apkPath
Write-Host "APK Path: $($apkInfo.FullName)" -ForegroundColor Cyan
Write-Host "File Size: $([math]::Round($apkInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "Created: $($apkInfo.CreationTime)" -ForegroundColor Cyan

Write-Host ""
Write-Host "Step 3: Next Steps for Deployment..." -ForegroundColor Yellow
Write-Host ""
Write-Host "To complete the direct download setup, you need to:" -ForegroundColor White
Write-Host ""
Write-Host "1. Upload the APK to your backend server:" -ForegroundColor Cyan
Write-Host "   - Copy the APK to: rooster-backend/uploads/apk/sns-rooster.apk" -ForegroundColor White
Write-Host "   - Or use the upload endpoint: POST /api/app/download/upload" -ForegroundColor White
Write-Host ""
Write-Host "2. Update the download URL in the backend:" -ForegroundColor Cyan
Write-Host "   - Edit: rooster-backend/routes/appDownloadRoutes.js" -ForegroundColor White
Write-Host "   - Update: download_url to point to your actual server" -ForegroundColor White
Write-Host ""
Write-Host "3. Deploy backend changes:" -ForegroundColor Cyan   
Write-Host "   - Push changes to your Git repository" -ForegroundColor White
Write-Host "   - Wait for Render to deploy the changes" -ForegroundColor White
Write-Host ""
Write-Host "4. Test the system:" -ForegroundColor Cyan
Write-Host "   - Run: ./scripts/test-direct-download.ps1" -ForegroundColor White
Write-Host "   - Test on an Android device" -ForegroundColor White

Write-Host ""
Write-Host "Step 4: Manual Upload Instructions..." -ForegroundColor Yellow
Write-Host ""
Write-Host "If you want to manually upload the APK:" -ForegroundColor White
Write-Host ""
Write-Host "1. Navigate to the backend directory:" -ForegroundColor Cyan
Write-Host "   cd ../rooster-backend" -ForegroundColor White
Write-Host ""
Write-Host "2. Create the uploads directory:" -ForegroundColor Cyan
Write-Host "   mkdir -p uploads/apk" -ForegroundColor White
Write-Host ""
Write-Host "3. Copy the APK:" -ForegroundColor Cyan
Write-Host "   copy '../sns_rooster/build/app/outputs/flutter-apk/app-release.apk' 'uploads/apk/sns-rooster.apk'" -ForegroundColor White
Write-Host ""
Write-Host "4. Commit and push changes:" -ForegroundColor Cyan
Write-Host "   git add ." -ForegroundColor White
Write-Host "   git commit -m 'Add APK for direct download'" -ForegroundColor White
Write-Host "   git push origin main" -ForegroundColor White

Write-Host ""
Write-Host "APK Build Complete!" -ForegroundColor Green
Write-Host "APK Location: $apkPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready for deployment to your direct download system!" -ForegroundColor Green 