# SNS Rooster - Multi-Tenant Employee Management System

A comprehensive **multi-tenant** employee management system built with Flutter (frontend) and Node.js (backend) for tracking attendance, managing users, and handling employee data across multiple companies.

## 🏢 Multi-Tenant Architecture

SNS Rooster is designed as a **Software-as-a-Service (SaaS)** platform that supports multiple companies (tenants) with complete data isolation and role-based access control.

### User Roles Hierarchy
```
Super Admin (Root Level)
├── Company Admin (Company Level)
│   ├── Manager (Department Level)
│   └── Employee (Individual Level)
```

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web App       │    │  Admin Portal   │
│   (Flutter)     │    │   (Flutter Web) │    │   (Web Only)    │
│                 │    │                 │    │                 │
│ • Employees     │    │ • Employees     │    │ • Company Admins│
│ • Basic Admin   │    │ • Basic Admin   │    │ • Super Admins  │
│ • Attendance    │    │ • Full Features │    │ • System Mgmt   │
│ • Payroll       │    │ • Analytics     │    │ • Multi-tenant  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🎯 Super Admin CMS System

### Overview
The Super Admin CMS (Content Management System) provides complete control over the multi-tenant platform, allowing system administrators to manage companies, users, subscriptions, and system settings.

### Features

#### 🔧 Company Management
- **Create Companies**: Set up new companies with admin users
- **Subscription Management**: Assign and manage subscription plans
- **Company Status**: Monitor active, suspended, and trial companies
- **Usage Tracking**: Monitor employee counts and feature usage

#### 👥 User Management
- **Cross-Company Users**: Manage all users across all companies
- **Role Assignment**: Assign admin, manager, and employee roles
- **User Activity**: Monitor login activity and user behavior
- **Bulk Operations**: Perform bulk user management operations

#### 💳 Subscription Management
- **Plan Creation**: Create custom subscription plans
- **Feature Configuration**: Set feature limits per plan
- **Pricing Management**: Configure monthly/yearly pricing
- **Plan Analytics**: Track plan adoption and usage

#### 📊 System Administration
- **System Overview**: Real-time system statistics
- **Analytics Dashboard**: Platform-wide usage analytics
- **System Settings**: Global system configuration
- **Backup Management**: System backup and restore
- **Log Monitoring**: System logs and error tracking

### Default Setup

#### Super Admin Credentials
```
Email: superadmin@snstechservices.com.au
Password: SuperAdmin@123
```

#### Default Subscription Plans
1. **Basic Plan** - $29/month
   - 10 employees max
   - Basic features (attendance, payroll, leave)
   - Weekly backups

2. **Professional Plan** - $79/month
   - 50 employees max
   - Advanced features (analytics, custom branding, API access)
   - Daily backups

3. **Enterprise Plan** - $199/month
   - 500 employees max
   - All features + priority support
   - Daily backups + advanced security

### API Endpoints

#### Super Admin Routes
```
GET    /api/super-admin/system/overview     # System statistics
GET    /api/super-admin/companies           # List all companies
POST   /api/super-admin/companies           # Create new company
PUT    /api/super-admin/companies/:id       # Update company
DELETE /api/super-admin/companies/:id       # Delete company
GET    /api/super-admin/subscription-plans  # List subscription plans
POST   /api/super-admin/subscription-plans  # Create plan
PUT    /api/super-admin/subscription-plans/:id # Update plan
GET    /api/super-admin/users               # List all users
PUT    /api/super-admin/users/:id           # Update user
DELETE /api/super-admin/users/:id           # Delete user
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (v3.0 or higher)
- MongoDB (local or cloud instance)

### Backend Setup
```bash
cd rooster-backend
npm install

# Set up super admin and default subscription plans
node scripts/setup-super-admin.js

