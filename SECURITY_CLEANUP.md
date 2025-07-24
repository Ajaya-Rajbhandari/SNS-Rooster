# 🔐 SECURITY CLEANUP GUIDE

## 🚨 IMMEDIATE ACTIONS REQUIRED

### 1. **ROTATE ALL EXPOSED CREDENTIALS**

**MongoDB Database:**
- Change password for user `ajaya`
- Update connection string in production environment
- Remove all hardcoded connection strings from code

**Firebase:**
- Generate new service account keys
- Update FIREBASE_PRIVATE_KEY in environment
- Rotate Firebase API keys

**JWT Secret:**
- Generate new JWT secret (32+ characters)
- Update JWT_SECRET in environment
- Invalidate all existing tokens

**Google Maps API:**
- Rotate Google Maps API key
- Update GOOGLE_MAPS_API_KEY in environment

### 2. **REMOVE HARDCODED CREDENTIALS**

The following files still contain hardcoded credentials that need to be fixed:

```bash
# Test files with hardcoded MongoDB URIs
rooster-backend/check-companies.js
rooster-backend/test-api-with-auth.js
rooster-backend/test-company-info.js
rooster-backend/verify-all-companies.js
rooster-backend/update-company-info.js
rooster-backend/update-all-companies.js
rooster-backend/test-usage-api.js
rooster-backend/test-ui-integration.js
rooster-backend/test-logo-upload.js
rooster-backend/test-flutter-integration.js
rooster-backend/test-flutter-api-call.js
rooster-backend/test-flutter-api-with-auth.js
rooster-backend/test-feature-management.js
rooster-backend/test-company-settings-api.js
rooster-backend/test-api-connection.js
rooster-backend/scripts/update-company-usage.js
rooster-backend/scripts/test_user_management_multi_tenant.js
rooster-backend/scripts/test_analytics_multi_tenant.js
rooster-backend/scripts/test_admin_settings_multi_tenant.js
rooster-backend/scripts/force-create-admin.js
rooster-backend/fix-production-sns-tech.js
rooster-backend/debug-api-response.js
rooster-backend/check-user-passwords.js
rooster-backend/assign-plans-to-companies.js

# Scripts with hardcoded passwords
rooster-backend/setup_test_user.js
rooster-backend/reset_test_password.js
rooster-backend/scripts/check-user-password.js
rooster-backend/scripts/create-distinctive-user.js
rooster-backend/scripts/debug-test-user.js
rooster-backend/scripts/final-test-user.js
rooster-backend/scripts/reset-admin-password.js
rooster-backend/scripts/test-company-creation.js
rooster-backend/scripts/test-login.js
rooster-backend/scripts/test-user-creation-login.js
rooster-backend/scripts/test-user-login.js
rooster-backend/scripts/verify-super-admin.js
rooster-backend/scripts/test-super-admin-users.js
rooster-backend/scripts/test-admin-login.js
rooster-backend/scripts/check-admin-passwords.js
rooster-backend/check-user-passwords.js
rooster-backend/assign-plans-to-companies.js
```

### 3. **FIX PATTERN FOR ALL FILES**

Replace hardcoded MongoDB URIs:
```javascript
// ❌ WRONG
const MONGODB_URI = 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';

// ✅ CORRECT
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster-dev';
```

Replace hardcoded passwords:
```javascript
// ❌ WRONG
password: 'SuperAdmin@123'

// ✅ CORRECT
password: process.env.TEST_PASSWORD || 'use-environment-variable'
```

## 🔧 AUTOMATED CLEANUP SCRIPT

Create a script to fix all hardcoded credentials:

```bash
#!/bin/bash
# security-cleanup.sh

echo "🔐 Starting security cleanup..."

# Fix MongoDB URIs
find rooster-backend -name "*.js" -type f -exec sed -i 's/mongodb+srv:\/\/ajaya:ysjevCMEPSwMcCDl@cluster0\.1ufkdju\.mongodb\.net\/sns-rooster?retryWrites=true&w=majority&appName=Cluster0/process.env.MONGODB_URI || "mongodb:\/\/localhost:27017\/sns-rooster-dev"/g' {} \;

# Fix hardcoded passwords
find rooster-backend -name "*.js" -type f -exec sed -i 's/password: '\''SuperAdmin@123'\''/password: process.env.TEST_PASSWORD || "use-environment-variable"/g' {} \;
find rooster-backend -name "*.js" -type f -exec sed -i 's/password: '\''admin123'\''/password: process.env.TEST_PASSWORD || "use-environment-variable"/g' {} \;
find rooster-backend -name "*.js" -type f -exec sed -i 's/password: '\''Admin123!'\''/password: process.env.TEST_PASSWORD || "use-environment-variable"/g' {} \;

echo "✅ Security cleanup completed!"
```

