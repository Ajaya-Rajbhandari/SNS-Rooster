# Setup Update Alerts for SNS Rooster
# This script integrates the app update service into the main application

Write-Host "🔔 Setting up App Update Alert System..." -ForegroundColor Cyan

# 1. Install dependencies
Write-Host "📦 Installing required dependencies..." -ForegroundColor Yellow
flutter pub add package_info_plus url_launcher

# 2. Update pubspec.yaml
Write-Host "📝 Updating pubspec.yaml..." -ForegroundColor Yellow
flutter pub get

# 3. Create integration guide
Write-Host "📋 Creating integration guide..." -ForegroundColor Yellow

$integrationGuide = @"
# App Update Alert Integration Guide

## 🔔 How to Integrate Update Alerts

### 1. Add to Main App (main.dart)

Add this to your main.dart file:

```dart
import 'package:sns_rooster/services/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app
  runApp(MyApp());
  
  // Check for updates after app starts
  Future.delayed(Duration(seconds: 3), () {
    AppUpdateService.checkForUpdates(showAlert: true);
  });
}
```

### 2. Add Update Alert Widget

Add this widget to show update alerts:

```dart
class UpdateAlertOverlay extends StatelessWidget {
  final AppUpdateInfo? updateInfo;
  final VoidCallback? onDismiss;
  
  const UpdateAlertOverlay({
    Key? key,
    this.updateInfo,
    this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (updateInfo == null) return const SizedBox.shrink();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: UpdateAlertWidget(
        updateInfo: updateInfo!,
        onDismiss: onDismiss,
      ),
    );
  }
}
```

### 3. Add to Scaffold

Add the overlay to your main scaffold:

```dart
Scaffold(
  body: Stack(
    children: [
      // Your main content
      YourMainContent(),
      
      // Update alert overlay
      UpdateAlertOverlay(
        updateInfo: updateInfo,
        onDismiss: () {
          setState(() {
            updateInfo = null;
          });
        },
      ),
    ],
  ),
)
```

### 4. Manual Update Check

Add a button or menu item for manual update checks:

```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () async {
    final updateInfo = await AppUpdateService.forceUpdateCheck();
    if (updateInfo != null) {
      setState(() {
        this.updateInfo = updateInfo;
      });
    }
  },
)
```

## 🚀 Backend Setup

### 1. Deploy Backend Changes

The backend routes are already added. Deploy to Render:

```bash
cd rooster-backend
git add .
git commit -m "Add app version checking routes"
git push origin main
```

### 2. Test Version Check API

Test the endpoint:

```bash
curl https://sns-rooster.onrender.com/api/app/version/check
```

### 3. Update Version Information

To update version info (admin only):

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

## 📱 Platform-Specific URLs

Update these URLs in the service:

- **Android**: https://play.google.com/store/apps/details?id=com.snstech.sns_rooster
- **Web**: https://your-production-domain.com
- **iOS**: https://apps.apple.com/app/sns-rooster/id123456789

## 🔧 Configuration

### Update Check Frequency

The service checks for updates:
- On app startup (after 3 seconds)
- Every 24 hours (if app stays open)
- Manually when user requests

### Alert Types

1. **Regular Update**: Blue alert, user can dismiss
2. **Critical Update**: Red alert, user must update or exit app

### Version Comparison

The system compares:
- Major.Minor.Patch versions (e.g., 1.0.0)
- Build numbers for same version

## 🎯 Usage Examples

### Check for Updates
```dart
final updateInfo = await AppUpdateService.checkForUpdates();
if (updateInfo != null) {
  // Show update alert
  showUpdateDialog(updateInfo);
}
```

### Force Update Check
```dart
await AppUpdateService.forceUpdateCheck();
```

### Launch Update URL
```dart
AppUpdateService.launchUpdateUrl(updateInfo.downloadUrl);
```

## 🔒 Security Notes

- Version check endpoint is public (no authentication required)
- Version update endpoint should be protected (admin only)
- User agent detection helps identify platform
- Version comparison is done server-side for security

