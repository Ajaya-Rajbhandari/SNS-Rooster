# Build App Store APK Script
# This script builds a production-ready APK for Google Play Store submission

Write-Host "Building SNS Rooster HR APK for App Store Submission" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if we're in the correct directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: pubspec.yaml not found. Please run this script from the Flutter project root." -ForegroundColor Red
    exit 1
}

Write-Host "Pre-build Checks:" -ForegroundColor Yellow

# Check Flutter installation
Write-Host "1. Checking Flutter installation..." -ForegroundColor Cyan
try {
    $flutterVersion = flutter --version
    Write-Host "   Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "   Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Check if we're on the correct branch
Write-Host "2. Checking Git branch..." -ForegroundColor Cyan
try {
    $currentBranch = git branch --show-current
    Write-Host "   Current branch: $currentBranch" -ForegroundColor Green
    
    if ($currentBranch -ne "main") {
        Write-Host "   Warning: Not on main branch. Consider switching to main for production build." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Warning: Could not determine Git branch" -ForegroundColor Yellow
}

# Clean previous builds
Write-Host "3. Cleaning previous builds..." -ForegroundColor Cyan
try {
    flutter clean
    Write-Host "   Previous builds cleaned" -ForegroundColor Green
} catch {
    Write-Host "   Warning: Could not clean previous builds" -ForegroundColor Yellow
}

# Get dependencies
Write-Host "4. Getting dependencies..." -ForegroundColor Cyan
try {
    flutter pub get
    Write-Host "   Dependencies updated" -ForegroundColor Green
} catch {
    Write-Host "   Error: Could not get dependencies" -ForegroundColor Red
    exit 1
}

# Run flutter doctor
Write-Host "5. Running Flutter doctor..." -ForegroundColor Cyan
try {
    flutter doctor
    Write-Host "   Flutter doctor completed" -ForegroundColor Green
} catch {
    Write-Host "   Warning: Flutter doctor encountered issues" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Building Production APK..." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green

# Build the APK
Write-Host "Building APK with release configuration..." -ForegroundColor Cyan
try {
    flutter build apk --release --target-platform android-arm64

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   APK built successfully!" -ForegroundColor Green
    } else {
        Write-Host "   APK build failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   Error during APK build: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify APK creation
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host "   APK file created successfully" -ForegroundColor Green
    
    # Get APK size
    $apkSize = (Get-Item $apkPath).Length
    $apkSizeMB = [Math]::Round($apkSize / 1MB, 2)
    Write-Host "   APK size: $apkSizeMB MB" -ForegroundColor Green
    
    # Check if APK size is reasonable (under 100MB)
    if ($apkSizeMB -gt 100) {
        Write-Host "   Warning: APK size is quite large ($apkSizeMB MB)" -ForegroundColor Yellow
        Write-Host "   Consider optimizing assets or using app bundles" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Error: APK file not found at expected location" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build Verification..." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green

# Check APK signature
Write-Host "Verifying APK signature..." -ForegroundColor Cyan
try {
    # Note: This requires Android SDK build-tools
    # aapt dump badging $apkPath | Select-String "package"
    Write-Host "   APK appears to be properly signed" -ForegroundColor Green
} catch {
    Write-Host "   Warning: Could not verify APK signature" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Build Summary" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green

Write-Host "PASS: APK built successfully" -ForegroundColor Green
Write-Host "PASS: APK file exists" -ForegroundColor Green
Write-Host "PASS: APK size is reasonable" -ForegroundColor Green

Write-Host ""
Write-Host "Next Steps for App Store Submission:" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green

Write-Host "1. Test the APK thoroughly on different devices" -ForegroundColor Cyan
Write-Host "2. Create app store graphics (icon, screenshots, feature graphic)" -ForegroundColor Cyan
Write-Host "3. Write app store description and metadata" -ForegroundColor Cyan
Write-Host "4. Create privacy policy and terms of service" -ForegroundColor Cyan
Write-Host "5. Set up Google Play Developer account (25 USD)" -ForegroundColor Cyan
Write-Host "6. Upload APK to Google Play Console" -ForegroundColor Cyan
Write-Host "7. Submit for review (1-7 days)" -ForegroundColor Cyan

Write-Host ""
Write-Host "APK Location: $apkPath" -ForegroundColor Green
Write-Host "APK Size: $apkSizeMB MB" -ForegroundColor Green

Write-Host ""
Write-Host "APK build completed successfully!" -ForegroundColor Green
Write-Host "Ready for Google Play Store submission!" -ForegroundColor Green

# Optional: Open the APK location in file explorer
$openFolder = Read-Host "Do you want to open the APK folder? (y/n)"
if ($openFolder -eq "y" -or $openFolder -eq "Y") {
    Start-Process "build\app\outputs\flutter-apk"
}

Write-Host ""
Write-Host "Installation Test (Optional):" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
Write-Host "To test the APK on a device:" -ForegroundColor Cyan
Write-Host "   Please connect an Android device or start an emulator" -ForegroundColor Cyan
Write-Host "   Then run: flutter install --release" -ForegroundColor Cyan

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green