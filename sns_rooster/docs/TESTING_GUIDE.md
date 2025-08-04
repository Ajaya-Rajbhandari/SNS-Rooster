# App Update and Direct Download System - Testing Guide

## Overview
This guide covers testing the complete app update alert system and direct APK download functionality for the SNS Rooster app.

## System Components

### 1. App Update Service
- **File**: `lib/services/app_update_service.dart`
- **Purpose**: Checks for app updates and shows alerts
- **Features**: Version comparison, update alerts, store/direct download URLs

### 2. Direct Download Service
- **File**: `lib/services/direct_download_service.dart`
- **Purpose**: Handles direct APK downloads for Android
- **Features**: Download progress, installation, permissions

### 3. Backend API Endpoints
- **Version Check**: `GET /api/app/version/check`
- **Download Info**: `GET /api/app/download/android`
- **File Download**: `GET /api/app/download/android/file`
- **Status**: `GET /api/app/download/status`

## Testing Checklist

### ✅ Backend API Testing

#### 1. Version Check Endpoint
```bash
curl https://sns-rooster.onrender.com/api/app/version/check
```
**Expected Response**:
```json
{
  "update_available": false,
  "current_version": "1.0.0",
  "latest_version": "1.0.0",
  "update_required": false,
  "message": "App is up to date",
  "download_url": "https://play.google.com/store/apps/details?id=com.snstech.sns_rooster"
}
```

#### 2. Download Info Endpoint
```bash
curl https://sns-rooster.onrender.com/api/app/download/android
```
**Expected Response**:
```json
{
  "version": "1.0.0",
  "build_number": "1",
  "download_url": "https://your-server.com/downloads/sns-rooster.apk",
  "file_size": 0,
  "checksum": "",
  "timestamp": "2025-08-03T07:42:25.973Z"
}
```

#### 3. Status Endpoint
```bash
curl https://sns-rooster.onrender.com/api/app/download/status
```
**Expected Response**:
```json
{
  "platform": "android",
  "version": "1.0.0",
  "build_number": "1",
  "file_exists": false,
  "file_size": 0,
  "last_modified": null,
  "download_url": "https://your-server.com/downloads/sns-rooster.apk"
}
```

### ✅ Frontend Testing

#### 1. App Update Service
**Test Cases**:
- [ ] App starts and checks for updates automatically
- [ ] Update alert shows when update is available
- [ ] Update alert shows when critical update is required
- [ ] Update alert can be dismissed (for non-critical updates)
- [ ] Update button launches correct URL

**Manual Testing**:
1. Open the app
2. Wait 3 seconds for update check
3. Check console for update service logs
4. Verify no update alert shows (current version matches server)

#### 2. Direct Download Service
**Test Cases**:
- [ ] Download progress shows correctly
- [ ] Permissions are requested properly
- [ ] APK downloads successfully
- [ ] Installation prompts correctly
- [ ] Error handling works for failed downloads

**Manual Testing**:
1. Trigger a direct download (when APK is available)
2. Check download progress
3. Verify permissions are requested
4. Test installation flow

### ✅ Integration Testing

#### 1. End-to-End Update Flow
**Test Scenario**: New version available
1. Update version info in backend (`/api/app/version/update`)
2. Restart the app
3. Verify update alert appears
4. Test update button functionality

#### 2. Direct Download Flow
**Test Scenario**: APK available for download
1. Upload APK to backend
2. Update download URL in backend
3. Test download endpoint
4. Test file download endpoint
5. Test on Android device

## Testing Scripts

### 1. Test Update System
```bash
./scripts/test-update-system.ps1
```

### 2. Test Direct Download
```bash
./scripts/test-direct-download.ps1
```

### 3. Build and Deploy APK
```bash
./scripts/build-and-deploy-apk.ps1
```

## Manual Testing Steps

