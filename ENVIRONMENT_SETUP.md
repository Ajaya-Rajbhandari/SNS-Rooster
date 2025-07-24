# 🔐 ENVIRONMENT SETUP GUIDE

## Overview
This guide explains how to set up environment variables for the SNS Rooster project securely.

## 🚨 CRITICAL SECURITY NOTES

1. **NEVER commit .env files to version control**
2. **NEVER use hardcoded secrets in code**
3. **ALWAYS use environment variables for sensitive data**
4. **ROTATE secrets regularly**

## 📁 Backend Environment Variables

### Required Variables (rooster-backend/.env)

```bash
# Database Configuration
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database?retryWrites=true&w=majority

# JWT Configuration
JWT_SECRET=your-super-secure-jwt-secret-minimum-32-characters-long

# Server Configuration
PORT=5000
NODE_ENV=production

# Email Configuration
EMAIL_PROVIDER=gmail
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour Private Key Here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Google Services
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account-key.json

# CORS Configuration
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://your-admin-portal.com

# Optional: Resend Email Service
RESEND_API_KEY=your-resend-api-key
```

### Development Variables (rooster-backend/.env.development)

```bash
# Database Configuration
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/sns-rooster-dev?retryWrites=true&w=majority

# JWT Configuration
JWT_SECRET=dev-jwt-secret-32-chars-minimum-for-development-only

# Server Configuration
PORT=5000
NODE_ENV=development

# Email Configuration (optional for dev)
EMAIL_PROVIDER=console

# Firebase Configuration (optional for dev)
FIREBASE_PROJECT_ID=your-dev-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour Dev Private Key Here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-dev-project.iam.gserviceaccount.com

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:5000
```

## 📱 Flutter Environment Variables

### Production Build

```bash
# Build with environment variables
flutter build web --dart-define=API_URL=https://your-backend-domain.com/api
flutter build web --dart-define=FIREBASE_API_KEY=your-firebase-api-key
flutter build web --dart-define=GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### Development Build

```bash
# Build with development environment variables
flutter build web --dart-define=API_URL=http://localhost:5000/api
flutter build web --dart-define=FIREBASE_API_KEY=your-dev-firebase-api-key
flutter build web --dart-define=GOOGLE_MAPS_API_KEY=your-dev-google-maps-api-key
```

## 🔧 Environment Variable Usage in Code

### Backend (Node.js)

```javascript
// ✅ CORRECT - Use environment variables
const jwtSecret = process.env.JWT_SECRET;
const mongoUri = process.env.MONGODB_URI;

// ❌ WRONG - Never hardcode secrets
const jwtSecret = 'hardcoded-secret';
```

### Frontend (Flutter)

```dart
// ✅ CORRECT - Use String.fromEnvironment()
class ApiConfig {
  static const String apiUrl = String.fromEnvironment('API_URL');
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
}

// ❌ WRONG - Never hardcode API keys
class ApiConfig {
  static const String apiUrl = 'https://hardcoded-url.com/api';
  static const String firebaseApiKey = 'AIzaSy...';
}
```

## 🛡️ Security Best Practices

### 1. **Secret Management**
- Use a secrets management service (AWS Secrets Manager, Azure Key Vault, etc.)
- Rotate secrets regularly
- Use different secrets for different environments

### 2. **Environment Separation**
- Use different databases for dev/staging/production
- Use different API keys for each environment
- Never use production secrets in development

### 3. **Access Control**
- Limit access to environment variables
- Use role-based access control
- Monitor access to sensitive data

### 4. **Validation**
- Validate environment variables on startup
- Provide clear error messages for missing variables
- Use default values only for non-sensitive data

## 🔍 Environment Variable Validation

### Backend Validation Script

```javascript
// Add this to your server startup
const requiredEnvVars = [
  'MONGODB_URI',
  'JWT_SECRET',
  'NODE_ENV'
];

requiredEnvVars.forEach(varName => {
  if (!process.env[varName]) {
    console.error(`❌ Missing required environment variable: ${varName}`);
    process.exit(1);
  }
});

console.log('✅ All required environment variables are set');
```

### Flutter Validation

```dart
// Add this to your app initialization
void validateEnvironment() {
  final requiredVars = [
    'API_URL',
    'FIREBASE_API_KEY',
  ];
  
  for (final varName in requiredVars) {
    final value = String.fromEnvironment(varName);
    if (value.isEmpty) {
      throw Exception('Missing required environment variable: $varName');
    }
  }
}
```

## 🚀 Deployment Checklist

### Before Production Deployment:

- [ ] All hardcoded secrets removed from code
- [ ] Environment variables configured
- [ ] Secrets rotated from development
- [ ] CORS configured for production domains
- [ ] HTTPS enabled
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Monitoring and logging configured

### Environment Variable Checklist:

- [ ] MONGODB_URI (production database)
- [ ] JWT_SECRET (32+ character secure secret)
- [ ] FIREBASE_PROJECT_ID (production project)
- [ ] FIREBASE_PRIVATE_KEY (production private key)
- [ ] FIREBASE_CLIENT_EMAIL (production service account)
- [ ] GOOGLE_MAPS_API_KEY (production API key)
- [ ] EMAIL_PROVIDER and SMTP settings
- [ ] ALLOWED_ORIGINS (production domains only)

## 📞 Troubleshooting

### Common Issues:

1. **"Missing environment variable" error**
   - Check that all required variables are set
   - Verify variable names match exactly
   - Restart the application after setting variables

2. **"Invalid JWT secret" error**
   - Ensure JWT_SECRET is at least 32 characters
   - Check for special characters that need escaping
   - Verify the secret is the same across all services

3. **"Database connection failed" error**
   - Verify MONGODB_URI format
   - Check network connectivity
   - Ensure database user has correct permissions

4. **"Firebase initialization failed" error**
   - Verify FIREBASE_PRIVATE_KEY format (include newlines)
   - Check FIREBASE_PROJECT_ID matches your project
   - Ensure service account has correct permissions

---

**🔐 Remember: Security is everyone's responsibility. Always follow these guidelines to keep your application secure.** 