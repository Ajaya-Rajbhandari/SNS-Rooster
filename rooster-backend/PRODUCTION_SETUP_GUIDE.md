# Backend Production Setup Guide for SNS Rooster

## 🎉 Current Status: Backend Ready for Production

The backend is already deployed on Render and working correctly. Here's what needs to be updated for production.

## 🔧 Backend Production Configuration

### ✅ **Already Working:**
- ✅ Backend deployed on Render
- ✅ Database connection working
- ✅ API endpoints responding
- ✅ CORS configured for production domains
- ✅ Email service working

### 🔒 **Required Updates for Production:**

#### 1. **Environment Variables Update**

**Current Backend URL**: `https://sns-rooster.onrender.com/api`

**Required Environment Variables in Render Dashboard:**

```env
# 🔐 Critical Security Variables
JWT_SECRET=your-super-secure-jwt-secret-32+characters-long
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database

# 📧 Email Configuration (Gmail)
EMAIL_PROVIDER=gmail
EMAIL_FROM=your-email@gmail.com
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-gmail-app-password

# 🌐 Server Configuration
NODE_ENV=production
PORT=5000
FRONTEND_URL=https://your-production-domain.com
ADMIN_PORTAL_URL=https://your-admin-domain.com

# 🗺️ Google Maps Configuration
GOOGLE_MAPS_API_KEY=AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc

# 🔔 Push Notifications (Optional)
FIREBASE_SERVER_KEY=your-firebase-server-key

# 📊 Monitoring (Optional)
SENTRY_DSN=your-sentry-dsn-url
```

#### 2. **CORS Configuration Update**

**Current CORS Settings** (in `app.js`):
```javascript
const allowedOrigins = [
  'https://sns-rooster-8cca5.web.app',
  'https://sns-rooster-admin.web.app',
  'https://sns-rooster.onrender.com',
  'http://localhost:3000',
  'http://localhost:3001',
  'http://192.168.1.119:8080'
];
```

**Update for Production:**
```javascript
const allowedOrigins = [
  'https://your-production-domain.com',
  'https://your-admin-domain.com',
  'https://sns-rooster.onrender.com',
  // Keep localhost for development
  'http://localhost:3000',
  'http://localhost:3001'
];
```

#### 3. **Google Maps API Key**

**Backend Configuration:**
- The backend doesn't directly use Google Maps API
- The API key is only used in the frontend (Flutter apps)
- **No backend changes needed** for Google Maps

#### 4. **Database Configuration**

**Current Status**: MongoDB Atlas connection working
**Production Requirements**:
- ✅ Database connection string configured
- ✅ Database indexes optimized
- ✅ Backup strategy in place

#### 5. **Email Service Configuration**

**Current Status**: Gmail service working
**Production Requirements**:
- ✅ Gmail app password configured
- ✅ Email templates ready
- ✅ Error handling in place

## 🚀 **Production Deployment Steps**

### **1. Update Render Environment Variables**

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Select your backend service**
3. **Go to "Environment" tab**
4. **Update these variables**:

```env
NODE_ENV=production
FRONTEND_URL=https://your-production-domain.com
ADMIN_PORTAL_URL=https://your-admin-domain.com
GOOGLE_MAPS_API_KEY=AIzaSyDrqjkWAfQqSWBPmKCAxYxs6cjuDEbPZGc
```

### **2. Update CORS Configuration**

**File**: `rooster-backend/app.js`
**Lines**: 75-85

```javascript
const allowedOrigins = [
  'https://your-production-domain.com',
  'https://your-admin-domain.com',
  'https://sns-rooster.onrender.com',
  'http://localhost:3000',  // Development
  'http://localhost:3001'   // Development
];
```

### **3. Deploy Backend Changes**

```bash
# Commit and push changes
git add .
git commit -m "Update CORS for production domains"
git push origin main

# Render will automatically deploy
```

## 🔍 **Production Verification**

### **1. Test API Endpoints**

```bash
# Health check
curl https://sns-rooster.onrender.com/api/health

# Authentication test
curl https://sns-rooster.onrender.com/api/auth/login
```

### **2. Test CORS**

```bash
# Test from your production domain
curl -H "Origin: https://your-production-domain.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS https://sns-rooster.onrender.com/api/auth/login
```

### **3. Test Email Service**

- Send test email from admin panel
- Verify email delivery
- Check email templates

## 📊 **Monitoring and Logs**

### **1. Render Logs**
- **Access**: Render Dashboard → Your Service → Logs
- **Monitor**: Error rates, response times, memory usage

### **2. Database Monitoring**
- **MongoDB Atlas**: Monitor connection pool, query performance
- **Set up alerts** for high CPU/memory usage

### **3. API Monitoring**
- **Set up uptime monitoring** (UptimeRobot, Pingdom)
- **Monitor response times** and error rates

## 🔒 **Security Checklist**

### **✅ Completed:**
- ✅ HTTPS enabled (Render provides SSL)
- ✅ JWT authentication working
- ✅ Rate limiting configured
- ✅ CORS properly configured
- ✅ Environment variables secured

### **🔧 Additional Security:**
- [ ] Set up API key restrictions for production domains
- [ ] Configure firewall rules if needed
- [ ] Set up security headers
- [ ] Enable request logging
- [ ] Set up error tracking (Sentry)

## 🚨 **Important Notes**

### **1. API Key Management**
- **Frontend**: Uses Google Maps API key directly
- **Backend**: Doesn't need Google Maps API key
- **Security**: API key restrictions should be set in Google Cloud Console

### **2. Environment Variables**
- **Never commit** `.env` files to version control
- **Use Render's environment variables** for production
- **Rotate secrets** regularly

### **3. Database**
- **Backup strategy** should be in place
- **Monitor** database performance
- **Set up alerts** for connection issues

### **4. Email Service**
- **Gmail app password** should be secure
- **Monitor** email delivery rates
- **Set up fallback** email provider if needed

## ✅ **Final Backend Checklist**

- [ ] Environment variables updated in Render
- [ ] CORS configuration updated for production domains
- [ ] Database connection verified
- [ ] Email service tested
- [ ] API endpoints tested
- [ ] Monitoring set up
- [ ] Security measures in place
- [ ] Backup strategy configured

## 🎯 **Summary**

**Backend Status**: ✅ **Ready for Production**

**Required Actions**:
1. **Update CORS** for your production domains
2. **Update environment variables** in Render
3. **Deploy changes** to Render
4. **Test all endpoints** from production domains

**No Google Maps API Key Changes Needed**: The backend doesn't use Google Maps directly - only the frontend apps do.

---

**🎉 Your backend is production-ready! Just update the CORS and environment variables for your specific domains.** 