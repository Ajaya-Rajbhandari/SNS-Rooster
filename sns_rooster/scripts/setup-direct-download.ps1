# Setup Direct Download System for SNS Rooster
# This script sets up direct APK downloads without Google Play Store

Write-Host "📱 Setting up Direct Download System..." -ForegroundColor Cyan

# 1. Create APK upload directory
Write-Host "📁 Creating APK upload directory..." -ForegroundColor Yellow
$apkDir = "rooster-backend/uploads/apk"
if (!(Test-Path $apkDir)) {
    New-Item -ItemType Directory -Path $apkDir -Force
    Write-Host "✅ Created directory: $apkDir" -ForegroundColor Green
} else {
    Write-Host "✅ Directory already exists: $apkDir" -ForegroundColor Green
}

# 2. Copy current APK to upload directory
Write-Host "📦 Copying current APK..." -ForegroundColor Yellow
$sourceApk = "build/app/outputs/flutter-apk/app-release.apk"
$targetApk = "$apkDir/sns-rooster.apk"

if (Test-Path $sourceApk) {
    Copy-Item $sourceApk $targetApk -Force
    Write-Host "✅ APK copied to: $targetApk" -ForegroundColor Green
} else {
    Write-Host "⚠️ Source APK not found: $sourceApk" -ForegroundColor Yellow
    Write-Host "   Please build the APK first with: flutter build apk --release" -ForegroundColor White
}

# 3. Create deployment guide
Write-Host "📋 Creating deployment guide..." -ForegroundColor Yellow

$deploymentGuide = @"
# Direct Download System Setup Guide

## 🚀 How to Deploy APK Updates

### 1. Build New APK

```bash
cd sns_rooster
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api
```

### 2. Upload APK to Server

Copy the new APK to the server:
```bash
# Copy APK to backend uploads directory
cp build/app/outputs/flutter-apk/app-release.apk rooster-backend/uploads/apk/sns-rooster.apk
```

### 3. Update Version Information

Update the version info via API:
```bash
curl -X POST https://sns-rooster.onrender.com/api/app/version/update \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "android",
    "version": "1.0.1",
    "build_number": "2",
    "update_required": false,
    "message": "New features and bug fixes available!"
  }'
```

### 4. Deploy Backend Changes

```bash
cd rooster-backend
git add .
git commit -m "Update APK to version 1.0.1"
git push origin main
```

## 📱 How Direct Download Works

### For Users:
1. **App checks for updates** automatically on startup
2. **Update alert appears** if new version is available
3. **User clicks "Download & Install"**
4. **APK downloads directly** from your server
5. **Android installer opens** automatically
6. **User confirms installation**

### For Admins:
1. **Build new APK** with updated version
2. **Upload APK** to server
3. **Update version info** via API
4. **Deploy changes** to backend
5. **Users get notified** automatically

## 🔧 Configuration

### APK File Location:
- **Server Path**: `rooster-backend/uploads/apk/sns-rooster.apk`
- **Download URL**: `https://sns-rooster.onrender.com/api/app/download/android/file`

### Version Management:
- **Check Version**: `GET /api/app/version/check`
- **Update Version**: `POST /api/app/version/update`
- **Download Info**: `GET /api/app/download/android`
- **Download File**: `GET /api/app/download/android/file`

## 🔒 Security Features

### Permissions Required:
- **Storage Permission**: To save APK file
- **Install Permission**: To install APK file
- **Network Permission**: To download APK file

### Security Measures:
- **File Validation**: Checksum verification
- **Size Validation**: File size limits
- **Access Control**: Admin-only uploads
- **HTTPS Only**: Secure downloads

## 📊 Monitoring

### Download Statistics:
- **Download Count**: Track successful downloads
- **Error Tracking**: Monitor failed downloads
- **Version Adoption**: Track update success rates
- **User Feedback**: Monitor installation issues

### Logs to Monitor:
- **Backend Logs**: Download requests and errors
- **App Logs**: Update check results
- **Installation Logs**: Success/failure rates

## 🎯 Testing

### Test Direct Download:
```bash
# Test download info
curl https://sns-rooster.onrender.com/api/app/download/android

# Test file download
curl -O https://sns-rooster.onrender.com/api/app/download/android/file
```

### Test Update Check:
```bash
# Test version check
curl https://sns-rooster.onrender.com/api/app/version/check
```

## 🚨 Important Notes

### Android Requirements:
- **Android 8.0+**: For direct APK installation
- **Unknown Sources**: Users must enable installation from unknown sources
- **Storage Permission**: Required for APK download
- **Install Permission**: Required for APK installation

### User Experience:
- **Automatic Checks**: App checks for updates on startup
- **Manual Checks**: Users can check for updates manually
- **Progress Tracking**: Download progress is shown
- **Error Handling**: Clear error messages for issues

### Deployment Best Practices:
- **Test Thoroughly**: Test on multiple devices
- **Version Increment**: Always increment version numbers
- **Backup APK**: Keep previous versions as backup
- **Monitor Logs**: Watch for download issues
- **User Communication**: Inform users about updates

"@

# Save deployment guide
$deploymentGuide | Out-File -FilePath "docs/DIRECT_DOWNLOAD_GUIDE.md" -Encoding UTF8

