# SNS Rooster Multi-App Setup Guide

This guide explains how to run all three applications simultaneously:
1. **Backend Server** (Node.js) - Port 5000
2. **Flutter Web App** (Frontend) - Port 3000  
3. **Admin Portal** (React) - Port 3001

## Quick Start (Recommended)

### Option 1: Use the Startup Script
```powershell
# Run the automated startup script
.\start-all-apps.ps1
```

This script will:
- Check port availability
- Start all three applications in separate windows
- Display the URLs for each application

### Option 2: Manual Startup

#### 1. Start Backend Server
```powershell
cd rooster-backend
npm install
npm run dev
```
**URL**: http://localhost:5000

#### 2. Start Flutter Web App
```powershell
cd sns_rooster
flutter pub get
flutter run -d chrome --web-port 3000
```
**URL**: http://localhost:3000

#### 3. Start Admin Portal
```powershell
cd admin-portal
npm install
npm start
```
**URL**: http://localhost:3001

## Application URLs

| Application | URL | Description |
|-------------|-----|-------------|
| Backend API | http://localhost:5000 | Node.js/Express server |
| Flutter Web | http://localhost:3000 | Main SNS Rooster app |
| Admin Portal | http://localhost:3001 | React admin interface |

## Port Configuration

### Backend (Port 5000)
- Configured in `rooster-backend/server.js`
- CORS allows both `localhost:3000` and `localhost:3001`

### Flutter Web (Port 3000)
- Default Flutter web port
- Configured with `--web-port 3000` flag

### Admin Portal (Port 3001)
- Configured in `admin-portal/package.json`
- Uses `set PORT=3001` in start script

## API Configuration

### Backend CORS Settings
```javascript
// rooster-backend/app.js
app.use(cors({
  origin: [
    'https://sns-rooster-8cca5.web.app',
    'https://sns-rooster.onrender.com',
    'http://localhost:3000',  // Flutter web app
    'http://localhost:3001',  // Admin portal
    'http://192.168.1.119:8080'
  ],
  credentials: true,
}));
```

### Admin Portal API Configuration
```typescript
// admin-portal/src/config/api.ts
const API_CONFIG = {
  BASE_URL: process.env.REACT_APP_API_BASE_URL || 'http://localhost:5000',
  // ... other config
};
```

### Flutter Web API Configuration
```dart
// sns_rooster/lib/config/api_config.dart
static String _getDevBaseUrl() {
  if (kIsWeb) {
    const url = 'http://localhost:$devPort/api'; // devPort = '5000'
    return url;
  }
  // ... other platforms
}
```

## Troubleshooting

### Port Already in Use
If you get "port already in use" errors:

1. **Find processes using the port:**
   ```powershell
   netstat -ano | findstr :5000
   netstat -ano | findstr :3000
   netstat -ano | findstr :3001
   ```

2. **Kill the process:**
   ```powershell
   taskkill /PID <process_id> /F
   ```

### CORS Errors
If you see CORS errors in the browser console:

1. Ensure backend is running on port 5000
2. Check that CORS configuration includes both frontend ports
3. Restart the backend server after CORS changes

### Flutter Web Issues
If Flutter web app doesn't start:

1. Ensure Flutter is properly installed
2. Run `flutter doctor` to check setup
3. Try `flutter clean` then `flutter pub get`

### Admin Portal Issues
If admin portal doesn't start:

1. Ensure Node.js is installed
2. Run `npm install` in admin-portal directory
3. Check for any missing dependencies

## Development Workflow

### Typical Development Session
1. Start all applications using the startup script
2. Make changes to backend code (auto-reloads)
3. Make changes to Flutter code (hot reload)
4. Make changes to admin portal code (auto-reloads)
5. Test functionality across all applications

### API Testing
- Backend API: http://localhost:5000
- Test endpoints directly or use tools like Postman
- Both frontend apps will automatically connect to the backend

### Database Access
- MongoDB should be running locally or accessible
- Backend connects to MongoDB and serves data to both frontends

## Production Deployment

For production, you'll typically:
1. Deploy backend to a cloud service (e.g., Render, Heroku)
2. Deploy Flutter web to Firebase Hosting
3. Deploy admin portal to a separate hosting service
4. Update API URLs in both frontend applications

## Support

If you encounter issues:
1. Check the console output for each application
2. Verify all ports are available
3. Ensure MongoDB is running
4. Check network connectivity
5. Review the troubleshooting section above 