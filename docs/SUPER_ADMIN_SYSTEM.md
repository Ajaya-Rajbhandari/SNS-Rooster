# Super Admin CMS System Documentation

## Overview

The Super Admin CMS (Content Management System) is a comprehensive management interface for the SNS Rooster multi-tenant platform. It provides complete control over companies, users, subscriptions, and system settings.

## Architecture

### System Design
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web App       │    │  Admin Portal   │
│   (Flutter)     │    │   (Flutter Web) │    │   (Web Only)    │
│                 │    │                 │    │                 │
│ • Employees     │    │ • Employees     │    │ • Company Mgmt  │
│ • Basic Admin   │    │ • Full Admin    │    │ • Super Admin   │
│ • No Super Admin│    │ • No Super Admin│    │ • System Mgmt   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Current Implementation
- **Flutter App**: Includes super admin dashboard (temporary)
- **Backend API**: Complete super admin endpoints
- **Database**: Multi-tenant ready with company isolation

### Future Architecture (Recommended)
- **Separate React/Vue.js Admin Portal**
- **Dedicated domain**: `admin.snsrooster.com`
- **Rich admin UI** with data tables, charts, forms
- **Advanced analytics** and reporting

## Database Models

### SuperAdmin Model
```javascript
{
  userId: ObjectId,           // Reference to User
  permissions: {
    manageCompanies: Boolean,
    manageSubscriptions: Boolean,
    manageFeatures: Boolean,
    manageUsers: Boolean,
    viewAnalytics: Boolean,
    manageBilling: Boolean,
    systemSettings: Boolean
  },
  lastActivity: Date,
  isActive: Boolean
}
```

### SubscriptionPlan Model
```javascript
{
  name: String,               // "Basic", "Professional", "Enterprise"
  description: String,
  price: {
    monthly: Number,
    yearly: Number
  },
  features: {
    maxEmployees: Number,
    maxDepartments: Number,
    analytics: Boolean,
    advancedReporting: Boolean,
    customBranding: Boolean,
    apiAccess: Boolean,
    prioritySupport: Boolean,
    dataRetention: Number,
    backupFrequency: String
  },
  isActive: Boolean,
  isDefault: Boolean,
  sortOrder: Number
}
```

### Updated Company Model
```javascript
{
  // ... existing fields ...
  subscriptionPlan: ObjectId,    // Reference to SubscriptionPlan
  createdBy: ObjectId,           // Super admin who created
  assignedSuperAdmin: ObjectId,  // Super admin assigned
  notes: String
}
```

### Updated User Model
```javascript
{
  // ... existing fields ...
  role: {
    type: String,
    enum: ['super_admin', 'admin', 'employee']
  },
  companyId: {
    type: ObjectId,
    required: function() {
      return this.role !== 'super_admin';
    }
  }
}
```

## API Endpoints

### Authentication
All super admin endpoints require authentication and super admin role validation.

### System Overview
```
GET /api/super-admin/system/overview
```
Returns system statistics including:
- Total companies
- Active companies
- Total users
- Total employees
- Subscription plans count

### Company Management
```
GET    /api/super-admin/companies?page=1&limit=10&status=active&search=company
POST   /api/super-admin/companies
PUT    /api/super-admin/companies/:companyId
DELETE /api/super-admin/companies/:companyId
```

### Subscription Management
```
GET    /api/super-admin/subscription-plans
POST   /api/super-admin/subscription-plans
PUT    /api/super-admin/subscription-plans/:planId
```

### User Management
```
GET    /api/super-admin/users?page=1&limit=10&role=admin&companyId=123
PUT    /api/super-admin/users/:userId
DELETE /api/super-admin/users/:userId
```

## Middleware

### Super Admin Middleware
```javascript
const { requireSuperAdmin, requirePermission } = require('../middleware/superAdmin');

// Check if user is super admin
router.use(requireSuperAdmin);

// Check specific permissions
router.get('/companies', requirePermission('manageCompanies'), controller.getAllCompanies);
```

