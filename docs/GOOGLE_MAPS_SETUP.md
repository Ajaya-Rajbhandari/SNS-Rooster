# 🗺️ Google Maps API Setup Guide

This guide will help you set up Google Maps API for the SNS Rooster app to enable real map functionality instead of the fallback custom map.

## 📋 Prerequisites

- Google account with access to Google Cloud Console
- Flutter project with location management features
- Android/iOS development environment

## 🔑 Step 1: Get Google Maps API Key

### 1.1 Access Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Select your project: `sns-rooster-8cca5` (or create new)

### 1.2 Enable Required APIs
Go to **APIs & Services** → **Library** and enable:

- ✅ **Maps SDK for Android**
- ✅ **Maps SDK for iOS** 
- ✅ **Places API** (for address lookup)
- ✅ **Geocoding API** (for address conversion)

### 1.3 Create API Key
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **API Key**
3. Copy the generated key (should be ~39 characters starting with "AIza")

## 🔐 Step 2: Configure API Key Restrictions

### 2.1 Get SHA-1 Certificate Fingerprint

**Option A: Use PowerShell Script (Recommended)**
```powershell
cd sns_rooster
.\scripts\get-sha1-fingerprint.ps1
```

**Option B: Manual Command**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2.2 Set API Key Restrictions
1. Click on your created API key in Google Cloud Console
2. **Application restrictions**:
   - Select **Android apps**
   - Package name: `com.snstech.sns_rooster`
   - SHA-1: (from step 2.1)
3. **API restrictions**:
   - Select **Restrict key**
   - Choose: Maps SDK for Android, Maps SDK for iOS, Places API, Geocoding API

## 🔧 Step 3: Update Configuration Files

### 3.1 Automated Update (Recommended)
```powershell
cd sns_rooster
.\scripts\update-google-maps-api-key.ps1 -ApiKey "YOUR_API_KEY_HERE"
```

### 3.2 Manual Update

#### Android (AndroidManifest.xml)
```xml
<!-- Update this line in android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

#### iOS (Info.plist)
```xml
<!-- Add this before </dict> in ios/Runner/Info.plist -->
<key>GMSApiKey</key>
<string>YOUR_API_KEY_HERE</string>
```

#### Web (index.html)
```html
<!-- Add this before </head> in web/index.html -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=places"></script>
```

## 🧪 Step 4: Test the Implementation

### 4.1 Clean and Rebuild
```bash
flutter clean
flutter pub get
```

### 4.2 Run the App
```bash
flutter run
```

### 4.3 Test Location Management
1. Navigate to **Admin Dashboard** → **Location Management**
2. You should see **real Google Maps** instead of fallback custom map
3. Test location creation and editing
4. Verify map markers and geofence circles

## 🔍 Troubleshooting

### Issue: Maps Still Show Fallback
**Possible Causes:**
- API key not properly configured
- APIs not enabled in Google Cloud Console
- SHA-1 fingerprint mismatch
- Network connectivity issues

**Solutions:**
1. Verify API key format (39 characters, starts with "AIza")
2. Check Google Cloud Console for enabled APIs
3. Verify SHA-1 fingerprint matches your debug keystore
4. Check network connectivity and firewall settings

### Issue: "Maps API key not found"
**Solution:**
- Ensure API key is properly added to AndroidManifest.xml
- Check that the key has proper restrictions set
- Verify the package name matches your app

### Issue: iOS Maps Not Working
**Solution:**
- Ensure GMSApiKey is added to Info.plist
- Check that Maps SDK for iOS is enabled
- Verify iOS bundle identifier matches restrictions

## 📱 Platform-Specific Notes

### Android
- Requires SHA-1 certificate fingerprint
- Debug and release keystores need separate fingerprints
- API key restrictions must include package name and SHA-1

### iOS
- Requires bundle identifier in API key restrictions
- GMSApiKey must be added to Info.plist
- Simulator and device may need different configurations

### Web
- Requires domain restrictions in API key settings
- JavaScript Maps API must be enabled
- CORS settings may need adjustment

## 🔒 Security Best Practices

1. **Restrict API Key**: Always set application and API restrictions
2. **Monitor Usage**: Check Google Cloud Console for usage metrics
3. **Rotate Keys**: Regularly update API keys for security
4. **Environment Separation**: Use different keys for dev/staging/prod

## 📊 Usage Monitoring

Monitor your API usage in Google Cloud Console:
- **APIs & Services** → **Dashboard**
- Check request counts and error rates
- Set up billing alerts for cost control

## 🎯 Success Criteria

✅ Real Google Maps display in location management  
✅ Map markers show correctly  
✅ Geofence circles render properly  
✅ Address lookup works  
✅ Location picker functions correctly  
✅ No fallback custom map visible  

## 🆘 Support

If you encounter issues:
1. Check Google Cloud Console for API errors
2. Verify all configuration files are updated
3. Test with a simple Google Maps example
4. Check Flutter and platform-specific logs 