Write-Host "✅ Deployment guide created: docs/DIRECT_DOWNLOAD_GUIDE.md" -ForegroundColor Green

# 4. Create test script
Write-Host "🧪 Creating test script..." -ForegroundColor Yellow

$testScript = @"
# Test Direct Download System

Write-Host "🧪 Testing Direct Download System..." -ForegroundColor Cyan

# Test download info endpoint
Write-Host "📡 Testing download info endpoint..." -ForegroundColor Yellow
try {
    `$response = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/download/android" -Method Get
    Write-Host "✅ Download info endpoint working:" -ForegroundColor Green
    Write-Host "   Version: `$(`$response.version)" -ForegroundColor White
    Write-Host "   Build Number: `$(`$response.build_number)" -ForegroundColor White
    Write-Host "   File Size: `$(`$response.file_size) bytes" -ForegroundColor White
    Write-Host "   Download URL: `$(`$response.download_url)" -ForegroundColor White
} catch {
    Write-Host "❌ Download info endpoint failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Test download status endpoint
Write-Host "📋 Testing download status endpoint..." -ForegroundColor Yellow
try {
    `$status = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/download/status" -Method Get
    Write-Host "✅ Download status endpoint working:" -ForegroundColor Green
    Write-Host "   Platform: `$(`$status.platform)" -ForegroundColor White
    Write-Host "   File Exists: `$(`$status.file_exists)" -ForegroundColor White
    Write-Host "   File Size: `$(`$status.file_size) bytes" -ForegroundColor White
    Write-Host "   Last Modified: `$(`$status.last_modified)" -ForegroundColor White
} catch {
    Write-Host "❌ Download status endpoint failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Test version check endpoint
Write-Host "🔍 Testing version check endpoint..." -ForegroundColor Yellow
try {
    `$version = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method Get
    Write-Host "✅ Version check endpoint working:" -ForegroundColor Green
    Write-Host "   Platform: `$(`$version.platform)" -ForegroundColor White
    Write-Host "   Current Version: `$(`$version.current_version)" -ForegroundColor White
    Write-Host "   Latest Version: `$(`$version.latest_version)" -ForegroundColor White
    Write-Host "   Update Available: `$(`$version.update_available)" -ForegroundColor White
    Write-Host "   Update Required: `$(`$version.update_required)" -ForegroundColor White
} catch {
    Write-Host "❌ Version check endpoint failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🎯 Direct Download System test completed!" -ForegroundColor Green
"@

# Save test script
$testScript | Out-File -FilePath "scripts/test-direct-download.ps1" -Encoding UTF8

Write-Host "✅ Test script created: scripts/test-direct-download.ps1" -ForegroundColor Green

# 5. Create deployment script
Write-Host "🚀 Creating deployment script..." -ForegroundColor Yellow

$deploymentScript = @"
# Deploy Direct Download System

Write-Host "🚀 Deploying Direct Download System..." -ForegroundColor Cyan

# 1. Build new APK
Write-Host "📱 Building new APK..." -ForegroundColor Yellow
cd sns_rooster
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api

# 2. Copy APK to backend
Write-Host "📦 Copying APK to backend..." -ForegroundColor Yellow
`$sourceApk = "build/app/outputs/flutter-apk/app-release.apk"
`$targetApk = "../rooster-backend/uploads/apk/sns-rooster.apk"

if (Test-Path `$sourceApk) {
    Copy-Item `$sourceApk `$targetApk -Force
    Write-Host "✅ APK copied to backend" -ForegroundColor Green
} else {
    Write-Host "❌ APK build failed" -ForegroundColor Red
    exit 1
}

# 3. Deploy backend changes
Write-Host "📡 Deploying backend changes..." -ForegroundColor Yellow
cd ../rooster-backend
git add .
git commit -m "Update APK for direct download"
git push origin main

Write-Host "✅ Backend deployed to Render" -ForegroundColor Green

# 4. Test the system
Write-Host "🧪 Testing direct download system..." -ForegroundColor Yellow
cd ../sns_rooster
./scripts/test-direct-download.ps1

Write-Host "🎉 Direct Download System deployed successfully!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Test the update system on Android devices" -ForegroundColor White
Write-Host "   2. Monitor download logs in Render dashboard" -ForegroundColor White
Write-Host "   3. Update version info when ready to release" -ForegroundColor White
"@

# Save deployment script
$deploymentScript | Out-File -FilePath "scripts/deploy-direct-download.ps1" -Encoding UTF8

Write-Host "✅ Deployment script created: scripts/deploy-direct-download.ps1" -ForegroundColor Green

Write-Host "🎉 Direct Download System setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review docs/DIRECT_DOWNLOAD_GUIDE.md" -ForegroundColor White
Write-Host "   2. Deploy backend changes to Render" -ForegroundColor White
Write-Host "   3. Test with scripts/test-direct-download.ps1" -ForegroundColor White
Write-Host "   4. Deploy APK with scripts/deploy-direct-download.ps1" -ForegroundColor White
Write-Host ""
Write-Host "📱 Your app now supports direct APK downloads without Google Play Store!" -ForegroundColor Green 