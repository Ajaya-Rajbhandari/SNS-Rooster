# Quick App Update Guide

## 🚀 One-Command Deployment

Use the automated script for quick deployments:

```powershell
# From sns_rooster directory
.\scripts\deploy-app-update.ps1 -NewVersion "1.0.4" -NewBuildNumber "5" -FeatureDescription "new feature description"
```

## 📋 Manual Steps (if needed)

### 1. Update Version
```yaml
# In pubspec.yaml
version: 1.0.4+5  # Increment both version and build number
```

### 2. Build APK
```bash
flutter build apk --release
```

### 3. Update Backend (CRITICAL)
```javascript
// In rooster-backend/routes/appVersionRoutes.js
android: {
  latest_version: '1.0.5',        // NEXT version (not 1.0.4)
  latest_build_number: '6',        // NEXT build number
  // ... rest of config
}
```

### 4. Deploy
```bash
# Copy APK
copy "build\app\outputs\flutter-apk\app-release.apk" "..\rooster-backend\downloads\sns-rooster.apk"

# Deploy to backend
cd ..\rooster-backend
git add downloads/sns-rooster.apk
git commit -m "Deploy version 1.0.4 APK"
git push origin main

git add routes/appVersionRoutes.js
git commit -m "Update backend to expect v1.0.5"
git push origin main
```

### 5. Test
```bash
# Test backend
$headers = @{'User-Agent'='SNS-Rooster/1.0.3 (Android)'}
Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers

# Install new APK
cd ..\sns_rooster
flutter install --release
```

## ⚠️ Critical Rules

1. **Always increment both version AND build number**
2. **Backend expects NEXT version, not current version**
3. **Deploy APK first, then backend config**
4. **Test the complete flow before releasing**

## 🔍 Troubleshooting

### Update Alert Keeps Showing
- Check backend expects NEXT version
- Verify APK file is correct version
- Ensure deployment completed

### Wrong Version Downloaded
- Verify APK in backend is new version
- Check deployment status on Render
- Test download endpoint directly

### Version Display Not Working
- Check `package_info_plus` dependency
- Verify `_loadAppVersion()` is called
- Check for linter errors

## 📞 Quick Commands

```bash
# Check current backend status
$headers = @{'User-Agent'='SNS-Rooster/1.0.3 (Android)'}
Invoke-RestMethod -Uri "https://sns-rooster.onrender.com/api/app/version/check" -Method GET -Headers $headers

# Test download endpoint
Invoke-WebRequest -Uri "https://sns-rooster.onrender.com/api/app/download/android/file" -OutFile "test.apk"

# Build and install quickly
flutter build apk --release && flutter install --release
```

## 📚 Full Documentation

For detailed workflow, see: `docs/APP_UPDATE_WORKFLOW.md` 