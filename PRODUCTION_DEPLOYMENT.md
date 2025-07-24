# 🚀 Production Deployment Guide

## 📋 Overview

This guide covers deploying the SNS Rooster app to production with proper file storage handling.

## 🌐 Environment Configuration

### **Development vs Production**

| Environment | File Storage | Database | API URLs |
|-------------|--------------|----------|----------|
| **Development** | Local Storage | MongoDB Atlas | `http://192.168.1.68:5000` |
| **Production** | Google Cloud Storage | MongoDB Atlas | `https://your-domain.com` |

## 🔧 Production Setup

### **1. Environment Variables**

Create a `.env` file in production:

```env
# Environment
NODE_ENV=production

# Database
MONGODB_URI=mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0

# Google Cloud Storage
GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
GOOGLE_CLOUD_PROJECT=sns-rooster-8cca5

# Server
PORT=5000
BASE_URL=https://your-domain.com

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key
```

### **2. Google Cloud Storage Setup**

#### **A. Create Service Account**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `sns-rooster-8cca5`
3. Go to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Name: `sns-rooster-storage`
6. Description: `Service account for SNS Rooster file storage`
7. Click **Create and Continue**

#### **B. Assign Permissions**

1. **Storage Admin** - Full access to Cloud Storage
2. **Storage Object Admin** - Manage objects in Cloud Storage
3. Click **Done**

#### **C. Create Service Account Key**

1. Click on the service account
2. Go to **Keys** tab
3. Click **Add Key** → **Create New Key**
4. Choose **JSON** format
5. Download the key file
6. Save as `serviceAccountKey.json` in your project root

### **3. Cloud Storage Bucket Setup**

#### **A. Create Bucket**

1. Go to **Cloud Storage** → **Buckets**
2. Click **Create Bucket**
3. Name: `sns-rooster-8cca5.appspot.com`
4. Location: Choose closest to your users
5. Class: Standard
6. Access Control: Fine-grained
7. Protection: None (for now)

#### **B. Make Bucket Public**

1. Click on the bucket
2. Go to **Permissions** tab
3. Click **Add**
4. New principals: `allUsers`
5. Role: **Storage Object Viewer**
6. Click **Save**

#### **C. CORS Configuration**

Add CORS configuration to allow web access:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

## 🚀 Deployment Options

### **Option 1: Render (Recommended)**

1. **Connect Repository**
   - Connect your GitHub repository to Render
   - Choose **Web Service**

2. **Configure Service**
   ```
   Name: sns-rooster-backend
   Environment: Node
   Build Command: npm install
   Start Command: npm run start-prod
   ```

3. **Environment Variables**
   - Add all environment variables from `.env`
   - Set `NODE_ENV=production`

4. **Deploy**
   - Click **Create Web Service**
   - Render will automatically deploy

### **Option 2: Heroku**

1. **Install Heroku CLI**
   ```bash
   npm install -g heroku
   ```

2. **Create App**
   ```bash
   heroku create sns-rooster-backend
   ```

3. **Add Environment Variables**
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set MONGODB_URI=your-mongodb-uri
   heroku config:set GOOGLE_APPLICATION_CREDENTIALS=path/to/key
   ```

4. **Deploy**
   ```bash
   git push heroku main
   ```

### **Option 3: DigitalOcean App Platform**

1. **Create App**
   - Connect your GitHub repository
   - Choose **Node.js** environment

2. **Configure**
   - Build Command: `npm install`
   - Run Command: `npm run start-prod`

3. **Environment Variables**
   - Add all required environment variables

## 📱 Flutter App Configuration

### **Production API Configuration**

Update `sns_rooster/lib/config/api_config.dart`:

```dart
// Production URLs (HTTPS only)
static const String productionApiUrl = 'https://your-domain.com/api';
```

### **Build for Production**

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🔒 Security Considerations

### **1. Environment Variables**
- ✅ Never commit `.env` files
- ✅ Use secure secret management
- ✅ Rotate secrets regularly

### **2. File Upload Security**
- ✅ Validate file types
- ✅ Limit file sizes
- ✅ Scan for malware
- ✅ Use signed URLs for sensitive files

### **3. API Security**
- ✅ Use HTTPS only
- ✅ Implement rate limiting
- ✅ Add request validation
- ✅ Use CORS properly

## 📊 Monitoring & Logging

### **1. Application Logs**
```javascript
// Use Winston for structured logging
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### **2. Health Checks**
```javascript
// Add health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

## 🧪 Testing Production

### **1. Test File Upload**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "logo=@test-logo.png" \
  https://your-domain.com/api/admin/settings/company/logo
```

### **2. Test File Access**
```bash
curl -I https://storage.googleapis.com/sns-rooster-8cca5.appspot.com/company/test-logo.png
```

## 🔄 Migration from Development

### **1. Database Migration**
- ✅ All data is already in MongoDB Atlas
- ✅ No migration needed

### **2. File Migration**
- ✅ New uploads go to Cloud Storage
- ✅ Old local files remain accessible
- ✅ Gradual migration possible

## 📞 Support

If you encounter issues:

1. **Check Logs**: Monitor application logs
2. **Verify Environment**: Ensure all env vars are set
3. **Test Connectivity**: Verify database and storage access
4. **Review Permissions**: Check service account permissions

## 🎯 Success Checklist

- [ ] Environment variables configured
- [ ] Google Cloud Storage bucket created
- [ ] Service account key uploaded
- [ ] CORS configured
- [ ] HTTPS enabled
- [ ] Health check endpoint working
- [ ] File upload tested
- [ ] Flutter app configured for production
- [ ] Monitoring set up
- [ ] Backup strategy in place

---

**🎉 Your app is now production-ready with scalable file storage!** 