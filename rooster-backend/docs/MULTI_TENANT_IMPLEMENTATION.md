# Multi-Tenant Implementation Guide - SNS Rooster

## Overview

The SNS Rooster backend has been successfully migrated to a multi-tenant architecture, allowing multiple companies to use the same application instance while maintaining complete data isolation. This document provides a comprehensive guide to understanding and working with the multi-tenant system.

## Architecture Overview

### Key Components

1. **Company Model** - Central entity that defines company boundaries
2. **Company Context Middleware** - Resolves and validates company context
3. **Multi-Tenant Models** - All models include companyId for data isolation
4. **Feature Management** - Company-specific feature toggles
5. **Usage Limits** - Enforce subscription-based limits

### Data Isolation Strategy

- **Database Level**: All records include `companyId` field
- **Query Level**: All queries automatically filter by company
- **API Level**: Company context validated on every request
- **File Level**: Uploads organized by company directory structure

## Company Model

### Structure

```javascript
{
  // Basic Information
  name: String,
  domain: String,        // Unique domain identifier
  subdomain: String,     // Unique subdomain identifier
  
  // Contact Information
  adminEmail: String,
  contactPhone: String,
  address: Object,
  
  // Subscription & Billing
  subscriptionPlan: 'basic' | 'professional' | 'enterprise',
  billingCycle: 'monthly' | 'yearly',
  nextBillingDate: Date,
  trialEndDate: Date,
  
  // Feature Configuration
  features: {
    attendance: Boolean,
    payroll: Boolean,
    leaveManagement: Boolean,
    analytics: Boolean,
    // ... more features
  },
  
  // Usage Limits
  limits: {
    maxEmployees: Number,
    maxStorageGB: Number,
    maxApiCallsPerDay: Number,
    // ... more limits
  },
  
  // Company Settings
  settings: {
    timezone: String,
    currency: String,
    workingDays: Array,
    workingHours: Object,
    // ... more settings
  },
  
  // Branding
  branding: {
    logo: String,
    primaryColor: String,
    companyName: String,
    // ... more branding
  },
  
  // Status
  status: 'active' | 'suspended' | 'trial' | 'expired' | 'cancelled'
}
```

### Key Methods

```javascript
// Check if company is active
company.isActive() // Returns boolean

// Check if feature is enabled
company.isFeatureEnabled('attendance') // Returns boolean

// Get company context for API responses
company.getCompanyContext() // Returns public company info
```

## Company Context Middleware

### Usage

```javascript
const { 
  resolveCompanyContext, 
  requireCompanyContext, 
  validateFeatureAccess 
} = require('../middleware/companyContext');

// Apply to routes
router.get('/attendance', 
  auth, 
  resolveCompanyContext, 
  requireCompanyContext,
  validateFeatureAccess('attendance'),
  attendanceController.getAll
);
```

### Company Resolution Methods

The middleware resolves company context using the following priority:

1. **Domain-based**: `company1.rooster.com` → resolves to company with domain "company1"
2. **Subdomain-based**: `company1.rooster.com` → resolves to company with subdomain "company1"
3. **Header-based**: `X-Company-Id: <companyId>` in request headers
4. **Query-based**: `?companyId=<companyId>` in URL parameters
5. **JWT-based**: Company ID from authenticated user's token
6. **Default fallback**: Uses "default" company for backward compatibility

### Middleware Functions

- `resolveCompanyContext` - Resolves and validates company context
- `requireCompanyContext` - Ensures company context is available
- `validateFeatureAccess(featureName)` - Validates feature availability
- `checkCompanyLimits(limitType)` - Validates usage limits
- `addCompanyFilter(query, companyId)` - Adds company filter to queries
- `validateCompanyOwnership(model, resourceId, companyId)` - Validates resource ownership

## Multi-Tenant Models

### Updated Models

All models now include a `companyId` field:

```javascript
{
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  }
}
```

### Compound Indexes

Unique constraints are now scoped to company:

```javascript
// User email uniqueness within company
userSchema.index({ companyId: 1, email: 1 }, { unique: true });

// Employee ID uniqueness within company
employeeSchema.index({ companyId: 1, employeeId: 1 }, { unique: true });

// Attendance uniqueness within company
attendanceSchema.index({ companyId: 1, user: 1, date: 1 }, { unique: true });
```

## API Endpoints

### Company Management

```
GET    /api/company/resolve          # Resolve company by domain/subdomain
GET    /api/company/context          # Get current company context
GET    /api/company/features         # Get company features
GET    /api/company/settings         # Get company settings (admin only)
PUT    /api/company/settings         # Update company settings (admin only)
GET    /api/company/limits           # Get usage limits (admin only)
GET    /api/company/status           # Get subscription status (admin only)
POST   /api/company/validate-feature # Validate feature access
```

