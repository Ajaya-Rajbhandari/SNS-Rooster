# Network Connectivity Troubleshooting Guide

## Problem Summary

The User Management screen in the SNS Rooster Flutter app was displaying "Network error occurred" when trying to connect to the backend API from the Android emulator.

## Root Causes Identified

### 1. Backend Server Network Binding Issue
**Problem**: The Node.js backend server was only listening on `localhost` (127.0.0.1) by default, making it inaccessible from external networks including the Android emulator.

**Technical Details**:
- Default `app.listen(PORT)` binds only to localhost
- Android emulator runs in a separate network namespace
- Emulator cannot reach host's localhost directly

### 2. Incorrect API Base URL Configuration
**Problem**: The Flutter app was configured to use `http://10.0.2.2:5000/api` which is the standard Android emulator gateway, but the server wasn't accessible on this address.

**Technical Details**:
- `10.0.2.2` is the special IP that Android emulator uses to reach the host machine
- This only works if the host service is bound to all network interfaces

## Solutions Implemented

### 1. Backend Server Configuration Fix

**File Modified**: `rooster-backend/server.js`

```javascript
// Before (problematic)
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

// After (fixed)
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces
app.listen(PORT, HOST, () => {
  console.log(`Server is running on ${HOST}:${PORT}`);
});
```

**What this fixes**:
- `0.0.0.0` binds the server to all available network interfaces
- Makes the server accessible from localhost, LAN, and emulator networks
- Allows environment variable override for production deployments

### 2. Frontend API Configuration Update

**File Modified**: `sns_rooster/lib/screens/admin/user_management_screen.dart`

```dart
// Updated to use actual host IP address
final String _baseUrl = 'http://192.168.1.67:5000/api'; // Use actual IP address for emulator access
```

**What this fixes**:
- Uses the actual IP address of the host machine
- Ensures reliable connectivity from Android emulator
- Provides fallback when `10.0.2.2` doesn't work

## Testing and Verification

### 1. Backend Accessibility Tests
Created test scripts to verify server accessibility:

```javascript
// test-ip-connection.js - Tests both localhost and IP connectivity
const testConnection = (host, port) => {
  // HTTP request to /api/auth/login endpoint
  // Verifies server responds on both localhost and IP address
};
```

### 2. Network Connectivity Verification
- Confirmed server responds on `localhost:5000` ✅
- Confirmed server responds on `192.168.1.67:5000` ✅
- Verified API endpoints return proper responses ✅

## Best Practices for Future Development

### 1. Server Configuration

**Always bind to all interfaces in development**:
```javascript
// Recommended approach
const HOST = process.env.HOST || '0.0.0.0';
app.listen(PORT, HOST, callback);
```

**Environment-specific configuration**:
```javascript
// Use environment variables for flexibility
const HOST = process.env.NODE_ENV === 'production' 
  ? process.env.HOST || 'localhost'
  : '0.0.0.0';
```

### 2. Flutter App Configuration

**Use conditional base URLs**:
```dart
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid) {
      // Try emulator gateway first, fallback to IP
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }
}
```

**Create environment-specific configurations**:
```dart
// config/api_config.dart
class ApiConfig {
  static const String devBaseUrl = 'http://192.168.1.67:5000/api';
  static const String prodBaseUrl = 'https://api.snsrooster.com/api';
  
  static String get baseUrl => kDebugMode ? devBaseUrl : prodBaseUrl;
}
```

### 3. Network Debugging Tools

**Create debugging utilities**:
```dart
// services/network_debug.dart
class NetworkDebug {
  static Future<bool> testConnectivity(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode < 500;
    } catch (e) {
      print('Network test failed: $e');
      return false;
    }
  }
}
```

### 4. Development Workflow

**Pre-development checklist**:
1. ✅ Verify backend server binds to `0.0.0.0`
2. ✅ Test API accessibility from host machine
3. ✅ Test API accessibility from emulator network
4. ✅ Configure appropriate base URLs for each platform
5. ✅ Add network error handling in Flutter app

**Debugging steps for network issues**:
1. Check server logs for incoming requests
2. Test API endpoints with curl/Postman from host
3. Test API endpoints from emulator network
4. Verify firewall settings don't block connections
5. Check if antivirus software interferes with local servers

## Common Network Issues and Solutions

### Issue: "Connection refused" errors
**Cause**: Server not running or wrong port
**Solution**: Verify server is running and check port configuration

### Issue: "Network unreachable" from emulator
**Cause**: Server bound to localhost only
**Solution**: Bind server to `0.0.0.0` or specific IP address

### Issue: "Timeout" errors
**Cause**: Firewall blocking connections or wrong IP address
**Solution**: Check firewall settings and verify host IP address

### Issue: API endpoints return 404
**Cause**: Incorrect route configuration or base URL
**Solution**: Verify route mounting and API endpoint paths

## Security Considerations

### Development vs Production
- **Development**: Binding to `0.0.0.0` is acceptable for local development
- **Production**: Use specific IP addresses or localhost with proper reverse proxy

### Firewall Configuration
- Ensure development ports are only accessible from trusted networks
- Use environment variables for sensitive configuration
- Never commit IP addresses or ports to version control for production

## Monitoring and Logging

### Server-side logging
```javascript
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} from ${req.ip}`);
  next();
});
```

### Client-side error handling
```dart
try {
  final response = await http.get(Uri.parse(url));
  // Handle response
} on SocketException catch (e) {
  print('Network error: $e');
  // Show user-friendly error message
} on TimeoutException catch (e) {
  print('Request timeout: $e');
  // Handle timeout
}
```

This documentation should be referenced whenever setting up new development environments or troubleshooting network connectivity issues in the SNS Rooster application.