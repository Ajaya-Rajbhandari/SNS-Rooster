# User-Employee Workflow Implementation

## Overview
This document describes the implementation of a proper user-employee workflow in the SNS Rooster Admin Portal, ensuring that users (authentication layer) are created first, followed by employee records (business layer) that are linked to existing users.

## Architecture Principles

### 1. User-First Approach
- **Users** represent the authentication layer (login credentials, roles, permissions)
- **Employees** represent the business layer (job details, payroll, attendance)
- Users must exist before employees can be created
- One user can have one employee record (1:1 relationship)

### 2. Data Hierarchy
```
Company
├── Users (Authentication Layer)
│   ├── Super Admin (system-wide access)
│   ├── Admin (company-level access)
│   └── Employee (limited access)
└── Employees (Business Layer)
    ├── Job Details
    ├── Payroll Information
    ├── Attendance Records
    └── Performance Data
```

## Implementation Details

### 1. User Management

#### Individual User Creation
- **Location**: Admin Portal → Users → "ADD USER"
- **Process**: 
  1. Fill user details (name, email, role, company)
  2. System creates user account with default password
  3. Email verification sent automatically
  4. User can log in after email verification

#### Bulk User Creation
- **Location**: Admin Portal → Users → "BULK OPERATIONS"
- **Features**:
  - Manual entry of multiple users
  - CSV import functionality
  - Template download for CSV format
  - Validation and error handling

#### CSV Import Format
```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position
John,Doe,john.doe@company.com,employee,company_id_here,IT,Developer
Jane,Smith,jane.smith@company.com,admin,company_id_here,HR,Manager
```

**Required Fields**:
- `FirstName`: User's first name
- `LastName`: User's last name
- `Email`: Unique email address
- `Role`: `admin` or `employee`
- `CompanyId`: Company ID (can be filled automatically)
- `Department`: User's department (optional)
- `Position`: User's job position (optional)

### 2. Employee Management

#### Employee Creation Workflow
- **Location**: Admin Portal → Employees → "ADD EMPLOYEE"
- **Process**:
  1. Select company first
  2. Click "ADD EMPLOYEE" → Opens User Selection Dialog
  3. Choose from available users (those without existing employee records)
  4. System creates employee record linked to selected user
  5. Employee appears in employee management table

#### User Selection Dialog
- **Purpose**: Select existing users for employee creation
- **Filters**:
  - Only shows users from selected company
  - Excludes users who already have employee records
  - Excludes super admin users
  - Only shows active users
- **Features**:
  - Search functionality
  - User details display (name, email, role, department)
  - Radio button selection

### 3. User-Employee Relationship

#### Database Schema
```javascript
// User Model
{
  _id: ObjectId,
  firstName: String,
  lastName: String,
  email: String,
  role: 'super_admin' | 'admin' | 'employee',
  companyId: ObjectId,
  isEmailVerified: Boolean,
  isActive: Boolean,
  // ... other user fields
}

// Employee Model
{
  _id: ObjectId,
  userId: ObjectId, // Reference to User
  companyId: ObjectId,
  firstName: String,
  lastName: String,
  email: String,
  position: String,
  department: String,
  employeeType: String,
  // ... other employee fields
}
```

#### Relationship Rules
- **One-to-One**: Each user can have at most one employee record
- **Mandatory Link**: Employee records must be linked to existing users
- **Company Consistency**: User and employee must belong to the same company
- **Role Validation**: Employee records can only be created for `admin` or `employee` users

## User Interface Changes

### 1. User Management Page
- **Enhanced Bulk Operations**: Added CSV import functionality
- **Template Download**: Provides CSV template with correct format
- **Validation**: Real-time validation of CSV data
- **Error Handling**: Clear error messages for import issues

### 2. Employee Management Page
- **User Selection Integration**: "ADD EMPLOYEE" opens user selection dialog
- **Available Users Display**: Shows users without employee records
- **Search and Filter**: Easy user selection with search functionality
- **Clear Workflow**: Step-by-step process for employee creation

### 3. Bulk User Operations Dialog
- **Three Tabs**: Create, Update, Delete operations
- **CSV Import**: File upload with validation
- **Template Download**: Standardized CSV format
- **Preview**: Shows imported data before creation
- **Error Reporting**: Detailed feedback on import issues

## Benefits of This Approach

### 1. Data Integrity
- **Consistent User Management**: All users go through the same creation process
- **Email Verification**: Ensures valid email addresses
- **Role-Based Access**: Proper permission management
- **Audit Trail**: Complete history of user and employee creation

