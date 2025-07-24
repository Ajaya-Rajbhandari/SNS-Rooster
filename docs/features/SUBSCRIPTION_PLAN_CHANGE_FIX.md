# Subscription Plan Change Feature Fix

## Issue Description

When a super admin changes a company's subscription plan, the features weren't being updated in real-time in the Flutter app. The plan change was visible in the UI, but the actual feature toggles and functionality remained unchanged.

## Root Cause

The issue was in the backend `/companies/features` endpoint, which was returning `company.features` instead of `company.subscriptionPlan?.features`. This meant that:

1. **Plan changes weren't reflected** in the features API response
2. **Feature Provider cache** wasn't being updated with new plan features
3. **UI components** continued to show old feature states

## Solution Implemented

### 1. Backend Fix (companyRoutes.js)

**File**: `rooster-backend/routes/companyRoutes.js`

**Change**: Updated the features endpoint to return subscription plan features instead of company features:

```javascript
// Before (incorrect)
features: company.features,
limits: company.limits,

// After (correct)
features: company.subscriptionPlan?.features || {},
limits: company.subscriptionPlan || {},
```

**Impact**: Now when subscription plans change, the features API immediately returns the updated feature set.

### 2. Frontend Enhancement (FeatureProvider)

**File**: `sns_rooster/lib/providers/feature_provider.dart`

**Added**: `forceRefreshFeatures()` method to clear cache and reload features:

```dart
/// Force refresh features (clear cache and reload)
Future<void> forceRefreshFeatures() async {
  _features.clear();
  _limits.clear();
  _usage.clear();
  _subscriptionPlan.clear();
  _companyInfo.clear();
  _error = null;
  _isLoading = true;
  notifyListeners();
  
  await loadFeatures();
}
```

### 3. UI Enhancement (Feature Management Screen)

**File**: `sns_rooster/lib/screens/admin/feature_management_screen.dart`

**Added**: Refresh button in app bar for manual feature refresh:

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.refresh),
    onPressed: () async {
      final featureProvider = Provider.of<FeatureProvider>(context, listen: false);
      await featureProvider.forceRefreshFeatures();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Features refreshed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    tooltip: 'Refresh Features',
  ),
],
```

## Testing the Fix

### Test Script

**File**: `rooster-backend/scripts/test-plan-change-features.js`

This script:
1. Temporarily switches a company to Basic plan
2. Allows testing of feature changes
3. Restores the original plan
4. Provides debugging information

### Manual Testing Steps

1. **Change Subscription Plan** (as super admin):
   - Go to Company Settings > Subscription
   - Change plan from Enterprise to Basic
   - Note that features should update immediately

2. **Verify Feature Changes**:
   - Location Management should disappear from admin navigation
   - Location validation should be disabled in attendance screen
   - Enterprise features should be hidden

3. **Force Refresh** (if needed):
   - Go to Feature Management screen
   - Click the refresh button in the app bar
   - Features should update immediately

## Expected Behavior

### When Switching to Basic Plan:
- ❌ Location-based Attendance: Disabled
- ❌ Multi-Location Support: Disabled
- ❌ Expense Management: Disabled
- ❌ Performance Reviews: Disabled
- ❌ Training Management: Disabled

### When Switching to Enterprise Plan:
- ✅ Location-based Attendance: Enabled
- ✅ Multi-Location Support: Enabled
- ✅ Expense Management: Enabled
- ✅ Performance Reviews: Enabled
- ✅ Training Management: Enabled

## API Endpoint

**GET** `/api/companies/features`

**Response**:
```json
{
  "features": {
    "locationBasedAttendance": true,
    "multiLocationSupport": true,
    "expenseManagement": true,
    "performanceReviews": true,
    "trainingManagement": true
  },
  "limits": {
    "maxEmployees": 100,
    "maxStorageGB": 5,
    "maxApiCallsPerDay": 1000
  },
  "usage": {
    "maxEmployees": 11,
    "maxStorageGB": 0,
    "maxApiCallsPerDay": 0
  },
  "subscriptionPlan": {
    "name": "Enterprise",
    "price": {
      "monthly": 199,
      "yearly": 1990
    },
    "features": {
      "locationBasedAttendance": true,
      "multiLocationSupport": true,
      "expenseManagement": true,
      "performanceReviews": true,
      "trainingManagement": true
    }
  },
  "company": {
    "name": "SNS Tech Services",
    "domain": "snstechservices.com.au",
    "subdomain": "sns",
    "status": "active"
  }
}
```

## Benefits

1. **Real-time Updates**: Features update immediately when plans change
2. **Consistent State**: UI always reflects the current subscription plan
3. **Manual Refresh**: Admins can force refresh if needed
4. **Better UX**: No need to restart app or clear cache
5. **Debugging**: Clear feedback when features are refreshed

## Future Enhancements

1. **Automatic Refresh**: Trigger feature refresh when plan changes are detected
2. **WebSocket Updates**: Real-time feature updates via WebSocket
3. **Feature Change Notifications**: Notify users when features are enabled/disabled
4. **Plan Change History**: Track when and why plans were changed
5. **Feature Usage Analytics**: Track which features are most used

## Troubleshooting

### If Features Still Don't Update:

1. **Check API Response**: Verify `/api/companies/features` returns correct data
2. **Force Refresh**: Use the refresh button in Feature Management
3. **Clear App Cache**: Restart the Flutter app
4. **Check Network**: Ensure API calls are reaching the backend
5. **Verify Plan Change**: Confirm the subscription plan was actually updated

### Debug Commands:

```bash
# Test plan change
node scripts/test-plan-change-features.js

# Check current features
node scripts/test-feature-provider.js

# Verify company subscription
node scripts/check-company-subscription.js
``` 