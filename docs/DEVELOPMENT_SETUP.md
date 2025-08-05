# Development Setup Guide

## Quick Start

### Backend Setup
1. Navigate to `rooster-backend` directory
2. Install dependencies: `npm install`
3. Start server: `npm start` or `node server.js`
4. Server will run on `http://0.0.0.0:5000` (accessible from all network interfaces)

### Frontend Setup
1. Navigate to `sns_rooster` directory
2. Install dependencies: `flutter pub get`
3. Run app: `flutter run`
4. Choose target device (Android emulator, iOS simulator, or web)

## Network Configuration

### Backend Server Configuration
The backend server is configured to listen on all network interfaces (`0.0.0.0`) to ensure accessibility from:
- Localhost (development)
- Android emulator (`10.0.2.2` or host IP)
- Physical devices on same network
- Web browsers

### Frontend API Configuration
The Flutter app uses different base URLs depending on the platform:

```dart
// Current configuration in user_management_screen.dart
final String _baseUrl = 'http://192.168.1.67:5000/api';
```

**Platform-specific URLs:**
- **Android Emulator**: `http://10.0.2.2:5000/api` or `http://[HOST_IP]:5000/api`
- **iOS Simulator**: `http://localhost:5000/api`
- **Web**: `http://localhost:5000/api`
- **Physical Device**: `http://[HOST_IP]:5000/api`

### 🏢 Working from Different Locations (Office vs Home)

**IMPORTANT**: Remember to update the API base URL when switching between work environments!

#### Quick Environment Switch Checklist

**Before starting development:**
1. ✅ Check your current IP address: `ipconfig` (Windows) or `ifconfig` (macOS/Linux)
2. ✅ Update the base URL in Flutter app
3. ✅ Test backend connectivity
4. ✅ Verify emulator can reach the backend

#### Environment-Specific Configuration

**Home Network Example:**
```dart
// user_management_screen.dart
final String _baseUrl = 'http://192.168.1.67:5000/api'; // Home IP
```

**Office Network Example:**
```dart
// user_management_screen.dart
final String _baseUrl = 'http://10.0.0.45:5000/api'; // Office IP
```

#### Automated Solution (Recommended)

Create a configuration file to avoid manual URL changes:

**Step 1: Create config file**
```dart
// lib/config/api_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Add your network IPs here
  static const String homeIP = '192.168.1.67';
  static const String officeIP = '10.0.0.45';
  static const String port = '5000';
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    } else if (Platform.isAndroid) {
      // Try to detect network or use environment variable
      String ip = const String.fromEnvironment('API_HOST', defaultValue: homeIP);
      return 'http://$ip:$port/api';
    } else {
      return 'http://localhost:$port/api';
    }
  }
  
  // Alternative: Auto-detect based on network
  static Future<String> getAutoDetectedBaseUrl() async {
    // You can implement network detection logic here
    // For now, return default
    return baseUrl;
  }
}
```

**Step 2: Update user_management_screen.dart**
```dart
// Replace the hardcoded URL with:
import '../config/api_config.dart';

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Replace hardcoded URL
  final String _baseUrl = ApiConfig.baseUrl;
  // ... rest of the code
}
```

**Step 3: Run with environment variable**
```bash
# For home network
flutter run --dart-define=API_HOST=192.168.1.67

# For office network
flutter run --dart-define=API_HOST=10.0.0.45
```

#### Quick IP Detection Commands

**Windows:**
```cmd
ipconfig | findstr "IPv4"
```

**macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**PowerShell (Windows):**
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*"} | Select-Object IPAddress
```

#### Environment Switch Script

Create a helper script to quickly switch environments:

**switch-environment.ps1** (Windows PowerShell):
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("home", "office")]
    [string]$Environment
)

$homeIP = "192.168.1.67"
$officeIP = "10.0.0.45"

switch ($Environment) {
    "home" { 
        Write-Host "Switching to HOME environment ($homeIP)"
        $targetIP = $homeIP
    }
    "office" { 
        Write-Host "Switching to OFFICE environment ($officeIP)"
        $targetIP = $officeIP
    }
}

# Update the user_management_screen.dart file
$filePath = "sns_rooster\lib\screens\admin\user_management_screen.dart"
$content = Get-Content $filePath -Raw
$pattern = "final String _baseUrl = 'http://[^']+'"
$replacement = "final String _baseUrl = 'http://$targetIP:5000/api'"
$newContent = $content -replace $pattern, $replacement
Set-Content $filePath $newContent

Write-Host "✅ Updated API URL to: http://$targetIP:5000/api"
Write-Host "🔄 Remember to restart your Flutter app!"
```

**Usage:**
```powershell
# Switch to home network
.\switch-environment.ps1 -Environment home

# Switch to office network
.\switch-environment.ps1 -Environment office
```

#### Troubleshooting Network Switches

**If app shows "Network error" after switching:**
1. Verify your new IP address: `ipconfig`
2. Check if backend server is running: `node test-backend.js`
3. Test connectivity from new network: `node test-ip-connection.js`
4. Restart Flutter app completely
5. Clear app cache if needed

**Common mistakes:**
- ❌ Forgetting to restart Flutter app after URL change
- ❌ Using old IP address from previous network
- ❌ Backend server not running on new network
- ❌ Firewall blocking connections on new network

## Common Issues and Solutions

### "Network error occurred" in Flutter app
**Cause**: Backend server not accessible from emulator/device