### 2. Operational Efficiency
- **Bulk Operations**: Create multiple users quickly via CSV
- **Standardized Process**: Consistent workflow for all user creation
- **Error Prevention**: Validation prevents invalid data entry
- **Template System**: Reduces data entry errors

### 3. Security
- **Email Verification**: Prevents unauthorized account creation
- **Role Separation**: Clear distinction between authentication and business data
- **Access Control**: Proper permission management
- **Audit Logging**: Track all user and employee changes

## Usage Examples

### Example 1: Creating Individual Employee
1. **Create User**: Go to Users → "ADD USER"
   - Name: John Doe
   - Email: john.doe@company.com
   - Role: Employee
   - Company: ABC Corp
2. **Create Employee**: Go to Employees → "ADD EMPLOYEE"
   - Select ABC Corp
   - Choose John Doe from user list
   - Fill employee details (position, department, etc.)

### Example 2: Bulk User Creation via CSV
1. **Download Template**: Users → "BULK OPERATIONS" → "Download Template"
2. **Fill CSV**: Add user data to template
3. **Import CSV**: "BULK OPERATIONS" → "Import CSV"
4. **Review**: Check imported data
5. **Create Users**: Click "Create Users"

### Example 3: Employee Creation from Bulk Users
1. **Create Users**: Use bulk operations to create multiple users
2. **Create Employees**: Go to Employees and create employee records for each user
3. **Link Records**: System automatically links users to employees

## Technical Implementation

### 1. Frontend Components
- `UserSelectionDialog.tsx`: Dialog for selecting users for employee creation
- `BulkUserOperations.tsx`: Enhanced with CSV import functionality
- `EmployeeManagementPage.tsx`: Updated to use user selection workflow

### 2. Backend API Endpoints
- `POST /api/super-admin/users/bulk-create`: Create multiple users
- `POST /api/super-admin/employees/{companyId}`: Create employee from user
- `GET /api/super-admin/users`: Get users for selection

### 3. Data Validation
- **CSV Validation**: Headers, required fields, data types
- **User Validation**: Email uniqueness, role validation
- **Employee Validation**: User existence, company consistency

## Future Enhancements

### 1. Advanced Features
- **Bulk Employee Creation**: Create multiple employees from CSV
- **User-Employee Sync**: Automatic synchronization of user/employee data
- **Import Templates**: Role-specific CSV templates
- **Data Migration**: Tools for existing data migration

### 2. Workflow Improvements
- **Approval Process**: Manager approval for user creation
- **Onboarding Flow**: Automated onboarding for new employees
- **Integration**: HR system integration for employee data
- **Notifications**: Email notifications for user/employee creation

### 3. Analytics and Reporting
- **User Creation Analytics**: Track user creation patterns
- **Employee Conversion Rates**: Monitor user-to-employee conversion
- **Import Success Rates**: Track CSV import success/failure rates
- **Audit Reports**: Comprehensive audit trails

## Troubleshooting

### Common Issues

#### 1. CSV Import Errors
- **Missing Headers**: Ensure all required headers are present
- **Invalid Data**: Check for proper email formats and required fields
- **Company ID**: Verify company IDs exist in the system

#### 2. User Selection Issues
- **No Users Available**: Create users first before creating employees
- **User Already Has Employee**: User already linked to employee record
- **Company Mismatch**: Ensure user and employee belong to same company

#### 3. Email Verification Issues
- **Email Not Sent**: Check email service configuration
- **Verification Link**: Ensure FRONTEND_URL is set correctly
- **Token Expiration**: Verification links expire after 24 hours

### Debug Steps
1. **Check User Creation**: Verify users exist in user management
2. **Validate CSV Format**: Use template and check data format
3. **Review Error Messages**: Check console and API responses
4. **Test Email Service**: Verify email configuration
5. **Check Permissions**: Ensure proper role assignments

## Related Files

### Frontend
- `admin-portal/src/pages/UserManagementPage.tsx`
- `admin-portal/src/pages/EmployeeManagementPage.tsx`
- `admin-portal/src/components/UserSelectionDialog.tsx`
- `admin-portal/src/components/BulkUserOperations.tsx`

### Backend
- `rooster-backend/controllers/super-admin-controller.js`
- `rooster-backend/models/User.js`
- `rooster-backend/models/Employee.js`
- `rooster-backend/routes/superAdminRoutes.js`

### Documentation
- `docs/features/EMAIL_VERIFICATION_SUPER_ADMIN.md`
- `rooster-backend/EMAIL_SETUP_GUIDE.md` 