### Company Context Middleware
```javascript
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');

// For regular users - validate company access
router.get('/data', validateCompanyContext, validateUserCompanyAccess, controller.getData);

// For super admins - bypass company validation
router.get('/data', validateCompanyAccess, controller.getData);
```

## Frontend Implementation

### Super Admin Service
```dart
class SuperAdminService {
  Future<Map<String, dynamic>> getSystemOverview();
  Future<Map<String, dynamic>> getAllCompanies({int page, int limit, String? status, String? search});
  Future<Map<String, dynamic>> createCompany({required String name, required String domain, ...});
  Future<List<Map<String, dynamic>>> getSubscriptionPlans();
  Future<Map<String, dynamic>> getAllUsers({int page, int limit, String? role, String? companyId});
}
```

### Super Admin Provider
```dart
class SuperAdminProvider with ChangeNotifier {
  // System Overview
  Map<String, dynamic>? get systemOverview;
  bool get isLoadingOverview;
  String? get overviewError;
  
  // Companies
  List<Map<String, dynamic>> get companies;
  bool get isLoadingCompanies;
  int get totalCompanies;
  
  // Methods
  Future<void> loadSystemOverview();
  Future<void> loadCompanies({int page, int limit, String? status, String? search});
  Future<bool> createCompany({required String name, required String domain, ...});
}
```

### Super Admin Dashboard
```dart
class SuperAdminDashboardScreen extends StatefulWidget {
  // Professional CMS-style interface
  // System overview with key metrics
  // Quick actions for common tasks
  // Recent activities feed
  // Navigation drawer with all management sections
}
```

## Setup Instructions

### 1. Backend Setup
```bash
cd rooster-backend

# Install dependencies
npm install

# Set up super admin and default subscription plans
node scripts/setup-super-admin.js

# Start the server
npm run dev
```

### 2. Frontend Setup
```bash
cd sns_rooster

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Super Admin Access
1. Start the backend server
2. Login with super admin credentials:
   ```
   Email: superadmin@snstechservices.com.au
   Password: SuperAdmin@123
   ```
3. You'll be redirected to the Super Admin Dashboard
4. Start creating companies and managing the platform

## Default Configuration

### Super Admin User
- **Email**: `superadmin@snstechservices.com.au`
- **Password**: `SuperAdmin@123`
- **Role**: `super_admin`
- **Permissions**: All permissions enabled

### Default Subscription Plans

#### Basic Plan - $29/month
- **Max Employees**: 10
- **Max Departments**: 3
- **Features**: Attendance, Payroll, Leave Management, Document Management, Notifications, Time Tracking
- **Backup**: Weekly
- **Support**: Standard

#### Professional Plan - $79/month
- **Max Employees**: 50
- **Max Departments**: 10
- **Features**: All Basic + Analytics, Advanced Reporting, Custom Branding, API Access
- **Backup**: Daily
- **Support**: Standard

#### Enterprise Plan - $199/month
- **Max Employees**: 500
- **Max Departments**: 50
- **Features**: All Professional + Priority Support, Advanced Security
- **Backup**: Daily
- **Support**: Priority

## Security Features

### Authentication
- JWT-based authentication with role-based tokens
- Secure password hashing with bcrypt
- Session management with automatic token refresh

### Authorization
- **Super Admin**: Full system access, company management
- **Company Admin**: Company-specific administration
- **Manager**: Department-level management
- **Employee**: Individual user access

### Data Isolation
- Company-specific data queries with middleware validation
- Automatic company context injection
- Cross-company access prevention

## Usage Examples

### Creating a New Company
```javascript
// Backend API call
const companyData = {
  name: "TechCorp Inc.",
  domain: "techcorp",
  subdomain: "techcorp",
  adminEmail: "admin@techcorp.com",
  adminPassword: "SecurePass123",
  adminFirstName: "John",
  adminLastName: "Doe",
  subscriptionPlanId: "subscription_plan_id",
  contactPhone: "+1234567890",
  address: {
    street: "123 Business St",
    city: "New York",
    state: "NY",
    postalCode: "10001",
    country: "USA"
  },
  notes: "New technology company"
};

