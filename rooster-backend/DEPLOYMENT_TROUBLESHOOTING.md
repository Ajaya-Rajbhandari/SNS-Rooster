# Deployment Troubleshooting Guide

## 🚨 Current Issue: Backend Not Deploying on Render

Based on the logs showing "Instance failed: f85k2" with memory usage over 256MB, here are the steps to fix the deployment:

## ✅ Immediate Fixes Applied

### 1. **Fixed Start Script**
- **Problem**: `package.json` was using `nodemon` for production
- **Fix**: Changed `"start": "nodemon server.js"` to `"start": "node server.js"`
- **Why**: Render needs a production-ready start command, not development tools

### 2. **Added Render Configuration**
- Created `render.yaml` with proper deployment settings
- Set memory limit to 512MB
- Added health check path

## 🔧 Manual Deployment Steps

### Step 1: Commit and Push Changes
```bash
cd rooster-backend
git add .
git commit -m "Fix deployment: Update start script and add Render config"
git push origin main
```

### Step 2: Check Render Dashboard
1. Go to your Render dashboard
2. Check if the service is building
3. Look for any build errors in the logs

### Step 3: Verify Environment Variables
Make sure these are set in Render:
```
NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=512
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
```

## 🚨 Common Deployment Issues

### Issue 1: Build Fails
**Symptoms**: Build process fails during `npm install`
**Solutions**:
- Check if all dependencies are in `package.json`
- Remove `node_modules` from git if present
- Ensure `package-lock.json` is committed

### Issue 2: Memory Limit Exceeded
**Symptoms**: Instance fails with "used over 256MB"
**Solutions**:
- ✅ Already fixed: Updated start script
- ✅ Already fixed: Added memory optimization middleware
- ✅ Already fixed: Set NODE_OPTIONS in render.yaml

### Issue 3: Port Issues
**Symptoms**: Service shows as unhealthy
**Solutions**:
- ✅ Already fixed: Server listens on `0.0.0.0:PORT`
- ✅ Already fixed: Health check endpoint at `/health`

### Issue 4: Database Connection
**Symptoms**: Service starts but database operations fail
**Solutions**:
- Verify `MONGODB_URI` is correct in Render environment variables
- Check if MongoDB Atlas IP whitelist includes Render's IPs

## 🔍 Debugging Steps

### 1. Check Local Server
```bash
cd rooster-backend
npm start
```
Should show: "Server is running on 0.0.0.0:5000"

### 2. Test Health Endpoint
```bash
curl http://localhost:5000/health
```
Should return JSON with status: "healthy"

### 3. Check Memory Usage
```bash
npm run memory-monitor
```
Monitor for memory leaks

### 4. Check Render Logs
1. Go to Render dashboard
2. Click on your service
3. Go to "Logs" tab
4. Look for error messages

## 📊 Expected Log Output

When deployment is successful, you should see:
```
✅ Email service initialized with Gmail
DEBUG: FCM - Firebase Admin SDK initialized successfully
✅ Environment variables validated successfully
Connected to MongoDB
✅ MongoDB connection established
Server is running on 0.0.0.0:5000
```

## 🚨 Emergency Actions

If deployment still fails:

### 1. Force Redeploy
- Go to Render dashboard
- Click "Manual Deploy"
- Select "Clear build cache & deploy"

### 2. Check Build Logs
Look for these specific errors:
- `ENOENT: no such file or directory` → Missing files
- `EADDRINUSE` → Port conflict
- `ECONNREFUSED` → Database connection issue
- `ENOMEM` → Memory issue

### 3. Rollback if Needed
- Go to Render dashboard
- Click "Deploys" tab
- Find last working deployment
- Click "Rollback"

## 🔧 Advanced Troubleshooting

### Memory Optimization
If memory issues persist:
1. Reduce response size limits further (from 50MB to 25MB)
2. Implement more aggressive caching
3. Add database query limits

### Database Issues
If MongoDB connection fails:
1. Check connection string format
2. Verify network access
3. Test connection locally

### Environment Variables
If environment variables are missing:
1. Check Render dashboard → Environment
2. Verify all required variables are set
3. Restart service after adding variables

## 📞 Next Steps

1. **Commit the changes** I made to fix the start script
2. **Push to your repository**
3. **Check Render dashboard** for deployment status
4. **Monitor the logs** for any remaining issues
5. **Test the health endpoint** once deployed

## 🎯 Success Indicators

Your deployment is successful when:
- ✅ Build completes without errors
- ✅ Service shows "Live" status in Render
- ✅ Health check returns 200 OK
- ✅ No memory limit warnings in logs
- ✅ Database connection established

---

**Last Updated**: January 6, 2025
**Status**: Ready for deployment 