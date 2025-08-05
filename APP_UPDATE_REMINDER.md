# 🚨 APP UPDATE WORKFLOW REMINDER

## ⚠️ CRITICAL: READ BEFORE ADDING NEW FEATURES

Every time you add new features to the Flutter app, you **MUST** follow the app update workflow to ensure the update system works correctly.

---

## 🚀 Quick Deployment (Recommended)

```powershell
# From sns_rooster directory
.\scripts\deploy-app-update.ps1 -NewVersion "1.0.4" -NewBuildNumber "5" -FeatureDescription "your new feature"
```

This single command will:
- ✅ Update version in pubspec.yaml
- ✅ Build new APK
- ✅ Update backend configuration
- ✅ Deploy APK to backend
- ✅ Deploy backend changes
- ✅ Test the deployment
- ✅ Install new APK

---

## 📋 Manual Steps (if needed)

### 1. Update Version
```yaml
# In sns_rooster/pubspec.yaml
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
cd ..\sns_rooster
flutter install --release
```

---

## ⚠️ CRITICAL RULES

1. **Always increment both version AND build number**
2. **Backend expects NEXT version, not current version**
3. **Deploy APK first, then backend config**
4. **Test the complete flow before releasing**

---

## 🔍 Why This Matters

If you don't follow this workflow:
- ❌ Users won't get update notifications
- ❌ Update system will break
- ❌ Users will be stuck on old versions
- ❌ You'll have to manually distribute APKs

---

## 📚 Documentation

- **Complete Workflow**: `docs/APP_UPDATE_WORKFLOW.md`
- **Quick Reference**: `docs/QUICK_UPDATE_GUIDE.md`
- **System Summary**: `docs/UPDATE_SYSTEM_SUMMARY.md`

---

## 🆘 Need Help?

1. Check the troubleshooting section in `docs/APP_UPDATE_WORKFLOW.md`
2. Use the debugging scripts in `sns_rooster/scripts/`
3. Test with the provided verification commands

---

**Remember**: This workflow ensures users always get the correct version when they update their app! 🎯 