## 🛡️ ENVIRONMENT VARIABLES SETUP

### Required Environment Variables

```bash
# Backend (.env)
MONGODB_URI=mongodb+srv://new-username:new-password@cluster.mongodb.net/sns-rooster-prod?retryWrites=true&w=majority
JWT_SECRET=your-new-super-secure-jwt-secret-minimum-32-characters-long
FIREBASE_PROJECT_ID=your-new-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour New Private Key Here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-new-project.iam.gserviceaccount.com
GOOGLE_MAPS_API_KEY=your-new-google-maps-api-key
TEST_PASSWORD=your-test-password-for-development

# Frontend (build-time)
API_URL=https://your-backend-domain.com/api
FIREBASE_API_KEY=your-new-firebase-api-key
GOOGLE_MAPS_API_KEY=your-new-google-maps-api-key
```

## 🔍 VERIFICATION STEPS

### 1. Check for Remaining Hardcoded Credentials

```bash
# Search for remaining hardcoded MongoDB URIs
grep -r "mongodb+srv://" rooster-backend/

# Search for remaining hardcoded passwords
grep -r "SuperAdmin@123\|admin123\|Admin123!" rooster-backend/

# Search for remaining API keys
grep -r "AIzaSy" rooster-backend/
grep -r "AIzaSy" sns_rooster/
```

### 2. Test Environment Variables

```bash
# Test backend environment variables
cd rooster-backend
node -e "console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'SET' : 'NOT SET')"
node -e "console.log('JWT_SECRET:', process.env.JWT_SECRET ? 'SET' : 'NOT SET')"
```

### 3. Test Application Functionality

```bash
# Test backend
cd rooster-backend
npm start

# Test frontend
cd sns_rooster
flutter run -d chrome
```

## 🚨 CRITICAL SECURITY CHECKLIST

- [ ] **ROTATE ALL EXPOSED CREDENTIALS**
  - [ ] MongoDB password changed
  - [ ] Firebase service account keys regenerated
  - [ ] JWT secret regenerated
  - [ ] Google Maps API key rotated
  - [ ] Firebase API key rotated

- [ ] **REMOVE ALL HARDCODED CREDENTIALS**
  - [ ] MongoDB URIs removed from code
  - [ ] Passwords removed from code
  - [ ] API keys removed from code
  - [ ] JWT secrets removed from code

- [ ] **SETUP ENVIRONMENT VARIABLES**
  - [ ] Backend .env file created
  - [ ] Frontend build variables configured
  - [ ] All variables tested

- [ ] **SECURITY HEADERS**
  - [ ] HTTPS enforced
  - [ ] CORS configured
  - [ ] Rate limiting enabled
  - [ ] Security headers set

- [ ] **MONITORING**
  - [ ] Logging configured
  - [ ] Error tracking enabled
  - [ ] Performance monitoring set up

## 📞 IMMEDIATE ACTIONS

1. **STOP ALL DEVELOPMENT** until credentials are rotated
2. **CHANGE ALL PASSWORDS** immediately
3. **REGENERATE ALL API KEYS**
4. **UPDATE ENVIRONMENT VARIABLES**
5. **TEST ALL FUNCTIONALITY**
6. **MONITOR FOR UNAUTHORIZED ACCESS**

## 🔄 ONGOING SECURITY

### Daily Tasks:
- Monitor logs for suspicious activity
- Check for failed login attempts
- Review API usage patterns

### Weekly Tasks:
- Update dependencies
- Review security advisories
- Backup sensitive data

### Monthly Tasks:
- Rotate secrets
- Conduct security audits
- Update security policies

---

**🚨 URGENT: Complete these steps immediately to secure your application!** 