const response = await fetch('/api/super-admin/companies', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify(companyData)
});
```

### Managing Subscription Plans
```javascript
// Create new subscription plan
const planData = {
  name: "Premium",
  description: "Premium plan for large enterprises",
  price: {
    monthly: 299,
    yearly: 2990
  },
  features: {
    maxEmployees: 1000,
    maxDepartments: 100,
    analytics: true,
    advancedReporting: true,
    customBranding: true,
    apiAccess: true,
    prioritySupport: true,
    dataRetention: 1825,
    backupFrequency: "daily"
  },
  sortOrder: 4
};
```

## Testing

### Backend Testing
```bash
# Test super admin setup
node scripts/setup-super-admin.js

# Test super admin login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@snstechservices.com.au","password":"SuperAdmin@123"}'

# Test system overview
curl -X GET http://localhost:5000/api/super-admin/system/overview \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test company creation
curl -X POST http://localhost:5000/api/super-admin/companies \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"name":"Test Company","domain":"test","subdomain":"test","adminEmail":"admin@test.com","adminPassword":"password123","subscriptionPlanId":"plan_id"}'
```

### Frontend Testing
```dart
// Test super admin login
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final success = await authProvider.login(
  'superadmin@snstechservices.com.au',
  'SuperAdmin@123'
);

// Test system overview loading
final superAdminProvider = Provider.of<SuperAdminProvider>(context, listen: false);
await superAdminProvider.loadSystemOverview();
```

## Troubleshooting

### Common Issues

#### 1. Super Admin Login Fails
**Problem**: Cannot login with super admin credentials
**Solution**: 
1. Run the setup script: `node scripts/setup-super-admin.js`
2. Check if the user exists in the database
3. Verify the password is correct

#### 2. Permission Denied Errors
**Problem**: Getting 403 errors on super admin endpoints
**Solution**:
1. Ensure the user has `super_admin` role
2. Check if the SuperAdmin record exists and is active
3. Verify the JWT token contains the correct role

#### 3. Company Creation Fails
**Problem**: Cannot create new companies
**Solution**:
1. Check if the domain/subdomain already exists
2. Verify the subscription plan ID is valid
3. Ensure all required fields are provided

#### 4. Data Isolation Issues
**Problem**: Users can see data from other companies
**Solution**:
1. Verify company context middleware is working
2. Check if the user has the correct companyId
3. Ensure super admin bypass is working correctly

### Debug Mode
Enable debug logging to troubleshoot issues:

```javascript
// Backend - Enable debug logging
NODE_ENV=development
DEBUG=true

// Frontend - Enable debug logging
EnvironmentConfig.enableDebugLogging = true;
```

## Future Enhancements

### Planned Features
1. **Advanced Analytics Dashboard**
   - Real-time system metrics
   - Usage trends and patterns
   - Performance monitoring

2. **Bulk Operations**
   - Bulk user management
   - Bulk company operations
   - Data import/export

3. **Advanced Security**
   - Two-factor authentication
   - IP whitelisting
   - Audit logging

4. **Automation**
   - Automated billing
   - Usage alerts
   - System maintenance

### Admin Portal Migration
1. **React/Vue.js Implementation**
   - Rich admin interface
   - Advanced data tables
   - Interactive charts

2. **Separate Deployment**
   - Dedicated domain
   - Independent scaling
   - Enhanced security

3. **Feature Parity**
   - All current functionality
   - Enhanced UI/UX
   - Better performance

## References

- [Multi-Tenant Architecture Guide](MULTI_TENANT_ARCHITECTURE.md)
- [API Documentation](api/API_DOCUMENTATION.md)
- [Security Documentation](SECURITY_ACCESS_CONTROL_DOCUMENTATION.md)
- [Deployment Guide](PRODUCTION_DEPLOYMENT.md)

---

*Last updated: July 17, 2025* 