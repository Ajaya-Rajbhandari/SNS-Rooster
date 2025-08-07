# Password Generation Rules for CSV User Import

## Overview
This document describes the password generation rules implemented for bulk user creation via CSV import in the SNS Rooster Admin Portal. The system supports multiple password generation patterns to provide flexibility while maintaining security.

## Password Generation Rules

### Available Rules

| Rule | Pattern | Example | Description |
|------|---------|---------|-------------|
| `firstName+lastName` | `{firstName}+{lastName}` | `john+doe` | Combines first and last name with + separator |
| `email+123` | `{email}+123` | `john.doe@company.com+123` | Uses email with +123 suffix |
| `firstName123` | `{firstName}123` | `john123` | First name with 123 suffix |
| `lastName123` | `{lastName}123` | `doe123` | Last name with 123 suffix |
| `email` | `{email}` | `john.doe@company.com` | Uses email as password |
| `default` | `defaultPassword123` | `defaultPassword123` | System default password |

### CSV Template Format

```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
John,Doe,john.doe@example.com,employee,company_id_here,IT,Developer,firstName+lastName
Jane,Smith,jane.smith@example.com,admin,company_id_here,HR,Manager,email+123
Bob,Wilson,bob@company.com,employee,company_id_here,Sales,Manager,default
Alice,Johnson,alice@company.com,employee,company_id_here,Marketing,Coordinator,firstname123
```

## Implementation Details

### 1. Frontend Implementation

#### Password Generation Function
```typescript
const generatePassword = (rule: string, userData: {
  firstName: string;
  lastName: string;
  email: string;
}): string => {
  const { firstName, lastName, email } = userData;
  
  switch (rule.toLowerCase()) {
    case 'firstname+lastname':
      return `${firstName.toLowerCase()}+${lastName.toLowerCase()}`;
    case 'email+123':
      return `${email}+123`;
    case 'firstname123':
      return `${firstName.toLowerCase()}123`;
    case 'lastname123':
      return `${lastName.toLowerCase()}123`;
    case 'email':
      return email;
    case 'default':
    default:
      return 'defaultPassword123';
  }
};
```

#### CSV Parsing with Password Rules
```typescript
const parseCsvFile = (file: File) => {
  // ... file reading logic ...
  
  const passwordRule = values[headers.indexOf('passwordrule')] || 'default';
  
  const user = {
    firstName,
    lastName,
    email,
    role: values[headers.indexOf('role')] || 'employee',
    companyId: values[headers.indexOf('companyid')] || selectedCompanyId || '',
    department: values[headers.indexOf('department')] || '',
    position: values[headers.indexOf('position')] || '',
    password: generatePassword(passwordRule, { firstName, lastName, email }),
    passwordRule
  };
};
```

### 2. User Interface Features

#### Password Rule Selection
- **Dropdown Menu**: Users can select password generation rules
- **Real-time Preview**: Generated password is shown immediately
- **Manual Override**: Users can manually edit generated passwords
- **Rule Validation**: Invalid rules default to 'default'

#### CSV Import Validation
- **Header Validation**: Ensures required headers are present
- **Rule Validation**: Validates password rule format
- **Data Validation**: Checks for required fields
- **Error Reporting**: Clear error messages for invalid data

## Usage Examples

### Example 1: Simple Password Rules
```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
John,Doe,john.doe@company.com,employee,company_id_here,IT,Developer,firstName+lastName
```
**Generated Password**: `john+doe`

### Example 2: Email-based Passwords
```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
Jane,Smith,jane.smith@company.com,admin,company_id_here,HR,Manager,email+123
```
**Generated Password**: `jane.smith@company.com+123`

### Example 3: Name-based Passwords
```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
Bob,Wilson,bob@company.com,employee,company_id_here,Sales,Manager,firstName123
```
**Generated Password**: `bob123`

### Example 4: Default Passwords
```csv
FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
Alice,Johnson,alice@company.com,employee,company_id_here,Marketing,Coordinator,default
```
**Generated Password**: `defaultPassword123`

