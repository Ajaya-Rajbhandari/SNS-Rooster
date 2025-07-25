# 🚀 SNS Rooster Backend - Render Production Deployment Checklist

## ✅ **SECURITY AUDIT COMPLETED**

### **Critical Security Issues Fixed:**
- ✅ **All hardcoded MongoDB URIs removed** - Now using `process.env.MONGODB_URI`
- ✅ **All hardcoded JWT secrets removed** - Now using `process.env.JWT_SECRET`
- ✅ **Comprehensive .gitignore created** - No sensitive files will be tracked
- ✅ **Environment variables properly configured** - All secrets moved to env vars

---

## 🔧 **RENDER DEPLOYMENT CONFIGURATION**

### **1. Environment Variables (Required in Render Dashboard)**

```bash
# 🗄️ DATABASE
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/sns-rooster?retryWrites=true&w=majority

# 🔐 JWT & AUTHENTICATION
JWT_SECRET=your-super-secure-jwt-secret-32+characters-long
JWT_REFRESH_SECRET=your-refresh-secret-32+characters-long

# 📧 EMAIL CONFIGURATION
EMAIL_PROVIDER=gmail
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password
RESEND_API_KEY=your-resend-api-key

# 🌐 SERVER CONFIGURATION
NODE_ENV=production
PORT=5000
HOST=0.0.0.0

# 🔗 FRONTEND URLs (for CORS)
FRONTEND_URL=https://sns-rooster-8cca5.web.app
ADMIN_PORTAL_URL=https://sns-rooster-admin.web.app

# 📊 MONITORING (Optional)
SENTRY_DSN=your-sentry-dsn
DATADOG_API_KEY=your-datadog-key

# 🔒 SECURITY
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### **2. Render Service Configuration**

```yaml
# Service Settings
Name: sns-rooster-backend
Environment: Node
Region: Choose closest to your users
Branch: main (or your production branch)

# Build Command
Build Command: npm install

# Start Command
Start Command: npm run start-prod

# Health Check Path
Health Check Path: /api/monitoring/health

# Auto-Deploy: Yes (for main branch)
```

### **3. Environment Variables in Render Dashboard**

**Go to:** Your Render Service → Environment → Environment Variables

**Add these variables:**

| Variable | Value | Description |
|----------|-------|-------------|
| `NODE_ENV` | `production` | Production environment flag |
| `MONGODB_URI` | `mongodb+srv://...` | Your production MongoDB URI |
| `JWT_SECRET` | `your-32-char-secret` | Strong JWT signing secret |
| `JWT_REFRESH_SECRET` | `your-32-char-refresh-secret` | JWT refresh token secret |
| `EMAIL_PROVIDER` | `gmail` | Email service provider |
| `GMAIL_EMAIL` | `your-email@gmail.com` | Gmail account email |
| `GMAIL_APP_PASSWORD` | `your-app-password` | Gmail app password |
| `FRONTEND_URL` | `https://sns-rooster-8cca5.web.app` | Flutter web app URL |
| `ADMIN_PORTAL_URL` | `https://sns-rooster-admin.web.app` | Admin portal URL |
| `PORT` | `5000` | Server port (Render will override) |
| `HOST` | `0.0.0.0` | Server host |

---

## 🛡️ **PRE-DEPLOYMENT SECURITY CHECKLIST**

### **✅ Code Security**
- [x] No hardcoded credentials in any files
- [x] All secrets moved to environment variables
- [x] .gitignore properly configured
- [x] No sensitive files in Git history

### **✅ Environment Variables**
- [x] Production MongoDB URI configured
- [x] Strong JWT secrets generated
- [x] Email credentials configured
- [x] CORS origins set correctly

### **✅ Security Middleware**
- [x] Helmet security headers enabled
- [x] Rate limiting configured
- [x] CORS properly configured
- [x] Input validation active
- [x] File upload security enabled

### **✅ Monitoring & Health**
- [x] Health check endpoint: `/api/monitoring/health`
- [x] Monitoring dashboard accessible
- [x] Error tracking configured
- [x] Performance monitoring active

