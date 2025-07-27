# Render Environment Variables Checklist

## Current Status Analysis

Based on the server logs and tests, the application is working correctly, but some environment variables may be missing or not properly configured.

## ✅ **Working Correctly:**
- Server is running in production mode
- Database connection is working
- Email service is working (logging to console)
- CORS is properly configured
- API endpoints are responding

## 📋 **Required Environment Variables for Render:**

### **🔐 Critical Security Variables:**
```env
JWT_SECRET=your-super-secure-jwt-secret-32+characters-long
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database
```

### **📧 Email Configuration (Gmail):**
```env
EMAIL_PROVIDER=gmail
EMAIL_FROM=your-email@gmail.com
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-16-character-app-password
```

### **🌐 Server Configuration:**
```env
NODE_ENV=production
PORT=5000
FRONTEND_URL=https://sns-rooster-8cca5.web.app
ADMIN_PORTAL_URL=https://sns-rooster-admin.web.app
```

### **📁 File Storage (Optional):**
```env
GOOGLE_CLOUD_STORAGE_BUCKET=your-bucket-name
GOOGLE_CLOUD_STORAGE_KEY_FILE=path/to/service-account-key.json
```

### **🗺️ Google Maps (Optional):**
```env
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### **🔔 Push Notifications (Optional):**
```env
FIREBASE_SERVER_KEY=your-firebase-server-key
```

## 🔍 **How to Check Current Variables:**

1. **In Render Dashboard:**
   - Go to your service dashboard
   - Click on "Environment" tab
   - Review all environment variables

2. **Via API Test:**
   ```bash
   node check-render-env.js
   ```

## ⚠️ **Potential Issues:**

### **Missing Critical Variables:**
- `JWT_SECRET` - Required for authentication
- `MONGODB_URI` - Required for database connection
- `EMAIL_PROVIDER` - Should be "gmail"
- `GMAIL_USER` - Your Gmail address
- `GMAIL_APP_PASSWORD` - 16-character app password

### **Incorrect Values:**
- `NODE_ENV` should be "production"
- `EMAIL_PROVIDER` should be "gmail" (not "development")
- `FRONTEND_URL` should point to your web app

## 🛠️ **How to Fix:**

### **1. Add Missing Variables in Render:**
1. Go to your Render dashboard
2. Select your service
3. Go to "Environment" tab
4. Add the missing variables

### **2. Update Email Configuration:**
```env
EMAIL_PROVIDER=gmail
GMAIL_USER=your-actual-gmail@gmail.com
GMAIL_APP_PASSWORD=your-actual-16-char-password
EMAIL_FROM=your-actual-gmail@gmail.com
```

### **3. Verify Database Connection:**
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database
```

### **4. Set JWT Secret:**
```env
JWT_SECRET=your-super-secure-jwt-secret-32+characters-long
```

## 🧪 **Testing After Changes:**

1. **Test Email Service:**
   ```bash
   node test-production-email.js
   ```

2. **Test Environment:**
   ```bash
   node check-render-env.js
   ```

3. **Test Web Application:**
   - Try password reset functionality
   - Check if emails are sent (not just logged)

## 📊 **Current Status:**

- ✅ **Server**: Running correctly
- ✅ **Database**: Connected
- ✅ **CORS**: Working
- ⚠️ **Email**: Logging to console (needs Gmail credentials)
- ⚠️ **Environment**: Some variables may be missing

## 🎯 **Next Steps:**

1. **Add Gmail credentials** to enable actual email sending
2. **Verify JWT_SECRET** is set for authentication
3. **Check MONGODB_URI** is correct
4. **Test email functionality** after adding credentials

The application is working correctly, but adding the Gmail credentials will enable actual email sending instead of just logging to console. 