# Start the server
npm run dev
```

### Frontend Setup
```bash
cd sns_rooster
flutter pub get
flutter run
```

### Super Admin Access
1. Start the backend server
2. Login with super admin credentials
3. You'll be redirected to the Super Admin Dashboard
4. Start creating companies and managing the platform

## 📁 Project Structure

```
SNS-Rooster/
├── rooster-backend/                    # Node.js backend API
│   ├── routes/                        # API route definitions
│   │   ├── superAdminRoutes.js        # Super admin routes
│   │   ├── analyticsRoutes.js         # Analytics routes
│   │   └── ...
│   ├── models/                        # Database models
│   │   ├── SuperAdmin.js              # Super admin model
│   │   ├── SubscriptionPlan.js        # Subscription plans
│   │   ├── Company.js                 # Company model
│   │   └── User.js                    # User model
│   ├── middleware/                    # Authentication & validation
│   │   ├── superAdmin.js              # Super admin middleware
│   │   └── companyContext.js          # Company isolation
│   ├── controllers/                   # Business logic
│   │   └── super-admin-controller.js  # Super admin controller
│   └── scripts/                       # Setup scripts
│       └── setup-super-admin.js       # Initial setup
├── sns_rooster/                       # Flutter frontend app
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── super_admin/           # Super admin screens
│   │   │   ├── admin/                 # Company admin screens
│   │   │   └── employee/              # Employee screens
│   │   ├── widgets/
│   │   │   └── super_admin/           # Super admin widgets
│   │   ├── services/
│   │   │   └── super_admin_service.dart # Super admin API
│   │   └── providers/
│   │       └── super_admin_provider.dart # Super admin state
│   └── pubspec.yaml
└── docs/                              # Documentation
```

## 🔧 Features

### Multi-Tenant Features
- **Company Isolation**: Complete data separation between companies
- **Role-Based Access**: Super admin, company admin, manager, employee roles
- **Subscription Management**: Flexible subscription plans with feature limits
- **Usage Monitoring**: Track company usage and limits

### Core Features
- **User Management**: Create, update, and manage user accounts
- **Attendance Tracking**: Clock in/out functionality with break management
- **Employee Management**: Comprehensive employee data handling
- **Profile Management**: Complete profile editing with image upload
- **Authentication**: Secure JWT-based authentication
- **Analytics & Reporting**: Dynamic work hours, attendance breakdown, and custom date range analytics
- **Cross-platform**: Works on Android, iOS, and Web

### Super Admin Features
- **System Overview**: Real-time platform statistics
- **Company Management**: Full CRUD operations for companies
- **User Management**: Cross-company user administration
- **Subscription Management**: Plan creation and management
- **System Administration**: Global settings and monitoring

## 🔐 Security & Permissions

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

## 🚀 Deployment Strategy

### Current Implementation
- **Flutter App**: Includes super admin dashboard (temporary)
- **Backend API**: Complete super admin endpoints
- **Database**: Multi-tenant ready with company isolation

### Future Architecture (Recommended)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web App       │    │  Admin Portal   │
│   (Flutter)     │    │   (Flutter Web) │    │   (React/Vue)   │
│                 │    │                 │    │                 │
│ • Employees     │    │ • Employees     │    │ • Company Mgmt  │
│ • Basic Admin   │    │ • Full Admin    │    │ • Super Admin   │
│ • No Super Admin│    │ • No Super Admin│    │ • System Mgmt   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Admin Portal Features (Planned)
- **React/Vue.js** based admin interface
- **Separate domain**: `admin.snsrooster.com`
- **Rich admin UI** with data tables, charts, forms
- **Advanced analytics** and reporting
- **Bulk operations** and automation

## 📊 Analytics & Reporting

### Company Analytics
- **Attendance Stats**: Present, absent, and on-leave counts
- **Department Analytics**: Performance metrics by department
- **Custom Date Ranges**: Flexible analytics periods
- **Real-time Data**: Live dashboard updates

### System Analytics (Super Admin)
- **Platform Overview**: Total companies, users, employees
- **Subscription Analytics**: Plan adoption and usage
- **System Health**: Performance and error monitoring
- **Usage Trends**: Growth and adoption metrics

## 🧪 Testing

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
```

### Frontend Testing
```bash
cd sns_rooster
flutter test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (including multi-tenant scenarios)
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For issues and questions:
1. Check the [troubleshooting documentation](docs/NETWORK_TROUBLESHOOTING.md)
2. Review the [development setup guide](docs/DEVELOPMENT_SETUP.md)
3. Test super admin functionality with provided credentials
4. Create an issue with detailed information

## Recent Updates

### Super Admin CMS System (Latest - July 2025)
- **Backend**: Complete super admin system with company management
- **Backend**: Subscription plan management with feature configuration
- **Backend**: Multi-tenant data isolation and security
- **Frontend**: Super admin dashboard with system overview
- **Frontend**: Company management interface (basic)
- **Database**: New models for SuperAdmin, SubscriptionPlan, updated Company
- **Security**: Role-based access control with super admin permissions
- **Setup**: Automated super admin and subscription plan creation

### Previous Updates
- Multi-tenant architecture implementation
- Company context middleware and data isolation
- Enhanced analytics with department-wise reporting
- Production-ready logging system
- Break management and timesheet approval systems
