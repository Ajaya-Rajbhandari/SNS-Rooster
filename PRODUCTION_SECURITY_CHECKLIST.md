# 🔒 Production Security Checklist

## 🚨 **URGENT: Render Environment Variables**

Your production backend is deployed on Render. You need to update these environment variables in your Render dashboard:

### **Required Environment Variables for Render:**

```
MONGODB_URI=mongodb+srv://ajaya:Rx5IfjM5G32uws52@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=your-super-secure-jwt-secret-32+characters
EMAIL_PROVIDER=gmail
EMAIL_FROM=ajaya@snstechservices.com.au
GMAIL_USER=ajaya@snstechservices.com.au
GMAIL_APP_PASSWORD=pfzo vbnj csif ykxq
NODE_ENV=production
FRONTEND_URL=https://sns-rooster-8cca5.web.app
ADMIN_PORTAL_URL=https://sns-rooster-admin.web.app
```

## 🔧 **How to Update Render Environment Variables:**

1. **Go to your Render Dashboard**
2. **Find your SNS Rooster backend service**
3. **Click on "Environment" tab**
4. **Add/Update these variables**

## 🛡️ **Security Recommendations:**

### **1. Change Passwords (Recommended)**
- **MongoDB Password**: Generate a new strong password
- **Gmail App Password**: Generate a new app password
- **JWT Secret**: Generate a new 32+ character secret

### **2. New Secure Credentials (if you want to change them):**

**MongoDB Password**: `[ASK USER FOR NEW PASSWORD]`
**Gmail App Password**: `[ASK USER FOR NEW APP PASSWORD]`
**JWT Secret**: `[ASK USER FOR NEW SECRET]`

## ✅ **Current Status:**

- ✅ **Main server.js**: Using environment variables correctly
- ✅ **Production code**: No hardcoded credentials found
- ⚠️ **Render Environment**: Needs verification
- ⚠️ **Passwords**: Should be rotated for security

## 🎯 **Next Steps:**

1. **Verify Render environment variables**
2. **Change passwords (optional but recommended)**
3. **Test production deployment**
4. **Set up monitoring**

## 📋 **Quick Security Test:**

After updating Render environment variables, test:
- [ ] Backend API responds correctly
- [ ] Email functionality works
- [ ] Authentication works
- [ ] Database connections work

## 🔍 **Monitoring Setup:**

Consider adding these to Render:
- **Uptime monitoring**
- **Error tracking (Sentry)**
- **Performance monitoring**

---

**Do you want me to help you:**
1. **Generate new secure passwords?**
2. **Guide you through updating Render environment variables?**
3. **Test the production deployment?** 