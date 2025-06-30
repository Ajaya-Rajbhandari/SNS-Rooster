# 🚀 Automatic IP Detection Guide

## Overview

This guide explains how to use the new **Automatic IP Detection System** that eliminates the need to manually update IP addresses when switching between different networks (home, office, etc.) or when running the app on physical devices.

## ✨ What's New

### 1. **Automatic IP Detection**
- The Flutter app now automatically detects your current local IP address
- No more manual updates to `fallbackIP` in `api_config.dart`
- Works across different networks and locations

### 2. **PowerShell Auto-Configuration Script**
- `auto-detect-ip.ps1` automatically detects your IP and updates the configuration
- Tests backend connectivity
- Provides detailed network information

### 3. **Dynamic API Service**
- `DynamicApiService` handles all API calls with automatic IP detection
- Caches detected IP for performance
- Provides network status and debugging information

## 🛠️ How to Use

### Method 1: PowerShell Script (Recommended)

1. **Run the auto-detection script:**
   ```powershell
   # Basic usage
   .\auto-detect-ip.ps1
   
   # Force update even if IP hasn't changed
   .\auto-detect-ip.ps1 -Force
   
   # Show detailed network information
   .\auto-detect-ip.ps1 -Verbose
   ```

2. **The script will:**
   - 🔍 Detect your current local IP address
   - 📝 Update the Flutter configuration automatically
   - 🧪 Test backend connectivity
   - 📋 Show you what to do next

3. **Start your Flutter app:**
   ```bash
   cd sns_rooster
   flutter run
   ```

### Method 2: Use Dynamic API Service in Code

Instead of hardcoded URLs, use the `DynamicApiService`:

```dart
import 'package:your_app/services/dynamic_api_service.dart';

class YourService {
  final _apiService = DynamicApiService.instance;
  
  Future<void> fetchData() async {
    try {
      // Automatically uses detected IP
      final response = await _apiService.get('users');
      
      if (response.statusCode == 200) {
        // Handle success
      }
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> uploadData(Map<String, dynamic> data) async {
    try {
      // Automatically uses detected IP
      final response = await _apiService.post(
        'users',
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 201) {
        // Handle success
      }
    } catch (e) {
      // Handle error
    }
  }
}
```

### Method 3: Network Status Widget

Add the `NetworkStatusWidget` to your app to monitor network status:

```dart
import 'package:your_app/widgets/network_status_widget.dart';

class DebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Debug')),
      body: Column(
        children: [
          NetworkStatusWidget(), // Shows current network status
          // Your other widgets...
        ],
      ),
    );
  }
}
```

## 🔧 Configuration Options

### Environment Variables

You can still override the automatic detection with environment variables:

```bash
# Force a specific IP
flutter run --dart-define=API_HOST=192.168.1.100

# Use localhost for web development
flutter run --dart-define=API_HOST=localhost
```

### Manual Configuration

If you prefer manual configuration, you can still update `api_config.dart`:

```dart
class ApiConfig {
  static const String fallbackIP = '192.168.1.68'; // Your IP here
  // ... rest of configuration
}
```

## 📱 Platform-Specific Behavior

| Platform | Behavior |
|----------|----------|
| **Web** | Always uses `localhost` |
| **Android Emulator** | Uses `10.0.2.2` (emulator gateway) |
| **iOS Simulator** | Uses `localhost` |
| **Physical Android/iOS** | Automatically detects local IP |
| **Desktop** | Uses `localhost` |

## 🧪 Testing the Setup

### 1. Test Backend Connectivity

```bash
# Test if backend is running
node test-backend.js

# Test network connectivity
node test-ip-connection.js
```

### 2. Test Flutter App

```bash
cd sns_rooster
flutter run
```

### 3. Use Network Status Widget

Add the `NetworkStatusWidget` to any screen to see:
- ✅ Detected IP address
- ✅ Base URL being used
- ✅ Connection status
- 🔄 Refresh button to retest
- 🗑️ Clear cache button

## 🔍 Troubleshooting

### "Could not detect local IP address"

**Causes:**
- No active network connection
- Only virtual/loopback interfaces available
- Network adapter issues

**Solutions:**
1. Check your network connection
2. Run `ipconfig` (Windows) or `ifconfig` (macOS/Linux) to verify IP
3. Try the verbose mode: `.\auto-detect-ip.ps1 -Verbose`

### "Backend server not reachable"

**Causes:**
- Backend server not running
- Firewall blocking connections
- Wrong port configuration

**Solutions:**
1. Start the backend server: `cd rooster-backend && npm start`
2. Check if server is listening on `0.0.0.0:5000`
3. Verify firewall settings
4. Test with: `node test-ip-connection.js`

### "App still shows network errors"

**Causes:**
- Flutter app needs complete restart
- Cached configuration
- Multiple network interfaces

**Solutions:**
1. **Completely restart Flutter app** (not just hot reload)
2. Clear cache in the Network Status Widget
3. Run: `flutter clean && flutter pub get`
4. Check the Network Status Widget for current configuration

## 📋 Quick Start Checklist

### Before Running on Physical Device:

1. ✅ **Start Backend Server**
   ```bash
   cd rooster-backend
   npm start
   ```

2. ✅ **Run Auto-Detection**
   ```powershell
   .\auto-detect-ip.ps1
   ```

3. ✅ **Verify Backend is Reachable**
   - Script should show "✅ Backend server is reachable"

4. ✅ **Start Flutter App**
   ```bash
   cd sns_rooster
   flutter run
   ```

5. ✅ **Test on Physical Device**
   - Connect your device to the same network
   - Run the app and test login/API calls

## 🎯 Benefits

### ✅ **No More Manual IP Updates**
- Automatically works on any network
- Switch between home/office seamlessly
- No more forgetting to update IP addresses

### ✅ **Better Development Experience**
- Faster setup on new networks
- Reduced configuration errors
- Built-in network diagnostics

### ✅ **Production Ready**
- Graceful fallbacks if detection fails
- Environment variable overrides
- Comprehensive error handling

## 🔄 Migration from Old System

If you're currently using hardcoded URLs:

1. **Replace hardcoded URLs:**
   ```dart
   // Old way
   final String _baseUrl = 'http://192.168.1.68:5000/api';
   
   // New way
   final _apiService = DynamicApiService.instance;
   final baseUrl = await _apiService.baseUrl;
   ```

2. **Update API calls:**
   ```dart
   // Old way
   final response = await http.get('$_baseUrl/users');
   
   // New way
   final response = await _apiService.get('users');
   ```

3. **Test thoroughly:**
   - Test on different networks
   - Test with Network Status Widget
   - Verify all API endpoints work

## 📞 Support

If you encounter issues:

1. **Check the Network Status Widget** for current configuration
2. **Run the auto-detection script** with verbose mode
3. **Review the troubleshooting section** above
4. **Check backend server logs** for connection attempts

---

**🎉 You're all set!** The app will now automatically work on any network without manual IP configuration. 