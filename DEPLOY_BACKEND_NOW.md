# 🚀 DEPLOY BACKEND NOW - QUICK GUIDE

## 🔧 **IMMEDIATE BACKEND DEPLOYMENT**

Your frontend is deployed but needs the backend to work with real data. Here's how to deploy the backend quickly:

### **Option 1: Render.com (Recommended - 5 minutes)**

1. **Go to [render.com](https://render.com)**
2. **Sign up/Login with GitHub**
3. **Click "New +" → "Web Service"**
4. **Connect your repository:** `https://github.com/Ajaya-Rajbhandari/SNS-Rooster`
5. **Configure:**
   - **Name:** `sns-rooster-backend`
   - **Root Directory:** `rooster-backend`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Plan:** Free

6. **Set Environment Variables:**
   ```
   MONGODB_URI=mongodb+srv://ajaya:Rx5IfjM5G32uws52@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0
   JWT_SECRET=5b990024ffc80d003af6e100d704f86372442f298db47ba03b3de14a94179578b0b5fbe0a97f69bf377d38ce19
   NODE_ENV=production
   PORT=5000
   FIREBASE_PROJECT_ID=sns-rooster-8cca5
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@sns-rooster-8cca5.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY=your-private-key-here
   ALLOWED_ORIGINS=https://sns-rooster-8cca5.web.app,https://sns-rooster-admin.web.app
   ```

7. **Click "Create Web Service"**

### **Option 2: Railway (Even Faster - 3 minutes)**

1. **Go to [railway.app](https://railway.app)**
2. **Sign up/Login with GitHub**
3. **Click "New Project" → "Deploy from GitHub repo"**
4. **Select your repository**
5. **Set Root Directory to:** `rooster-backend`
6. **Add environment variables (same as above)**
7. **Deploy automatically**

## 🔗 **After Backend Deployment:**

Once your backend is deployed, you'll get a URL like:
- Render: `https://sns-rooster-backend.onrender.com`
- Railway: `https://sns-rooster-backend-production.up.railway.app`

### **Update Flutter App API URL:**

Update `sns_rooster/lib/config/api_config.dart`:
```dart
static const String productionApiUrl = 'https://your-backend-url.onrender.com/api';
```

### **Rebuild and Redeploy Flutter App:**
```bash
cd sns_rooster
flutter build web --release
firebase deploy --only hosting
```

## ✅ **What Will Work After Backend Deployment:**

- ✅ Performance Reviews with real data
- ✅ User authentication
- ✅ Company management
- ✅ Employee management
- ✅ Attendance tracking
- ✅ All API features

## 🎯 **Quick Test:**

After backend deployment, test these URLs:
- **Flutter App:** https://sns-rooster-8cca5.web.app
- **Admin Portal:** https://sns-rooster-admin.web.app
- **Backend API:** https://your-backend-url.onrender.com/api/health

**The Performance Reviews feature will work with real data once the backend is deployed!** 