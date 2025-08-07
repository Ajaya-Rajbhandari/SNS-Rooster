# Manual APK Upload Guide

## 🎯 Why Manual Upload?

We use manual upload to GitHub Releases instead of Git LFS because:
- **No LFS Budget Issues** - Prevents deployment failures
- **Better User Experience** - Proper download pages with release notes
- **Multiple Download Sources** - GitHub, Play Store, and your server
- **No Repository Bloat** - Keeps Git repo fast and efficient

## 📋 Complete Release Workflow

### Step 1: Create Release
```powershell
.\scripts\simple-release.ps1 -Version "1.0.15" -BuildNumber "15" -ReleaseNotes "New features and bug fixes"
```

### Step 2: Push to GitHub
```bash
git push origin main --tags
```

### Step 3: Build APK
```bash
cd sns_rooster
flutter build apk --release
```

**APK Location:** `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Upload to GitHub Releases

1. **Go to GitHub Releases:**
   - Visit: https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases

2. **Edit the Release:**
   - Find your release (e.g., "v1.0.15")
   - Click the "Edit" button (pencil icon)

3. **Upload APK:**
   - Scroll down to "Attach binaries"
   - Drag & drop your APK file (`app-release.apk`)
   - Or click "Attach binaries" and select the file

4. **Update Release:**
   - Click "Update release" button

### Step 5: Test the Release

1. **Download APK:**
   - Go to the GitHub release page
   - Click "app-release.apk" to download

2. **Install on Test Device:**
   - Enable "Install from Unknown Sources"
   - Install the APK
   - Verify version shows correctly in app

## 🔗 Download Sources for Users

Users can download updates from multiple sources:

1. **GitHub Releases** (Primary)
   - Direct download with release notes
   - Example: https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest

2. **Google Play Store** (Official)
   - Automatic updates for Play Store users
   - Example: https://play.google.com/store/apps/details?id=com.snstech.sns_rooster

3. **Your Server** (Backup)
   - In-app update detection
   - Example: https://sns-rooster.onrender.com/api/app/download/android/file

## ⚠️ Important Notes

- **APK files are excluded from Git** to prevent LFS budget issues
- **Manual upload is required** - this prevents deployment failures
- **Multiple download sources** ensure users can always get updates
- **Test each release** before announcing to users

## 🚨 Troubleshooting

### If APK is too large for GitHub:
- GitHub has a 2GB file size limit
- Flutter APKs are typically under 100MB
- If larger, consider using Play Store or your server

### If release doesn't appear in app:
- Check that server version was updated correctly
- Verify the app version check endpoint
- Ensure APK was uploaded to the correct release

### If users can't download:
- Check GitHub release is public
- Verify download links work
- Test on different devices/browsers

## 📞 Support

If you encounter issues:
- Check the release logs
- Verify all steps were completed
- Test the download process
- Contact support if needed 