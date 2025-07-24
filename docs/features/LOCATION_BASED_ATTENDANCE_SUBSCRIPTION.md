# Location-Based Attendance Subscription Feature

## Overview

The location-based attendance feature is now tied to subscription plans, allowing companies to control whether employees must be at their assigned location to check in/out based on their subscription tier.

## Feature Implementation

### Backend Changes

#### 1. Subscription Plan Model Updates
- **File**: `rooster-backend/models/SubscriptionPlan.js`
- **Added Features**:
  - `locationBasedAttendance`: Boolean flag for location validation
  - `multiLocationSupport`: Boolean flag for multi-location features
  - `expenseManagement`: Boolean flag for expense management
  - `performanceReviews`: Boolean flag for performance reviews
  - `trainingManagement`: Boolean flag for training management

#### 2. Attendance Controller Updates
- **File**: `rooster-backend/controllers/attendance-controller.js`
- **Changes**:
  - Modified `checkLocationValidation()` function to check subscription plan
  - Updated `checkIn()` and `checkOut()` functions to include location validation
  - Added subscription plan validation before enforcing location requirements

#### 3. Subscription Plan Configuration
- **Basic Plan**: ❌ No location features
- **Advance Plan**: ❌ No location features
- **Professional Plan**: ❌ No location features
- **Enterprise Plan**: ✅ All location features enabled

### Frontend Changes

#### 1. Feature Provider Updates
- **File**: `sns_rooster/lib/providers/feature_provider.dart`
- **Added**: `hasLocationBasedAttendance` getter for subscription-based feature check

#### 2. Attendance Screen Updates
- **File**: `sns_rooster/lib/screens/attendance/attendance_screen.dart`
- **Added**: Location validation status indicator showing whether location validation is enabled

#### 3. Admin Navigation Updates
- **File**: `sns_rooster/lib/widgets/admin_side_navigation.dart`
- **Updated**: Location management menu to use subscription-based feature check

## How It Works

### When Location Validation is ENABLED (Enterprise Plan)
1. **Check-in Process**:
   - Employee must provide latitude and longitude
   - System validates employee is within assigned location's geofence
   - If outside geofence, check-in is rejected with distance information
   - If inside geofence, check-in succeeds and location data is stored

2. **Check-out Process**:
   - Same validation as check-in
   - Location data stored with attendance record

3. **UI Indicators**:
   - Green status indicator: "Location validation is enabled"
   - Employees see clear messaging about location requirements

### When Location Validation is DISABLED (Basic/Advance/Professional Plans)
1. **Check-in Process**:
   - Employee can check in from anywhere
   - Location data is still collected and stored if provided
   - No validation errors regardless of location

2. **Check-out Process**:
   - Same behavior as check-in
   - No location restrictions

3. **UI Indicators**:
   - Orange status indicator: "Location validation not available in current plan"
   - Employees see messaging that they can check in/out from anywhere

## Testing

### Test Scripts Available

1. **Check Company Subscription**: `rooster-backend/scripts/check-company-subscription.js`
   - Shows current company's subscription plan and features
   - Displays location validation status

2. **Test Location Validation**: `rooster-backend/scripts/test-subscription-location-validation.js`
   - Provides test coordinates for location validation
   - Shows expected behavior for current subscription plan

3. **Test Basic Plan**: `rooster-backend/scripts/test-basic-plan-location.js`
   - Temporarily switches to Basic plan for testing
   - Demonstrates behavior without location features

### Manual Testing Steps

#### For Enterprise Plan (Location Validation Enabled)
1. Log in as an employee
2. Go to Attendance screen
3. Verify green status indicator shows location validation is enabled
4. Try check-in with coordinates inside geofence (should succeed)
5. Try check-in with coordinates outside geofence (should fail)

#### For Basic Plan (Location Validation Disabled)
1. Switch company to Basic plan using test script
2. Log in as an employee
3. Go to Attendance screen
4. Verify orange status indicator shows location validation is disabled
5. Try check-in with any coordinates (should always succeed)

## API Endpoints

### Check-in with Location
```
POST /api/attendance/check-in
{
  "userId": "user_id",
  "latitude": 27.7172,
  "longitude": 85.3240,
  "notes": "Optional notes"
}
```

### Check-out with Location
```
PATCH /api/attendance/check-out
{
  "userId": "user_id",
  "latitude": 27.7172,
  "longitude": 85.3240,
  "notes": "Optional notes"
}
```

## Error Responses

### Location Validation Failed (Enterprise Plan)
```json
{
  "message": "You are 150m away from mid baneshwor. Please move within 100m to check in.",
  "distance": 150,
  "geofenceRadius": 100,
  "locationName": "mid baneshwor"
}
```

### Location Validation Not Available (Basic Plan)
```json
{
  "message": "Location validation not available in current plan"
}
```

## Database Schema Updates

### Attendance Model
- Added `checkInLocation` with latitude/longitude
- Added `checkOutLocation` with latitude/longitude
- Added `locationValidation` with validation results

### Subscription Plan Model
- Added enterprise features to features object
- All location-related features default to `false`

## Benefits

1. **Flexible Pricing**: Companies can choose plans based on their location needs
2. **Clear Communication**: UI clearly shows what features are available
3. **Graceful Degradation**: Basic plans still work without location features
4. **Data Collection**: Location data is still collected when available
5. **Easy Testing**: Comprehensive test scripts for validation

## Future Enhancements

1. **Plan Upgrades**: Allow companies to upgrade plans to enable location features
2. **Custom Geofences**: Allow companies to set custom geofence sizes
3. **Location Analytics**: Provide insights on employee location patterns
4. **Offline Support**: Handle location validation when offline
5. **Multiple Locations**: Support for employees assigned to multiple locations 