**Solutions:**
1. Ensure backend server is running
2. Verify server binds to `0.0.0.0` (check `server.js`)
3. Update Flutter app base URL to use correct host IP
4. Check firewall settings

**Quick fix:**
```bash
# Get your IP address
ipconfig  # Windows
ifconfig  # macOS/Linux

# Update base URL in Flutter app to use your IP
# Example: http://192.168.1.67:5000/api
```

### API endpoints returning 404
**Cause**: Incorrect route configuration

**Check:**
- Route mounting in `server.js`
- Endpoint paths in Flutter app
- API base URL configuration

**Example correct endpoints:**
- Login: `POST /api/auth/login`
- Users: `GET /api/auth/users`
- Update user: `PATCH /api/auth/users/:id`

## Testing Network Connectivity

### Backend API Testing
Use the provided test scripts:

```bash
# Test basic connectivity
node test-backend.js

# Test from emulator perspective
node test-emulator-connection.js

# Test both localhost and IP
node test-ip-connection.js

# Test users API with authentication
node test-users-api.js
```

### Manual Testing
```bash
# Test server accessibility
curl http://localhost:5000
curl http://192.168.1.67:5000

# Test login endpoint
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

## Environment Variables

### Backend (.env file)
```env
PORT=5000
HOST=0.0.0.0
JWT_SECRET=your_jwt_secret
MONGODB_URI=mongodb://localhost:27017/sns_rooster
```

### Flutter (Environment-specific configs)
Create different configuration files for different environments:

```dart
// config/dev_config.dart
class DevConfig {
  static const String apiBaseUrl = 'http://192.168.1.67:5000/api';
  static const bool debugMode = true;
}

// config/prod_config.dart
class ProdConfig {
  static const String apiBaseUrl = 'https://api.snsrooster.com/api';
  static const bool debugMode = false;
}
```

## Development Workflow

### Starting Development Session
1. **Start Backend Server**
   ```bash
   cd rooster-backend
   node server.js
   ```
   
2. **Verify Server Accessibility**
   ```bash
   node test-backend.js
   ```
   
3. **Start Flutter App**
   ```bash
   cd sns_rooster
   flutter run
   ```
   
4. **Test Network Connectivity**
   - Open User Management screen
   - Verify users load without "Network error"
   - Test create/update user functionality

### Debugging Network Issues
1. Check backend server logs
2. Run network connectivity tests
3. Verify API endpoints with curl/Postman
4. Check Flutter app error logs
5. Verify firewall/antivirus settings

## 🚀 App Update Workflow (CRITICAL)

**IMPORTANT**: Every time you add new features to the app, you MUST follow this update workflow to ensure the app update system works correctly.

### Quick Deployment (Recommended)
```powershell
# From sns_rooster directory
.\scripts\deploy-app-update.ps1 -NewVersion "1.0.4" -NewBuildNumber "5" -FeatureDescription "new feature description"
```

### Manual Update Process
1. **Update Version in pubspec.yaml**
   ```yaml
   version: 1.0.4+5  # Increment both version and build number
   ```

2. **Build New APK**
   ```bash
   flutter build apk --release
   ```

3. **Update Backend Configuration (CRITICAL)**
   ```javascript
   // In rooster-backend/routes/appVersionRoutes.js
   android: {
     latest_version: '1.0.5',        // NEXT version (not 1.0.4)
     latest_build_number: '6',        // NEXT build number
     // ... rest of config
   }
   ```

4. **Deploy APK to Backend**
   ```bash
   copy "build\app\outputs\flutter-apk\app-release.apk" "..\rooster-backend\downloads\sns-rooster.apk"
   cd ..\rooster-backend
   git add downloads/sns-rooster.apk
   git commit -m "Deploy version 1.0.4 APK"
   git push origin main
   ```

5. **Deploy Backend Changes**
   ```bash
   git add routes/appVersionRoutes.js
   git commit -m "Update backend to expect v1.0.5"
   git push origin main
   ```

6. **Test Update Flow**
   ```bash
   cd ..\sns_rooster
   flutter install --release
   ```

### ⚠️ Critical Rules
1. **Always increment both version AND build number**
2. **Backend expects NEXT version, not current version**
3. **Deploy APK first, then backend config**
4. **Test the complete flow before releasing**

### 📚 Documentation
- **Complete Workflow**: `docs/APP_UPDATE_WORKFLOW.md`
- **Quick Reference**: `docs/QUICK_UPDATE_GUIDE.md`
- **System Summary**: `docs/UPDATE_SYSTEM_SUMMARY.md`

## Production Deployment Considerations

### Backend
- Use environment variables for configuration
- Bind to specific IP address, not `0.0.0.0`
- Use reverse proxy (nginx/Apache)
- Enable HTTPS
- Configure proper CORS settings

### Frontend
- Use production API URLs
- Enable release mode optimizations
- Configure proper error handling
- Use secure HTTP client settings

## Troubleshooting Resources

- **Detailed Network Troubleshooting**: See `docs/NETWORK_TROUBLESHOOTING.md`
- **API Documentation**: See `docs/api/API_CONTRACT.md`
- **System Architecture**: See `docs/SYSTEM_ARCHITECTURE.md`

## Support

If you encounter issues not covered in this guide:
1. Check the troubleshooting documentation
2. Review server and Flutter app logs
3. Test network connectivity with provided scripts
4. Verify environment configuration

For persistent issues, document:
- Error messages
- Network configuration
- Platform/device information
- Steps to reproduce