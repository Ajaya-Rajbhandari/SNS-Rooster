# Subscription Plan Loading Issues - Troubleshooting Guide

## Problem Description

Users of certain companies experience issues where subscription plans don't load properly during login, resulting in:
- Missing features in the UI
- "No Plan" or "Basic" plan displayed regardless of actual subscription
- Features not working as expected
- Inconsistent behavior across different companies

## Root Causes Identified

### 1. **Missing Subscription Plan Assignment**
- Companies created without proper subscription plan assignment
- Database inconsistencies where `subscriptionPlan` field is null or undefined
- Companies with invalid subscription plan references

### 2. **Feature Synchronization Issues**
- Company features not properly synced with subscription plan features
- Mismatched feature flags between company and plan data
- Outdated company feature data

### 3. **API Response Problems**
- Backend features endpoint returning incomplete data
- Missing fallback mechanisms for companies without plans
- Inconsistent error handling

### 4. **Frontend Caching Issues**
- Feature provider cache not clearing properly
- Stale data persisting after plan changes
- Race conditions during login

## Solutions Implemented

### 1. **Backend Improvements**

#### Enhanced Features Endpoint (`rooster-backend/routes/companyRoutes.js`)
```javascript
// Added robust fallback mechanisms
const defaultFeatures = {
  attendance: true,
  payroll: true,
  leaveManagement: true,
  analytics: false,
  // ... other features
};

const defaultLimits = {
  maxEmployees: 10,
  maxStorageGB: 5,
  maxApiCallsPerDay: 1000,
  // ... other limits
};

// Use plan features or defaults
analytics: planFeatures.analytics || defaultFeatures.analytics,
```

#### Key Improvements:
- **Default Features**: Companies without plans get basic features
- **Graceful Degradation**: API always returns valid response
- **Better Error Handling**: Comprehensive fallback mechanisms

### 2. **Database Fix Scripts**

#### Diagnostic Script (`diagnose-subscription-issue.js`)
```bash
# Run to identify issues
node scripts/diagnose-subscription-issue.js
```

**Checks for:**
- Companies without subscription plans
- Feature mismatches
- Invalid company status
- Trial expiration issues

#### Fix Script (`fix-subscription-loading.js`)
```bash
# Run to fix issues
node scripts/fix-subscription-loading.js
```

**Fixes:**
- Assigns default plans to companies without plans
- Syncs features with subscription plans
- Updates company status and trial information
- Validates all data consistency

### 3. **Frontend Enhancements**

#### Improved Feature Service (`sns_rooster/lib/services/feature_service.dart`)
```dart
// Better fallback features
'subscriptionPlan': {
  'name': 'Basic',
  'price': {'monthly': 29, 'yearly': 290},
},
'company': {
  'name': user?['companyName'] ?? 'Default Company',
  'status': 'active',
},
```

#### Enhanced Error Handling
- Multiple fallback attempts
- User-specific company information
- Consistent default values

## Step-by-Step Resolution Process

### Step 1: Diagnose the Issue
```bash
cd rooster-backend
node scripts/diagnose-subscription-issue.js
```

**Expected Output:**
```
🔍 DIAGNOSING SUBSCRIPTION PLAN LOADING ISSUES
===============================================

📊 Found 5 companies in database

🏢 Company: Cit Express (687c6cf9fce054783b9af432)
   Status: trial
   Subscription Plan: NO PLAN ASSIGNED
   ❌ ISSUE: No subscription plan assigned
```

### Step 2: Apply Fixes
```bash
cd rooster-backend
node scripts/fix-subscription-loading.js
```

**Expected Output:**
```
🔧 FIXING SUBSCRIPTION PLAN LOADING ISSUES
==========================================

📊 Found 2 companies without subscription plans

🏢 Fixing company: Cit Express
   ✅ Set company status to trial
   ✅ Assigned Basic plan to Cit Express
```

### Step 3: Verify Fixes
```bash
cd rooster-backend
node scripts/diagnose-subscription-issue.js
```

**Expected Output:**
```
✅ VERIFICATION
===============
✅ Cit Express: Has Basic plan
✅ Another Company: Has Professional plan

🎉 All subscription plan issues have been resolved!
```

### Step 4: Test Frontend
1. Clear app cache/storage
2. Log out and log back in
3. Check subscription plan display
4. Verify features are working

## Common Issues and Solutions

### Issue: "No Plan" Displayed
**Cause:** Company has no subscription plan assigned
**Solution:** Run fix script to assign default plan

### Issue: Features Not Working
**Cause:** Features not synced with subscription plan
**Solution:** Run fix script to sync features

### Issue: Trial Expired
**Cause:** Company trial period has ended
**Solution:** Update company status to 'active' or extend trial

### Issue: Inconsistent Behavior
**Cause:** Frontend cache issues
**Solution:** Clear app cache and restart

## Prevention Measures

### 1. **Database Validation**
- Ensure all new companies get subscription plans
- Validate subscription plan references
- Regular consistency checks

### 2. **API Monitoring**
- Monitor features endpoint responses
- Log subscription plan loading issues
- Alert on missing plans

### 3. **Frontend Improvements**
- Better error handling in feature provider
- Automatic retry mechanisms
- Clear cache on plan changes

## Testing Checklist

### Backend Testing
- [ ] All companies have subscription plans
- [ ] Features endpoint returns valid data
- [ ] Default features work for companies without plans
- [ ] Plan changes reflect immediately

### Frontend Testing
- [ ] Login loads correct subscription plan
- [ ] Features display correctly
- [ ] Plan changes update UI
- [ ] Fallback features work

### Integration Testing
- [ ] End-to-end login flow
- [ ] Plan change propagation
- [ ] Error scenarios handled
- [ ] Performance under load

## Monitoring and Maintenance

### Regular Checks
```bash
# Weekly diagnostic check
node scripts/diagnose-subscription-issue.js

# Monthly full fix run
node scripts/fix-subscription-loading.js
```

### Key Metrics to Monitor
- Companies without subscription plans
- Feature synchronization issues
- API response times
- Frontend error rates

### Alert Conditions
- More than 5% of companies without plans
- Feature endpoint errors > 1%
- Plan change failures
- Cache inconsistencies

## Support Commands

### Quick Status Check
```bash
# Check specific company
node scripts/check-company-by-id.js

# Test API response
curl -H "Authorization: Bearer TOKEN" \
     -H "x-company-id: COMPANY_ID" \
     http://localhost:5000/api/companies/features
```

### Emergency Fixes
```bash
# Force refresh all companies
node scripts/refresh-company-features.js

# Reset specific company
node scripts/fix-company-subscriptions.js
```

## Conclusion

The subscription plan loading issues have been resolved through:
1. **Robust backend fallback mechanisms**
2. **Comprehensive database fix scripts**
3. **Enhanced frontend error handling**
4. **Improved monitoring and maintenance**

These solutions ensure that all companies have proper subscription plans and features load correctly during login, providing a consistent user experience across the platform. 