# 🚀 PRODUCTION SETUP GUIDE

## Overview
This guide walks you through setting up the SNS Rooster project for production deployment securely.

## ⚠️ CRITICAL SECURITY WARNINGS

**BEFORE PRODUCTION DEPLOYMENT:**
1. **NEVER commit .env files to git**
2. **NEVER use hardcoded secrets in code**
3. **ALWAYS rotate secrets from development**
4. **ALWAYS use HTTPS in production**

## 📋 PRE-DEPLOYMENT CHECKLIST

### ✅ Security Checklist
- [ ] All hardcoded credentials removed from code
- [ ] Environment variables configured
- [ ] Secrets rotated from development
- [ ] CORS configured for production domains
- [ ] HTTPS enabled
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Monitoring and logging configured

### ✅ Environment Variables Checklist
- [ ] MONGODB_URI (production database)
- [ ] JWT_SECRET (32+ character secure secret)
- [ ] FIREBASE_PROJECT_ID (production project)
- [ ] FIREBASE_PRIVATE_KEY (production private key)
- [ ] FIREBASE_CLIENT_EMAIL (production service account)
- [ ] GOOGLE_MAPS_API_KEY (production API key)
- [ ] EMAIL_PROVIDER and SMTP settings
- [ ] ALLOWED_ORIGINS (production domains only)

## 🔧 STEP-BY-STEP SETUP

### Step 1: Remove Sensitive Files

```bash
# Remove any remaining sensitive files
rm -f rooster-backend/firebase-adminsdk.json
rm -f rooster-backend/serviceAccountKey.json
rm -f rooster-backend/COMPANY_ADMIN_CREDENTIALS.md
rm -f rooster-backend/.env
```

### Step 2: Create Production Environment File

```bash
# Create production environment file
cd rooster-backend
touch .env
```

Add the following to `rooster-backend/.env`:

```bash
# Database Configuration
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/sns-rooster-prod?retryWrites=true&w=majority

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
FIREBASE_PROJECT_ID=your-production-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour Production Private Key Here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-production-project.iam.gserviceaccount.com

# Google Services
GOOGLE_MAPS_API_KEY=your-production-google-maps-api-key
GOOGLE_APPLICATION_CREDENTIALS=path/to/production-service-account-key.json

# CORS Configuration
ALLOWED_ORIGINS=https://your-production-domain.com,https://www.your-production-domain.com

# Optional: Resend Email Service
RESEND_API_KEY=your-production-resend-api-key
```

### Step 3: Install Dependencies

```bash
# Backend dependencies
cd rooster-backend
npm install --production

# Frontend dependencies (if needed)
cd ../sns_rooster
flutter pub get
```

### Step 4: Build Frontend for Production

```bash
# Build Flutter web app with production environment variables
cd sns_rooster
flutter build web --release \
  --dart-define=API_URL=https://your-backend-domain.com/api \
  --dart-define=FIREBASE_API_KEY=your-production-firebase-api-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-production-google-maps-api-key
```

### Step 5: Start Backend Server

```bash
# Start the backend server
cd rooster-backend
npm start
```

### Step 6: Deploy Frontend

Upload the contents of `sns_rooster/build/web/` to your web hosting service.

## 🔒 SECURITY CONFIGURATION

### Backend Security Headers

Add to your Express app:

```javascript
const helmet = require('helmet');
const cors = require('cors');

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://your-domain.com'],
  credentials: true
}));

// Rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);
```

### HTTPS Configuration

```javascript
// Force HTTPS in production
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.header('x-forwarded-proto') !== 'https') {
      res.redirect(`https://${req.header('host')}${req.url}`);
    } else {
      next();
    }
  });
}
```

## 📊 MONITORING SETUP

### Logging Configuration

```javascript
// Add to your server
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}
```

### Health Check Endpoint

```javascript
// Add health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    version: process.env.npm_package_version || '1.0.0'
  });
});
```

## 🚀 DEPLOYMENT OPTIONS

### Option 1: Traditional VPS/Server

1. **Upload code to server**
2. **Install Node.js and dependencies**
3. **Set up environment variables**
4. **Use PM2 for process management**
5. **Set up reverse proxy (nginx)**
6. **Configure SSL certificate**

### Option 2: Cloud Platforms

#### Render.com
1. Connect your GitHub repository
2. Set environment variables in dashboard
3. Deploy automatically on push

#### Heroku
1. Connect your GitHub repository
2. Set config vars in dashboard
3. Deploy automatically on push

#### AWS/Azure/GCP
1. Use container services
2. Set up CI/CD pipelines
3. Use managed databases
4. Configure load balancers

## 🔍 POST-DEPLOYMENT VERIFICATION

### 1. Test API Endpoints

```bash
# Test health endpoint
curl https://your-backend-domain.com/api/health

# Test authentication
curl -X POST https://your-backend-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}'
```

### 2. Test Frontend

1. Open your frontend URL
2. Test login functionality
3. Test all major features
4. Check for console errors
5. Verify HTTPS is working

### 3. Security Testing

1. Check for exposed secrets
2. Verify CORS is working
3. Test rate limiting
4. Check security headers
5. Verify HTTPS redirects

## 📞 TROUBLESHOOTING

### Common Issues:

1. **"Cannot connect to database"**
   - Check MONGODB_URI format
   - Verify network connectivity
   - Check database user permissions

2. **"JWT verification failed"**
   - Ensure JWT_SECRET is set correctly
   - Check for special characters in secret
   - Verify secret is same across services

3. **"CORS error"**
   - Check ALLOWED_ORIGINS configuration
   - Verify frontend URL is included
   - Check for trailing slashes

4. **"Firebase initialization failed"**
   - Verify FIREBASE_PRIVATE_KEY format
   - Check FIREBASE_PROJECT_ID
   - Ensure service account permissions

## 🔄 MAINTENANCE

### Regular Tasks:

1. **Monitor logs** for errors
2. **Update dependencies** regularly
3. **Rotate secrets** periodically
4. **Backup database** regularly
5. **Monitor performance** metrics
6. **Update SSL certificates**

### Security Updates:

1. **Keep Node.js updated**
2. **Update npm packages** regularly
3. **Monitor security advisories**
4. **Conduct security audits** periodically

---

**🚀 Your application is now ready for production! Remember to monitor it closely and maintain security best practices.** 