### Step 1: Test Backend Endpoints
```bash
# Test version check
curl https://sns-rooster.onrender.com/api/app/version/check

# Test download info
curl https://sns-rooster.onrender.com/api/app/download/android

# Test status
curl https://sns-rooster.onrender.com/api/app/download/status
```

### Step 2: Test Frontend Integration
1. **Start the app**: `flutter run -d chrome` (web) or `flutter run` (Android)
2. **Check console logs** for update service activity
3. **Verify no update alerts** show (current version matches server)
4. **Test manual update check** (if implemented in UI)

### Step 3: Test Update Scenario
1. **Update backend version**:
   ```bash
   curl -X POST https://sns-rooster.onrender.com/api/app/version/update \
     -H "Content-Type: application/json" \
     -d '{"platform":"android","latest_version":"1.1.0","update_required":true}'
   ```
2. **Restart the app**
3. **Verify update alert appears**

### Step 4: Test Direct Download
1. **Build APK**: `flutter build apk --release`
2. **Upload to backend**: Copy APK to `rooster-backend/uploads/apk/`
3. **Update download URL** in backend
4. **Deploy backend changes**
5. **Test download endpoints**
6. **Test on Android device**

## Common Issues and Solutions

### Issue 1: 404 Errors on Backend Endpoints
**Cause**: Routes not deployed or not registered
**Solution**: 
1. Check if routes are imported in `app.js`
2. Verify backend deployment on Render
3. Check server logs for errors

### Issue 2: Update Alert Not Showing
**Cause**: Version comparison logic or timing
**Solution**:
1. Check console logs for update service
2. Verify version comparison logic
3. Check if update check is called in `main.dart`

### Issue 3: Direct Download Fails
**Cause**: APK file not uploaded or URL incorrect
**Solution**:
1. Verify APK exists on server
2. Check download URL configuration
3. Test file download endpoint directly

### Issue 4: Permission Errors on Android
**Cause**: Missing permissions in `AndroidManifest.xml`
**Solution**:
1. Add required permissions:
   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
   ```

## Performance Testing

### 1. Update Check Performance
- **Target**: < 2 seconds for update check
- **Test**: Measure time from app start to update check completion

### 2. Download Performance
- **Target**: Show progress updates every 1-2 seconds
- **Test**: Download large APK and monitor progress updates

### 3. Memory Usage
- **Target**: No memory leaks during download
- **Test**: Monitor memory usage during large file downloads

## Security Testing

### 1. API Security
- [ ] Version check endpoint is public (OK)
- [ ] Download endpoints are public (OK)
- [ ] Upload endpoint requires authentication (if implemented)

### 2. File Security
- [ ] APK file is served with correct headers
- [ ] No sensitive information in APK metadata
- [ ] Checksum verification works

### 3. URL Security
- [ ] Download URLs are HTTPS
- [ ] No hardcoded credentials in URLs
- [ ] URLs are validated before use

## Browser Compatibility (Web)

### Tested Browsers
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

### Mobile Browsers
- [ ] Chrome Mobile
- [ ] Safari Mobile
- [ ] Samsung Internet

## Android Device Testing

### Tested Devices
- [ ] Physical Android device
- [ ] Android emulator
- [ ] Different Android versions (API 21+)

### Test Scenarios
- [ ] App update from Play Store
- [ ] Direct APK download
- [ ] Permission handling
- [ ] Installation flow

## Reporting Issues

When reporting issues, include:
1. **Platform**: Web/Android/iOS
2. **Version**: App version and build number
3. **Steps**: Detailed steps to reproduce
4. **Expected**: What should happen
5. **Actual**: What actually happens
6. **Logs**: Console logs and error messages
7. **Screenshots**: If applicable

## Success Criteria

The system is working correctly when:
- [ ] Backend endpoints return correct responses
- [ ] App checks for updates on startup
- [ ] Update alerts show when updates are available
- [ ] Direct download works on Android devices
- [ ] No errors in console logs
- [ ] All test cases pass
- [ ] Performance targets are met
- [ ] Security requirements are satisfied 