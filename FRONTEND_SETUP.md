# 🔐 FRONTEND ENVIRONMENT SETUP GUIDE

## Overview
This guide explains how to set up the Flutter frontend with secure environment variables.

## 🚨 SECURITY NOTES

1. **NEVER hardcode API keys in Flutter code**
2. **ALWAYS use String.fromEnvironment() for sensitive data**
3. **NEVER commit environment variables to version control**
4. **ALWAYS validate configuration before building**

## 📱 FLUTTER ENVIRONMENT VARIABLES

### Required Environment Variables

```bash
# API Configuration
API_URL=https://your-backend-domain.com/api

# Firebase Configuration
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_MESSAGING_SENDER_ID=your-messaging-sender-id
FIREBASE_APP_ID=your-firebase-app-id

# Google Maps Configuration
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# App Configuration
ENVIRONMENT=production
APP_NAME=SNS HR
APP_VERSION=1.0.0
```

## 🔧 SETUP STEPS

### Step 1: Set Environment Variables

#### Windows (PowerShell):
```powershell
$env:API_URL="https://your-backend-domain.com/api"
$env:FIREBASE_API_KEY="your-firebase-api-key"
$env:FIREBASE_PROJECT_ID="your-firebase-project-id"
$env:FIREBASE_MESSAGING_SENDER_ID="your-messaging-sender-id"
$env:FIREBASE_APP_ID="your-firebase-app-id"
$env:GOOGLE_MAPS_API_KEY="your-google-maps-api-key"
$env:ENVIRONMENT="production"
$env:APP_NAME="SNS HR"
$env:APP_VERSION="1.0.0"
```

#### Linux/macOS:
```bash
export API_URL="https://your-backend-domain.com/api"
export FIREBASE_API_KEY="your-firebase-api-key"
export FIREBASE_PROJECT_ID="your-firebase-project-id"
export FIREBASE_MESSAGING_SENDER_ID="your-messaging-sender-id"
export FIREBASE_APP_ID="your-firebase-app-id"
export GOOGLE_MAPS_API_KEY="your-google-maps-api-key"
export ENVIRONMENT="production"
export APP_NAME="SNS HR"
export APP_VERSION="1.0.0"
```

### Step 2: Build the App

#### Using Build Scripts:

**Windows:**
```powershell
cd sns_rooster
.\scripts\build-web.ps1
```

**Linux/macOS:**
```bash
cd sns_rooster
chmod +x scripts/build-web.sh
./scripts/build-web.sh
```

#### Manual Build:
```bash
cd sns_rooster
flutter build web \
  --dart-define=API_URL="$API_URL" \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=APP_NAME="$APP_NAME" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --release
```

### Step 3: Run Development Mode

```bash
cd sns_rooster
flutter run -d chrome \
  --dart-define=API_URL="http://localhost:5000/api" \
  --dart-define=FIREBASE_API_KEY="your-dev-firebase-key" \
  --dart-define=GOOGLE_MAPS_API_KEY="your-dev-google-maps-key" \
  --dart-define=ENVIRONMENT="development"
```

## 🔍 CONFIGURATION VALIDATION

### Check Configuration in Code:

```dart
import 'package:sns_rooster/config/secure_config.dart';

void main() {
  // Validate configuration before starting the app
  if (!SecureConfig.validateConfiguration()) {
    print('❌ Configuration validation failed!');
    return;
  }
  
  // Print configuration info (development only)
  if (SecureConfig.isDevelopment) {
    print('Configuration: ${SecureConfig.getConfigurationInfo()}');
  }
  
  runApp(MyApp());
}
```

### Test Configuration:

```dart
// Test API connection
final apiUrl = SecureConfig.apiUrl;
print('API URL: $apiUrl');

// Test Firebase configuration
final firebaseConfig = SecureConfig.getFirebaseConfig();
print('Firebase Project ID: ${firebaseConfig['projectId']}');

// Test Google Maps
final mapsKey = SecureConfig.googleMapsApiKey;
print('Google Maps API Key set: ${mapsKey.isNotEmpty}');
```

## 🛡️ SECURITY BEST PRACTICES

### 1. **Environment Separation**
- Use different API keys for development/staging/production
- Use different Firebase projects for each environment
- Use different Google Maps API keys for each environment

### 2. **Build-time Security**
- Always validate configuration before building
- Use `--release` flag for production builds
- Never include debug information in production builds

### 3. **Runtime Security**
- Validate configuration on app startup
- Handle missing configuration gracefully
- Log security events (but not sensitive data)

### 4. **Deployment Security**
- Use CI/CD pipelines with secure environment variables
- Rotate API keys regularly
- Monitor API usage for anomalies

## 📋 DEPLOYMENT CHECKLIST

### Before Production Deployment:

- [ ] All environment variables set correctly
- [ ] Configuration validation passes
- [ ] API keys are production keys (not development)
- [ ] HTTPS URLs configured for production
- [ ] Firebase project is production project
- [ ] Google Maps API key has proper restrictions
- [ ] App version updated
- [ ] Security headers configured
- [ ] CORS properly configured

### Environment Variable Checklist:

- [ ] API_URL (production backend URL)
- [ ] FIREBASE_API_KEY (production Firebase key)
- [ ] FIREBASE_PROJECT_ID (production Firebase project)
- [ ] FIREBASE_MESSAGING_SENDER_ID (production sender ID)
- [ ] FIREBASE_APP_ID (production app ID)
- [ ] GOOGLE_MAPS_API_KEY (production Google Maps key)
- [ ] ENVIRONMENT (set to "production")
- [ ] APP_NAME (correct app name)
- [ ] APP_VERSION (updated version)

## 🔧 TROUBLESHOOTING

### Common Issues:

1. **"Configuration validation failed"**
   - Check that all required environment variables are set
   - Verify variable names match exactly
   - Ensure no empty values

2. **"API connection failed"**
   - Verify API_URL is correct
   - Check backend server is running
   - Ensure CORS is configured properly

3. **"Firebase initialization failed"**
   - Verify FIREBASE_API_KEY is correct
   - Check FIREBASE_PROJECT_ID matches your project
   - Ensure Firebase project is properly configured

4. **"Google Maps not working"**
   - Verify GOOGLE_MAPS_API_KEY is correct
   - Check API key restrictions
   - Ensure Maps API is enabled in Google Cloud Console

## 📞 SUPPORT

If you encounter issues:

1. Check the configuration validation output
2. Verify all environment variables are set
3. Test with development configuration first
4. Check the browser console for errors
5. Verify backend is accessible

---

**🔐 Remember: Security is everyone's responsibility. Always follow these guidelines to keep your application secure.** 