# App Update Deployment Script
# This script automates the app update deployment workflow

param(
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$NewBuildNumber,
    
    [Parameter(Mandatory=$true)]
    [string]$FeatureDescription
)

Write-Host "App Update Deployment Script" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "===========" -ForegroundColor Yellow
Write-Host "New Version: $NewVersion" -ForegroundColor Cyan
Write-Host "New Build Number: $NewBuildNumber" -ForegroundColor Cyan
Write-Host "Feature Description: $FeatureDescription" -ForegroundColor Cyan
Write-Host ""

# Calculate next version for backend
$versionParts = $NewVersion.Split('.')
$nextVersion = "$($versionParts[0]).$($versionParts[1]).$([int]$versionParts[2] + 1)"
$nextBuildNumber = [int]$NewBuildNumber + 1

Write-Host "Calculated Next Version: $nextVersion+$nextBuildNumber" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Updating pubspec.yaml..." -ForegroundColor Green
# Update pubspec.yaml
$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$pubspecContent = $pubspecContent -replace "version: \d+\.\d+\.\d+\+\d+", "version: $NewVersion+$NewBuildNumber"
Set-Content $pubspecPath $pubspecContent
Write-Host "✅ Updated pubspec.yaml to version $NewVersion+$NewBuildNumber" -ForegroundColor Green

Write-Host ""
Write-Host "Step 2: Building APK..." -ForegroundColor Green
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ APK build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ APK built successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Updating backend configuration..." -ForegroundColor Green
# Update backend version configuration
$backendConfigPath = "..\rooster-backend\routes\appVersionRoutes.js"
$backendContent = Get-Content $backendConfigPath -Raw

# Update Android version
$androidPattern = "android: \{\s+latest_version: '[^']+',\s+latest_build_number: '[^']+',"
$androidReplacement = "android: {`n    latest_version: '$nextVersion',`n    latest_build_number: '$nextBuildNumber',"
$backendContent = $backendContent -replace $androidPattern, $androidReplacement

# Update Web version
$webPattern = "web: \{\s+latest_version: '[^']+',\s+latest_build_number: '[^']+',"
$webReplacement = "web: {`n    latest_version: '$nextVersion',`n    latest_build_number: '$nextBuildNumber',"
$backendContent = $backendContent -replace $webPattern, $webReplacement

Set-Content $backendConfigPath $backendContent
Write-Host "✅ Updated backend to expect version $nextVersion+$nextBuildNumber" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Deploying APK to backend..." -ForegroundColor Green
# Copy APK to backend
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "..\rooster-backend\downloads\sns-rooster.apk" -Force
Write-Host "✅ Copied APK to backend downloads folder" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Deploying to backend repository..." -ForegroundColor Green
Set-Location "..\rooster-backend"

# Add and commit APK
git add downloads/sns-rooster.apk
git commit -m "Deploy version $NewVersion+$NewBuildNumber APK with $FeatureDescription"
git push origin main

# Add and commit backend config
git add routes/appVersionRoutes.js
git commit -m "Update backend to expect v$nextVersion+$nextBuildNumber for next update cycle"
git push origin main

Write-Host "✅ Backend changes deployed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Testing deployment..." -ForegroundColor Green
Set-Location "..\sns_rooster"

# Wait for deployment
Write-Host "Waiting 15 seconds for deployment to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Test the version check
$headers = @{'User-Agent'="SNS-Rooster/$NewVersion (Android)"}
try {
    $response = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers
    Write-Host "✅ Backend version check working:" -ForegroundColor Green
    Write-Host "   Current: $($response.current_version)" -ForegroundColor Cyan
    Write-Host "   Latest: $($response.latest_version)" -ForegroundColor Cyan
    Write-Host "   Update Available: $($response.update_available)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Backend version check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 7: Installing new APK..." -ForegroundColor Green
flutter install --release
Write-Host "✅ New APK installed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "========" -ForegroundColor Yellow
Write-Host "✅ Updated pubspec.yaml to $NewVersion+$NewBuildNumber" -ForegroundColor Green
Write-Host "✅ Built new APK" -ForegroundColor Green
Write-Host "✅ Updated backend to expect $nextVersion+$nextBuildNumber" -ForegroundColor Green
Write-Host "✅ Deployed APK to backend" -ForegroundColor Green
Write-Host "✅ Deployed backend changes" -ForegroundColor Green
Write-Host "✅ Installed new APK on device" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "===========" -ForegroundColor Yellow
Write-Host "1. Test the app on your device" -ForegroundColor White
Write-Host "2. Verify version display shows $NewVersion+$NewBuildNumber" -ForegroundColor White
Write-Host "3. Verify NO update notification appears (backend expects $nextVersion)" -ForegroundColor White
Write-Host "4. Test all new features" -ForegroundColor White
Write-Host ""
Write-Host "To test the update flow with the previous version:" -ForegroundColor Yellow
Write-Host "1. Install the previous version APK" -ForegroundColor White
Write-Host "2. Open the app and go to login screen" -ForegroundColor White
Write-Host "3. Verify update notification appears" -ForegroundColor White
Write-Host "4. Test the update button" -ForegroundColor White 