## 📊 Monitoring

Monitor update checks in backend logs:
- Successful checks
- Failed checks
- Update downloads
- User dismissals

"@

# Save integration guide
$integrationGuide | Out-File -FilePath "docs/APP_UPDATE_INTEGRATION.md" -Encoding UTF8

Write-Host "✅ Integration guide created: docs/APP_UPDATE_INTEGRATION.md" -ForegroundColor Green

# 4. Create test script
Write-Host "🧪 Creating test script..." -ForegroundColor Yellow

$testScript = @"
# Test App Update System

Write-Host "🧪 Testing App Update System..." -ForegroundColor Cyan

# Test backend endpoint
Write-Host "📡 Testing backend endpoint..." -ForegroundColor Yellow
try {
    `$response = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method Get
    Write-Host "✅ Backend endpoint working:" -ForegroundColor Green
    Write-Host "   Platform: `$(`$response.platform)" -ForegroundColor White
    Write-Host "   Latest Version: `$(`$response.latest_version)" -ForegroundColor White
    Write-Host "   Update Available: `$(`$response.update_available)" -ForegroundColor White
} catch {
    Write-Host "❌ Backend endpoint failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Test version info endpoint
Write-Host "📋 Testing version info endpoint..." -ForegroundColor Yellow
try {
    `$info = Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/info" -Method Get
    Write-Host "✅ Version info endpoint working:" -ForegroundColor Green
    Write-Host "   Android: `$(`$info.platforms.android.latest_version)" -ForegroundColor White
    Write-Host "   Web: `$(`$info.platforms.web.latest_version)" -ForegroundColor White
    Write-Host "   iOS: `$(`$info.platforms.ios.latest_version)" -ForegroundColor White
} catch {
    Write-Host "❌ Version info endpoint failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

Write-Host "🎯 Test completed!" -ForegroundColor Green
"@

# Save test script
$testScript | Out-File -FilePath "scripts/test-update-system.ps1" -Encoding UTF8

Write-Host "✅ Test script created: scripts/test-update-system.ps1" -ForegroundColor Green

# 5. Create deployment script
Write-Host "🚀 Creating deployment script..." -ForegroundColor Yellow

$deploymentScript = @"
# Deploy App Update System

Write-Host "🚀 Deploying App Update System..." -ForegroundColor Cyan

# 1. Deploy backend changes
Write-Host "📡 Deploying backend changes..." -ForegroundColor Yellow
cd rooster-backend
git add .
git commit -m "Add app version checking and update alerts"
git push origin main

Write-Host "✅ Backend deployed to Render" -ForegroundColor Green

# 2. Build production apps
Write-Host "📱 Building production apps..." -ForegroundColor Yellow
cd ../sns_rooster

# Build web app
flutter build web --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api

# Build Android app
flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=API_URL=https://sns-rooster.onrender.com/api

Write-Host "✅ Production builds created" -ForegroundColor Green

# 3. Test update system
Write-Host "🧪 Testing update system..." -ForegroundColor Yellow
./scripts/test-update-system.ps1

Write-Host "🎉 App Update System deployed successfully!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Deploy web app to your hosting service" -ForegroundColor White
Write-Host "   2. Upload Android APK to Google Play Store" -ForegroundColor White
Write-Host "   3. Update version info via admin panel" -ForegroundColor White
"@

# Save deployment script
$deploymentScript | Out-File -FilePath "scripts/deploy-update-system.ps1" -Encoding UTF8

Write-Host "✅ Deployment script created: scripts/deploy-update-system.ps1" -ForegroundColor Green

Write-Host "🎉 App Update Alert System setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review docs/APP_UPDATE_INTEGRATION.md" -ForegroundColor White
Write-Host "   2. Integrate update service into your main app" -ForegroundColor White
Write-Host "   3. Test with scripts/test-update-system.ps1" -ForegroundColor White
Write-Host "   4. Deploy with scripts/deploy-update-system.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🔔 Your app will now automatically check for updates and alert users!" -ForegroundColor Green 