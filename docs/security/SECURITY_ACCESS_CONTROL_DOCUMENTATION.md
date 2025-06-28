# Security Access Control Documentation

## Overview
This document outlines the security measures implemented to ensure users can only access their own information and prevent unauthorized data access.

## Security Issues Identified and Fixed

### 1. Employee Routes Security Vulnerabilities
**Issue**: The `employeeRoutes.js` file had multiple endpoints without authentication middleware, allowing unauthorized access to employee data.

**Endpoints Fixed**:
- `GET /` - Get all employees
- `GET /:id` - Get single employee
- `POST /` - Create new employee
- `PUT /:id` - Update employee
- `DELETE /:id` - Delete employee
- `GET /dashboard` - Employee dashboard

**Security Measures Added**:
- Added `authMiddleware` to all endpoints
- Implemented role-based access control (RBAC)
- Added user ownership validation

### 2. Access Control Rules Implemented

#### Employee Data Access
- **View All Employees**: Admin and Manager roles only
- **View Single Employee**: Admin, Manager, or the employee themselves
- **Create Employee**: Admin role only
- **Update Employee**: Admin, Manager, or the employee themselves
- **Delete Employee**: Admin role only
- **Employee Dashboard**: Any authenticated user (own data only)

#### Attendance Data Access
- **Check-in/Check-out**: Any authenticated user (own data only)
- **Start/End Break**: Any authenticated user (own data only)
- **View Own Attendance**: New endpoint `/my-attendance` for users to view their own data
- **View User Attendance**: Admin, Manager, or the user themselves
- **View All Attendance**: Admin role only

#### User Profile Access
- **View Profile (`/me`)**: Any authenticated user (own profile only)
- **Update Profile (`/me`)**: Any authenticated user (own profile only)
- **View All Users**: Admin and Manager roles only
- **Update Any User**: Admin role or the user themselves
- **Delete User**: Admin role only
- **Upload Profile Picture**: Any authenticated user (own profile only)

## Authentication Middleware

### JWT Token Validation
The `auth.js` middleware validates JWT tokens and extracts user information:
- Validates Bearer token format
- Verifies JWT signature
- Checks token expiration
- Extracts user ID and role from token payload

### Token Payload Structure
```javascript
{
  userId: "user_id",
  email: "user@example.com",
  role: "employee|manager|admin",
  isProfileComplete: boolean
}
```

## Role-Based Access Control (RBAC)

### Role Hierarchy
1. **Admin**: Full access to all data and operations
2. **Manager**: Can view and manage employee data, limited admin functions
3. **Employee**: Can only access and modify their own data

### Access Matrix

| Endpoint | Admin | Manager | Employee |
|----------|-------|---------|----------|
| GET /employees | ✅ | ✅ | ❌ |
| GET /employees/:id | ✅ | ✅ | ✅ (own only) |
| POST /employees | ✅ | ❌ | ❌ |
| PUT /employees/:id | ✅ | ✅ | ✅ (own only) |
| DELETE /employees/:id | ✅ | ❌ | ❌ |
| GET /attendance | ✅ | ❌ | ❌ |
| GET /attendance/my-attendance | ✅ | ✅ | ✅ |
| GET /attendance/user/:userId | ✅ | ✅ | ✅ (own only) |
| GET /auth/users | ✅ | ✅ | ❌ |
| PATCH /auth/users/:id | ✅ | ❌ | ✅ (own only) |
| DELETE /auth/users/:id | ✅ | ❌ | ❌ |

## Security Best Practices Implemented

### 1. Principle of Least Privilege
- Users can only access data they need for their role
- Employees can only access their own data
- Managers have limited administrative access
- Admins have full access

### 2. Input Validation
- JWT token validation
- User ID validation
- Role-based authorization checks

### 3. Error Handling
- Consistent error messages
- No information leakage in error responses
- Proper HTTP status codes

### 4. Data Isolation
- User data is filtered by user ID
- Cross-user data access is prevented
- Database queries include user ownership filters

## Testing Security Controls

### Test Cases to Verify
1. **Unauthorized Access Prevention**
   - Employee trying to access another employee's data
   - Non-admin trying to access admin endpoints
   - Unauthenticated requests to protected endpoints

2. **Role-Based Access**
   - Admin accessing all data
   - Manager accessing employee data
   - Employee accessing only own data

3. **Token Validation**
   - Invalid tokens rejected
   - Expired tokens rejected
   - Missing tokens rejected

## Monitoring and Logging

### Security Events to Monitor
- Failed authentication attempts
- Unauthorized access attempts
- Role escalation attempts
- Unusual data access patterns

### Recommended Logging
```javascript
// Log unauthorized access attempts
console.warn(`Unauthorized access attempt: User ${req.user.userId} (${req.user.role}) tried to access ${req.path}`);

// Log successful admin operations
console.info(`Admin operation: User ${req.user.userId} performed ${req.method} on ${req.path}`);
```

## Future Security Enhancements

### 1. Rate Limiting
- Implement rate limiting on authentication endpoints
- Prevent brute force attacks

### 2. Audit Logging
- Comprehensive audit trail for all data modifications
- User action logging with timestamps

### 3. Session Management
- Token refresh mechanism
- Session timeout handling
- Concurrent session limits

### 4. Data Encryption
- Encrypt sensitive data at rest
- Implement field-level encryption for PII

### 5. API Security Headers
- CORS configuration
- Security headers (HSTS, CSP, etc.)
- Request size limits

## Compliance Considerations

### Data Privacy
- Users can only access their own personal data
- Admin access is logged and controlled
- Data deletion is restricted to admins

### GDPR Compliance
- Right to access own data (implemented)
- Right to rectification (profile updates)
- Right to erasure (admin deletion)
- Data portability (export functionality needed)

## See Also

- [API_CONTRACT.md](../api/API_CONTRACT.md) – API endpoints and data models
- [FEATURES_AND_WORKFLOW.md](../features/FEATURES_AND_WORKFLOW.md) – Payroll, payslip, and workflow documentation
- [PROJECT_ORGANIZATION_GUIDE.md](../PROJECT_ORGANIZATION_GUIDE.md) – Project structure and documentation standards

## Conclusion

The implemented security measures ensure that:
1. Users can only access their own information
2. Role-based access is properly enforced
3. All endpoints are protected with authentication
4. Authorization checks prevent unauthorized data access
5. The system follows security best practices

Regular security audits and penetration testing are recommended to maintain the security posture of the application.