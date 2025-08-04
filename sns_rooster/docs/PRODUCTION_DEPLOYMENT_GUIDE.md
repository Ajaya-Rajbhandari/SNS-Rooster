# Production Deployment Guide for SNS Rooster

## 🎉 Current Status: Ready for Production

Both web and Android apps are working perfectly with real Google Maps integration.

## 🔧 Pre-Deployment Checklist

### ✅ Completed
- [x] Google Maps APIs enabled
- [x] API key configured and working
- [x] Web app showing real maps
- [x] Android app showing real maps
- [x] Environment configuration ready

### 🔒 Security Configuration Required

#### 1. Google Cloud Console API Key Security

**Current API Key**: `AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc`

**Required Changes for Production:**

1. **Go to**: https://console.cloud.google.com/apis/credentials
2. **Click on your API key**
3. **Set Application Restrictions**:
   - For **Web**: Add your production domain (e.g., `https://yourdomain.com/*`)
   - For **Android**: Add your app package name and SHA-1 fingerprint
   - For **iOS**: Add your app bundle ID and SHA-1 fingerprint

4. **API Restrictions**: Keep enabled with these APIs:
   - Maps JavaScript API
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
   - Geolocation API

#### 2. Enable Billing

1. **Go to**: https://console.cloud.google.com/billing
2. **Enable billing** for your project
3. **Set up budget alerts** to avoid unexpected charges

## 🚀 Production Build Commands

### Web App Production Build

```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://sns-rooster.onrender.com/api \
  --dart-define=APP_VERSION=1.0.0
```

### Android App Production Build

#### For APK (Direct Distribution)
```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://sns-rooster.onrender.com/api \
  --dart-define=APP_VERSION=1.0.0
```

#### For Google Play Store (AAB)
```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=https://sns-rooster.onrender.com/api \
  --dart-define=APP_VERSION=1.0.0
```

## 🌐 Web App Deployment

### Build Output
- **Location**: `build/web/`
- **Files**: Optimized HTML, CSS, JS, and assets

### Deployment Options

#### 1. Firebase Hosting (Recommended)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase
firebase init hosting

# Deploy
firebase deploy
```

#### 2. Netlify
- Drag and drop `build/web/` folder to Netlify
- Configure custom domain and SSL

#### 3. Vercel
- Connect GitHub repository
- Set build command: `flutter build web`
- Set output directory: `build/web`

### Custom Domain Configuration
1. **Add domain** to your hosting service
2. **Update Google Cloud Console** API key restrictions
3. **Configure SSL certificate**
4. **Update DNS records**

## 📱 Android App Deployment

### Google Play Store Deployment

1. **Create Google Play Console Account**
2. **Create New App**
3. **Upload AAB file** from `build/app/outputs/bundle/release/`
4. **Configure App Signing**
5. **Add App Content** (screenshots, descriptions)
6. **Set up Release Track** (Internal Testing → Alpha → Beta → Production)

### Direct APK Distribution
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Distribution**: Email, file sharing, or direct download

## 🔍 Post-Deployment Verification

### Web App Testing
- [ ] Maps load correctly on production domain
- [ ] API calls work with production backend
- [ ] SSL certificate is valid
- [ ] Performance is acceptable

### Android App Testing
- [ ] Maps load correctly on production devices
- [ ] API calls work with production backend
- [ ] App signing is correct
- [ ] No debug information is exposed

## 📊 Monitoring and Analytics

### Google Analytics
1. **Set up Google Analytics** for web app
2. **Configure Firebase Analytics** for mobile apps
3. **Track user engagement** and map usage

### Error Monitoring
1. **Set up Sentry** or similar error tracking
2. **Monitor API errors** and map loading issues
3. **Track performance metrics**

## 🔄 Environment Variables

### Production Environment
```bash
ENVIRONMENT=production
API_URL=https://sns-rooster.onrender.com/api
APP_VERSION=1.0.0
```

### Staging Environment (Optional)
```bash
ENVIRONMENT=staging
API_URL=https://sns-rooster-staging.onrender.com/api
APP_VERSION=1.0.0-beta
```

## 🚨 Important Security Notes

1. **Never commit API keys** to version control
2. **Use environment variables** for sensitive data
3. **Enable API key restrictions** for production domains
4. **Monitor API usage** to prevent abuse
5. **Set up billing alerts** in Google Cloud Console

## 📞 Support and Troubleshooting

### Common Issues
1. **Maps not loading**: Check API key restrictions
2. **API errors**: Verify production backend is running
3. **Performance issues**: Optimize images and assets
4. **SSL errors**: Ensure valid SSL certificate

### Resources
- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Google Cloud Console Help](https://cloud.google.com/apis/docs)

## ✅ Final Checklist

- [ ] Google Cloud Console API key secured
- [ ] Production builds created
- [ ] Web app deployed and tested
- [ ] Android app uploaded to Play Store
- [ ] Custom domain configured
- [ ] SSL certificates installed
- [ ] Monitoring set up
- [ ] Documentation updated

---

**🎉 Congratulations! Your SNS Rooster app is now ready for production!** 