### Example Usage

```javascript
// Resolve company
const response = await fetch('/api/company/resolve?domain=acme');
const { company } = await response.json();

// Get company features
const features = await fetch('/api/company/features', {
  headers: { 'Authorization': `Bearer ${token}` }
});

// Validate feature access
const validation = await fetch('/api/company/validate-feature', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({ featureName: 'analytics' })
});
```

## Database Migration

### Migration Script

Run the migration script to update existing data:

```bash
node scripts/migrate-to-multi-tenant.js
```

### What the Migration Does

1. Creates a default company for existing data
2. Updates all existing records with `companyId`
3. Creates default break types for the company
4. Creates default admin settings for the company

### Testing Migration

Run the test script to validate the migration:

```bash
node scripts/test-multi-tenant-migration.js
```

## Best Practices

### Querying Data

Always include company filtering in queries:

```javascript
// ✅ Correct - includes company filter
const users = await User.find({ companyId: req.companyId });

// ❌ Incorrect - no company filter
const users = await User.find({});
```

### Creating Records

Always include companyId when creating records:

```javascript
// ✅ Correct - includes companyId
const user = new User({
  ...userData,
  companyId: req.companyId
});

// ❌ Incorrect - missing companyId
const user = new User(userData);
```

### Updating Records

Validate company ownership before updates:

```javascript
// ✅ Correct - validates ownership
const user = await validateCompanyOwnership(User, userId, req.companyId);
await user.updateOne(updateData);

// ❌ Incorrect - no ownership validation
await User.findByIdAndUpdate(userId, updateData);
```

### File Uploads

Organize uploads by company:

```javascript
// ✅ Correct - company-specific path
const uploadPath = `uploads/companies/${req.companyId}/avatars/${filename}`;

// ❌ Incorrect - global path
const uploadPath = `uploads/avatars/${filename}`;
```

## Feature Management

### Checking Feature Access

```javascript
// In middleware
router.get('/analytics', 
  validateFeatureAccess('analytics'),
  analyticsController.getData
);

// In controllers
if (!req.company.isFeatureEnabled('analytics')) {
  return res.status(403).json({ error: 'Feature not available' });
}
```

### Feature Configuration

Features can be enabled/disabled per company:

```javascript
const company = await Company.findById(companyId);
company.features.analytics = true;
company.features.advancedReporting = false;
await company.save();
```

## Usage Limits

### Checking Limits

```javascript
// In middleware
router.post('/employees', 
  checkCompanyLimits('employees'),
  employeeController.create
);

// In controllers
const limits = req.company.limits;
const currentCount = await User.countDocuments({ 
  companyId: req.companyId, 
  role: 'employee' 
});

if (currentCount >= limits.maxEmployees) {
  return res.status(403).json({ error: 'Employee limit exceeded' });
}
```

## Security Considerations

### Data Isolation

- All queries must include company filtering
- File uploads must be company-isolated
- API responses must not leak cross-company data
- Authentication must validate company context

### Access Control

- Users can only access data from their company
- Admins can only manage their own company
- Super admins can manage all companies (future implementation)

## Troubleshooting

### Common Issues

1. **Missing Company Context**
   - Ensure `resolveCompanyContext` middleware is applied
   - Check that company exists and is active
   - Verify domain/subdomain configuration

2. **Duplicate Key Errors**
   - Check compound unique indexes
   - Ensure companyId is included in unique constraints
   - Verify data migration completed successfully

3. **Feature Access Denied**
   - Check if feature is enabled for company
   - Verify subscription plan includes feature
   - Check company status is active

### Debug Commands

```bash
# Check company status
node -e "const Company = require('./models/Company'); Company.findByDomain('default').then(c => console.log(c))"

# Check migration status
node scripts/test-multi-tenant-migration.js

# Validate company context
curl -H "X-Company-Id: <companyId>" http://localhost:3000/api/company/context
```

## Next Steps

### Phase 2: Authentication & Authorization
- Update authentication to include company validation
- Implement super admin role and permissions
- Add domain-based company resolution

### Phase 3: API Updates
- Update all existing controllers to include company filtering
- Implement company-specific error handling
- Update file upload paths for company isolation

### Phase 4: Testing & Validation
- Create multi-tenant test scenarios
- Validate data isolation
- Performance testing with multiple companies

## Support

For questions or issues with the multi-tenant implementation:

1. Check this documentation
2. Review the test scripts for examples
3. Check the migration logs for errors
4. Contact the backend development team

---

**Last Updated**: 2024-01-15
**Version**: 1.0.0 