## Security Considerations

### 1. Password Strength
- **Rule-based Generation**: Provides predictable but manageable passwords
- **Manual Override**: Allows for custom strong passwords
- **Email Verification**: Users must verify email before first login
- **Password Reset**: Users can reset passwords after verification

### 2. Best Practices
- **Default Rule**: Use 'default' for most users
- **Custom Passwords**: Use manual override for sensitive accounts
- **Email Communication**: Inform users of their initial passwords
- **Password Policy**: Enforce password changes on first login

### 3. Security Recommendations
- **Avoid Email-only**: Don't use 'email' rule for sensitive accounts
- **Use Complex Rules**: Prefer 'firstName+lastName' or 'email+123'
- **Manual Override**: For admin accounts, use custom passwords
- **Regular Updates**: Encourage users to change passwords regularly

## Workflow Integration

### 1. User Creation Process
1. **CSV Import**: Upload CSV with password rules
2. **Password Generation**: System generates passwords based on rules
3. **User Creation**: Backend creates users with generated passwords
4. **Email Verification**: Verification emails sent to users
5. **First Login**: Users can log in with generated passwords

### 2. Employee Creation
1. **User Selection**: Choose from users created via CSV import
2. **Employee Record**: Create employee record linked to user
3. **Data Consistency**: Ensure user and employee data match

## Error Handling

### 1. Invalid Password Rules
- **Unknown Rule**: Defaults to 'default' rule
- **Missing Rule**: Uses 'default' rule
- **Case Insensitive**: Rules are case-insensitive

### 2. CSV Import Errors
- **Missing Headers**: Clear error message with required headers
- **Invalid Data**: Validation errors for each row
- **Empty Fields**: Skips rows with missing required fields

### 3. Password Generation Errors
- **Empty Names**: Uses email-based rules as fallback
- **Invalid Email**: Uses default password
- **Special Characters**: Handles special characters in names

## Future Enhancements

### 1. Advanced Password Rules
- **Custom Patterns**: User-defined password patterns
- **Random Generation**: Secure random password generation
- **Password Strength**: Password strength validation
- **Company Policies**: Company-specific password policies

### 2. Integration Features
- **LDAP Integration**: Import passwords from LDAP
- **SSO Integration**: Single sign-on password management
- **Password Sync**: Synchronize passwords across systems
- **Audit Logging**: Track password generation and changes

### 3. User Experience
- **Password Preview**: Show password strength indicators
- **Bulk Password Reset**: Reset passwords for multiple users
- **Password History**: Track password changes
- **Expiration Policies**: Password expiration management

## Troubleshooting

### Common Issues

#### 1. Password Generation Problems
- **Rule Not Working**: Check rule spelling and case
- **Empty Passwords**: Verify user data is complete
- **Special Characters**: Check for encoding issues

#### 2. CSV Import Issues
- **Header Mismatch**: Ensure exact header names
- **Data Format**: Check CSV format and encoding
- **Missing Fields**: Verify all required fields are present

#### 3. User Creation Errors
- **Duplicate Emails**: Check for existing users
- **Invalid Company**: Verify company IDs exist
- **Role Validation**: Ensure valid role values

### Debug Steps
1. **Check CSV Format**: Verify headers and data format
2. **Test Password Rules**: Try different rules manually
3. **Validate User Data**: Check for missing or invalid data
4. **Review Error Messages**: Check console and API responses
5. **Test Individual Users**: Create users one by one to isolate issues

## Related Files

### Frontend
- `admin-portal/src/components/BulkUserOperations.tsx`
- `admin-portal/src/pages/UserManagementPage.tsx`

### Backend
- `rooster-backend/controllers/super-admin-controller.js`
- `rooster-backend/models/User.js`

### Documentation
- `docs/features/USER_EMPLOYEE_WORKFLOW.md`
- `docs/features/EMAIL_VERIFICATION_SUPER_ADMIN.md` 