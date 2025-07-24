# 🔧 Config Files Migration Guide

## Current Problem

You have **5 scattered config files** with **redundant and conflicting logic**:

1. `api_config.dart` - API endpoints (hardcoded IPs)
2. `environment_config.dart` - Environment settings
3. `secure_config.dart` - Sensitive data (new)
4. `debug_config.dart` - Debug utilities
5. `leave_config.dart` - Leave settings

## Issues Identified

### ❌ **Conflicting API URLs**
- `api_config.dart` uses hardcoded `192.168.1.119:5000` for web
- `environment_config.dart` uses `String.fromEnvironment()`
- `secure_config.dart` also has `String.fromEnvironment()`

### ❌ **Duplicate Environment Logic**
- Multiple files handle environment detection
- Inconsistent validation methods
- Scattered debug utilities

### ❌ **Widespread Dependencies**
- **50+ files** import from scattered config files
- Hard to maintain and update

## ✅ **Solution: Single AppConfig**

### **New Structure:**
```
lib/config/
├── app_config.dart          # 🎯 SINGLE CONFIG FILE
├── MIGRATION_GUIDE.md       # This guide
└── [DEPRECATED]/
    ├── api_config.dart      # ❌ Remove after migration
    ├── environment_config.dart
    ├── secure_config.dart
    ├── debug_config.dart
    └── leave_config.dart
```

### **Benefits:**
- ✅ **Single source of truth** for all configuration
- ✅ **No conflicting URLs** or duplicate logic
- ✅ **Easier to maintain** and update
- ✅ **Better security** with centralized validation
- ✅ **Cleaner imports** across the app

## 🔄 **Migration Steps**

### **Phase 1: Create AppConfig (DONE)**
- ✅ Created `app_config.dart` with all consolidated logic

### **Phase 2: Update Imports (NEXT)**
Replace all imports from scattered config files:

**Before:**
```dart
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/config/environment_config.dart';
import 'package:sns_rooster/config/secure_config.dart';
import 'package:sns_rooster/config/debug_config.dart';
```

**After:**
```dart
import 'package:sns_rooster/config/app_config.dart';
```

### **Phase 3: Update Code References**
Replace all references:

**Before:**
```dart
ApiConfig.baseUrl
EnvironmentConfig.isDevelopment
SecureConfig.apiUrl
DebugConfig.printEnvironmentInfo()
```

**After:**
```dart
AppConfig.baseUrl
AppConfig.isDevelopment
AppConfig.apiUrl
AppConfig.printEnvironmentInfo()
```

### **Phase 4: Remove Old Files**
After all imports are updated:
1. Delete old config files
2. Test the application
3. Update documentation

## 📊 **Files to Update (50+ files)**

### **Services (15 files):**
- `services/api_service.dart`
- `services/auth_service.dart`
- `services/company_service.dart`
- `services/attendance_service.dart`
- `services/notification_service.dart`
- `services/feature_service.dart`
- `services/payroll_service.dart`
- `services/analytics_service.dart`
- `services/admin_payroll_service.dart`
- `services/company_settings_service.dart`
- `services/tax_settings_service.dart`
- `services/super_admin_service.dart`
- `services/location_settings_service.dart`
- `services/payroll_cycle_service.dart`
- `services/company_info_service.dart`

### **Providers (10 files):**
- `providers/auth_provider.dart`
- `providers/attendance_provider.dart`
- `providers/profile_provider.dart`
- `providers/leave_provider.dart`
- `providers/leave_request_provider.dart`
- `providers/analytics_provider.dart`
- `providers/payroll_analytics_provider.dart`
- `providers/admin_settings_provider.dart`
- `providers/admin_attendance_provider.dart`
- `providers/admin_analytics_provider.dart`

### **Screens (20 files):**
- `screens/admin/admin_dashboard_screen.dart`
- `screens/admin/employee_management_screen.dart`
- `screens/admin/payroll_management_screen.dart`
- `screens/admin/break_management_screen.dart`
- `screens/admin/break_types_screen.dart`
- `screens/admin/notification_alert_screen.dart`
- `screens/admin/feature_management_screen.dart`
- `screens/admin/event_management_screen.dart`
- `screens/admin/timesheet_approval_screen.dart`
- `screens/admin/user_management_screen.dart`
- `screens/admin/employee_detail_screen.dart`
- `screens/admin/edit_company_form_screen.dart`
- `screens/admin/add_employee_dialog.dart`
- `screens/admin/admin_attendance_screen.dart`
- `screens/admin/location_management_screen.dart`
- `screens/admin/expense_management_screen.dart`
- `screens/employee/employee_dashboard_screen.dart`
- `screens/employee/analytics_screen.dart`
- `screens/employee/payroll_screen.dart`
- `screens/employee/employee_events_screen.dart`
- `screens/auth/forgot_password_screen.dart`
- `screens/auth/reset_password_screen.dart`
- `screens/auth/verify_email_screen.dart`
- `screens/profile/profile_screen.dart`
- `screens/notification/notification_screen.dart`

### **Widgets (5 files):**
- `widgets/user_avatar.dart`
- `widgets/employee_assignment_dialog.dart`
- `widgets/company_info_widget.dart`
- `widgets/dashboard/user_info_header.dart`
- `widgets/break_time_warning_widget.dart`

### **Utils (3 files):**
- `utils/logger.dart`
- `utils/avatar_helper.dart`
- `utils/debug_company_context.dart`

## 🚀 **Quick Migration Script**

You can use search and replace in your IDE:

**Search for:**
```
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/config/environment_config.dart';
import 'package:sns_rooster/config/secure_config.dart';
import 'package:sns_rooster/config/debug_config.dart';
```

**Replace with:**
```
import 'package:sns_rooster/config/app_config.dart';
```

**Search for:**
```
ApiConfig.
EnvironmentConfig.
SecureConfig.
DebugConfig.
```

**Replace with:**
```
AppConfig.
```

## ✅ **Testing After Migration**

1. **Run the app** and check for import errors
2. **Test API calls** to ensure URLs are correct
3. **Verify environment detection** works properly
4. **Check debug output** shows correct configuration
5. **Test all major features** (login, dashboard, etc.)

## 🎯 **Benefits After Migration**

- ✅ **Single config file** to maintain
- ✅ **No more conflicting URLs**
- ✅ **Centralized validation** and security
- ✅ **Easier debugging** with unified debug methods
- ✅ **Cleaner codebase** with consistent imports
- ✅ **Better maintainability** for future updates

---

**Ready to migrate? Start with updating the imports in your services folder first!** 