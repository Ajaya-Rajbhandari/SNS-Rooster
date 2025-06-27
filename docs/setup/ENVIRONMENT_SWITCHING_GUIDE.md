# 🔄 Environment Switching Quick Guide

> **Problem**: Always forgetting to change the URL address between localhost and machine IP when working from different locations (office vs home).

## 🚀 Quick Solutions

### Method 1: PowerShell Script (Fastest)

```powershell
# Switch to home network
.\switch-environment.ps1 -Environment home

# Switch to office network
.\switch-environment.ps1 -Environment office
```

### Method 2: Environment Variables (Recommended)

```bash
# For home network
flutter run --dart-define=API_HOST=192.168.1.67

# For office network
flutter run --dart-define=API_HOST=10.0.0.45
```

### Method 3: Manual Update

Edit `sns_rooster\lib\screens\admin\user_management_screen.dart`:

```dart
// Home network
final String _baseUrl = 'http://192.168.1.67:5000/api';

// Office network (update IP as needed)
final String _baseUrl = 'http://10.0.0.45:5000/api';
```

## 📋 Before You Start Development

### 1. Check Your Current IP
```cmd
ipconfig | findstr "IPv4"
```

### 2. Update Configuration
Choose one of the methods above

### 3. Test Backend Connection
```bash
node test-ip-connection.js
```

### 4. Restart Flutter App
Completely restart (not just hot reload)

## 🏠🏢 Network-Specific Setup

| Location | IP Address | Configuration |
|----------|------------|---------------|
| **Home** | `192.168.1.67` | Already configured |
| **Office** | `10.0.0.45` | ⚠️ **Update this IP!** |

## 🛠️ Advanced Setup (One-time)

### Option A: Use ApiConfig Class

1. **Import the config** in `user_management_screen.dart`:
```dart
import '../config/api_config.dart';

class _UserManagementScreenState extends State<UserManagementScreen> {
  final String _baseUrl = ApiConfig.baseUrl;
  // ... rest of code
}
```

2. **Run with environment variable**:
```bash
flutter run --dart-define=API_HOST=192.168.1.67  # Home
flutter run --dart-define=API_HOST=10.0.0.45     # Office
```

### Option B: Create VS Code Tasks

Add to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Flutter Run (Home)",
      "type": "shell",
      "command": "flutter",
      "args": ["run", "--dart-define=API_HOST=192.168.1.67"],
      "group": "build"
    },
    {
      "label": "Flutter Run (Office)",
      "type": "shell",
      "command": "flutter",
      "args": ["run", "--dart-define=API_HOST=10.0.0.45"],
      "group": "build"
    }
  ]
}
```

## 🚨 Troubleshooting

### "Network error occurred" after switching?

1. **Verify IP**: `ipconfig`
2. **Check backend**: `node test-backend.js`
3. **Test connectivity**: `node test-ip-connection.js`
4. **Restart Flutter app** (completely)
5. **Clear cache**: `flutter clean && flutter pub get`

### Common Mistakes
- ❌ Forgetting to restart Flutter app
- ❌ Using old IP from previous network
- ❌ Backend not running on new network
- ❌ Firewall blocking connections

## 📱 Platform-Specific Notes

| Platform | URL Format | Notes |
|----------|------------|-------|
| **Android Emulator** | `http://[HOST_IP]:5000/api` | Use actual machine IP |
| **iOS Simulator** | `http://localhost:5000/api` | Always localhost |
| **Web** | `http://localhost:5000/api` | Always localhost |
| **Physical Device** | `http://[HOST_IP]:5000/api` | Use actual machine IP |

## 🔧 Files to Remember

- **Main config**: `sns_rooster\lib\screens\admin\user_management_screen.dart`
- **Auto script**: `switch-environment.ps1`
- **Config class**: `sns_rooster\lib\config\api_config.dart`
- **Test scripts**: `test-ip-connection.js`, `test-backend.js`

## 💡 Pro Tips

1. **Bookmark this guide** for quick reference
2. **Update office IP** in the script when you know it
3. **Use environment variables** for team development
4. **Test connectivity** before coding
5. **Keep backend running** when switching

---

**Need help?** Check the full documentation in `docs/DEVELOPMENT_SETUP.md`