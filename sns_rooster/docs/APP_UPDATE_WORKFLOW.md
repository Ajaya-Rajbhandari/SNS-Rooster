# App Update Workflow Documentation

## Overview
This document outlines the complete workflow for deploying app updates with the integrated update notification system. This process must be followed every time new features are added to the app.

## Prerequisites
- Flutter development environment set up
- Access to the backend repository
- Android device for testing
- Git access to both frontend and backend repositories

## Workflow Steps

### 1. Development Phase
```bash
# Make your feature changes in the Flutter app
# Test your changes thoroughly
# Commit your changes to the frontend repository
git add .
git commit -m "Add new feature: [description]"
git push origin main
```

### 2. Version Update
**CRITICAL**: Before building the new APK, you MUST update the version in `pubspec.yaml`:

```yaml
# In sns_rooster/pubspec.yaml
version: 1.0.4+5  # Increment both version and build number
```

**Version Numbering Rules:**
- **Major.Minor.Patch** format (e.g., 1.0.4)
- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes
- **Build Number**: Always increment (e.g., +5)

### 3. Build New APK
```bash
cd sns_rooster
flutter build apk --release
```

### 4. Update Backend Version Configuration
**CRITICAL**: Update the backend to expect the NEXT version (not the current one):

```javascript
// In rooster-backend/routes/appVersionRoutes.js
const APP_VERSIONS = {
  android: {
    latest_version: '1.0.5',        // NEXT version (not 1.0.4)
    latest_build_number: '6',        // NEXT build number
    update_required: false,
    update_message: 'A new version of SNS Rooster is available with improved features and bug fixes!',
    download_url: 'https://sns-rooster.onrender.com/api/app/download/android/file',
    min_required_version: '1.0.0',
    min_required_build: '1',
  },
  // ... other platforms
};
```

**Why NEXT version?**
- Current app (1.0.4) checks for updates
- Backend says "1.0.5 is available"
- User clicks update → downloads 1.0.4 (current build)
- After installing 1.0.4, no more update alerts

### 5. Deploy APK to Backend
```bash
# Copy the new APK to backend downloads folder
cd ..\rooster-backend
copy "..\sns_rooster\build\app\outputs\flutter-apk\app-release.apk" "downloads\sns-rooster.apk"

# Commit and push the APK
git add downloads/sns-rooster.apk
git commit -m "Deploy version 1.0.4 APK with [feature description]"
git push origin main
```

### 6. Deploy Backend Changes
```bash
# Commit and push the version configuration changes
git add routes/appVersionRoutes.js
git commit -m "Update backend to expect v1.0.5 for next update cycle"
git push origin main
```

### 7. Testing the Update Flow

#### Test Current App (v1.0.3)
```bash
# Test that current app detects the update
$headers = @{'User-Agent'='SNS-Rooster/1.0.3 (Android)'}
Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers
```

**Expected Response:**
```json
{
  "current_version": "1.0.0",
  "latest_version": "1.0.4",
  "update_available": true,
  "download_url": "https://sns-rooster.onrender.com/api/app/download/android/file"
}
```

#### Test Login Screen Features
1. Open the app (current version)
2. Navigate to login screen
3. Verify version display shows current version
4. Verify update notification appears
5. Test the update button functionality

### 8. Install and Test New Version
```bash
# Install the new APK on test device
cd ..\sns_rooster
flutter install --release
```

**Test New App (v1.0.4):**
1. Open the updated app
2. Verify version display shows "Version 1.0.4 (Build 5)"
3. Verify NO update notification appears (since backend expects 1.0.5)
4. Test all new features

## Complete Example Workflow

### Scenario: Adding Login Screen Version Display

#### Step 1: Development
```bash
# Make changes to login_screen.dart
# Add version display functionality
git add .
git commit -m "Add version display and update notification to login screen"
git push origin main
```

#### Step 2: Version Update
```yaml
# pubspec.yaml
version: 1.0.3+4  # Increment from 1.0.2+3
```

#### Step 3: Build APK
```bash
flutter build apk --release
```

#### Step 4: Update Backend Configuration
```javascript
// appVersionRoutes.js
android: {
  latest_version: '1.0.4',  // NEXT version
  latest_build_number: '5',  // NEXT build number
  // ... other config
}
```

#### Step 5: Deploy
```bash
# Deploy APK
cd ..\rooster-backend
copy "..\sns_rooster\build\app\outputs\flutter-apk\app-release.apk" "downloads\sns-rooster.apk"
git add downloads/sns-rooster.apk
git commit -m "Deploy version 1.0.3 APK with login screen version display"
git push origin main

# Deploy backend config
git add routes/appVersionRoutes.js
git commit -m "Update backend to expect v1.0.4 for next update cycle"
git push origin main
```

#### Step 6: Test
```bash
# Test current app (v1.0.2) detects update to v1.0.3
# Install and test new app (v1.0.3)
# Verify login screen shows version and update notification
```

## Troubleshooting

### Common Issues

#### 1. Update Alert Keeps Showing
**Problem**: App keeps showing update alert even after updating
**Solution**: 
- Check that backend expects NEXT version, not current version
- Verify APK file in backend is the correct version
- Ensure version numbers match between `pubspec.yaml` and backend config

#### 2. Wrong Version Downloaded
**Problem**: Update downloads old version instead of new version
**Solution**:
- Verify the APK file in `rooster-backend/downloads/sns-rooster.apk` is the new version
- Check that you copied the correct APK file
- Ensure backend deployment completed successfully

#### 3. Version Display Not Working
**Problem**: Login screen doesn't show version information
**Solution**:
- Check that `package_info_plus` dependency is added
- Verify `_loadAppVersion()` method is called in `initState()`
- Check for any linter errors in the login screen

### Verification Commands

#### Check Backend Status
```bash
$headers = @{'User-Agent'='SNS-Rooster/1.0.3 (Android)'}
Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers
```

#### Test Download Endpoint
```bash
Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/download/android/file" -OutFile "test-download.apk"
```

#### Check APK Version
```bash
# Install APK and check version in app settings
# Or use Android Studio to inspect APK contents
```

## Best Practices

### 1. Version Management
- Always increment both version and build number
- Use semantic versioning (Major.Minor.Patch)
- Keep a changelog of what each version includes

### 2. Testing
- Test the complete update flow before deploying
- Verify both current and new app versions work correctly
- Test on multiple devices if possible

### 3. Documentation
- Update this document when workflow changes
- Document any new features or changes
- Keep track of version history

### 4. Deployment
- Deploy APK first, then backend configuration
- Wait for Render deployment to complete before testing
- Test immediately after deployment

## Version History

| Version | Build | Features | Date |
|---------|-------|----------|------|
| 1.0.0 | 1 | Initial release | - |
| 1.0.1 | 2 | Google Maps integration | - |
| 1.0.2 | 3 | App update system | - |
| 1.0.3 | 4 | Login screen version display | 2025-08-03 |

## Support

If you encounter issues with this workflow:
1. Check this documentation first
2. Review the troubleshooting section
3. Check backend logs on Render
4. Verify all version numbers are consistent
5. Test the complete flow step by step

---

**Remember**: This workflow ensures that users always get the correct version when they update their app, and the update notification system works seamlessly. 