---

## 🚀 **DEPLOYMENT STEPS**

### **Step 1: Push to Git**
```bash
# Ensure you're on the correct branch
git checkout main

# Add all changes
git add .

# Commit with descriptive message
git commit -m "🔒 Security audit completed - Ready for production deployment"

# Push to remote
git push origin main
```

### **Step 2: Configure Render Service**
1. **Go to Render Dashboard**
2. **Create New Web Service** (if not exists)
3. **Connect your Git repository**
4. **Configure environment variables** (see above)
5. **Set build command:** `npm install`
6. **Set start command:** `npm run start-prod`
7. **Set health check path:** `/api/monitoring/health`

### **Step 3: Deploy**
1. **Click "Deploy"**
2. **Monitor build logs** for any errors
3. **Verify health check passes**
4. **Test monitoring endpoint:** `https://your-app.onrender.com/api/monitoring/health`

---

## 🧪 **POST-DEPLOYMENT TESTING**

### **1. Health Check**
```bash
curl https://your-app.onrender.com/api/monitoring/health
```
**Expected:** `{"status":"healthy","database":"connected",...}`

### **2. Authentication Test**
```bash
curl -X POST https://your-app.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@snsrooster.com","password":"your-password"}'
```
**Expected:** `{"token":"...","user":{...}}`

### **3. CORS Test**
```bash
curl -H "Origin: https://sns-rooster-8cca5.web.app" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS https://your-app.onrender.com/api/auth/login
```
**Expected:** CORS headers in response

### **4. Rate Limiting Test**
```bash
# Make multiple rapid requests
for i in {1..10}; do
  curl https://your-app.onrender.com/api/monitoring/health
done
```
**Expected:** Some requests should be rate limited (429 status)

---

## 📊 **MONITORING & MAINTENANCE**

### **1. Health Monitoring**
- **URL:** `https://your-app.onrender.com/api/monitoring/health`
- **Frequency:** Every 5 minutes
- **Alert on:** Status != "healthy"

### **2. Performance Monitoring**
- **URL:** `https://your-app.onrender.com/api/monitoring/performance`
- **Check:** Response times, error rates
- **Alert on:** Response time > 5 seconds

### **3. Error Tracking**
- **URL:** `https://your-app.onrender.com/api/monitoring/errors`
- **Check:** Error frequency, severity
- **Alert on:** Critical errors

### **4. Database Monitoring**
- **Check:** Connection status, query performance
- **Alert on:** Connection failures, slow queries

---

## 🔄 **BACKUP & RECOVERY**

### **1. Database Backups**
```bash
# Automated backup (configure in Render cron)
npm run backup
```

### **2. Environment Variables Backup**
- **Export all env vars** from Render dashboard
- **Store securely** (password manager, secure notes)
- **Document** all variable purposes

### **3. Recovery Plan**
1. **Database restore:** Use `mongorestore` with backup files
2. **Service restart:** Via Render dashboard
3. **Environment restore:** Re-add env vars in Render

---

## 🎯 **SUCCESS CRITERIA**

### **✅ Deployment Successful When:**
- [ ] Health check returns `200 OK`
- [ ] Authentication endpoints work
- [ ] CORS allows frontend requests
- [ ] Rate limiting is active
- [ ] Monitoring dashboard accessible
- [ ] No errors in Render logs
- [ ] Database connection stable
- [ ] Email service functional

### **✅ Security Verified When:**
- [ ] No secrets in code
- [ ] All endpoints require authentication
- [ ] Rate limiting prevents abuse
- [ ] CORS only allows trusted origins
- [ ] Input validation blocks malicious data
- [ ] File uploads are secure

---

## 🚨 **EMERGENCY CONTACTS**

- **Render Support:** Via Render dashboard
- **MongoDB Support:** Via MongoDB Atlas dashboard
- **Email Provider:** Gmail/Resend support
- **Monitoring:** Check Render logs and monitoring dashboard

---

**🎉 Your SNS Rooster backend is now ready for secure production deployment on Render!** 