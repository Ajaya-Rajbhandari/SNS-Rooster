# Backend Manual QA Checklist

A comprehensive manual QA checklist for SNS Rooster backend/API. Use this to verify endpoints and business logic using Postman, curl, or your frontend.

---

## 1. Authentication & User Management
- [ ] Register User (`POST /api/auth/register`)
  - [ ] Required fields, duplicate email, password rules
- [ ] Login (`POST /api/auth/login`)
  - [ ] Valid/invalid credentials, locked/disabled users
- [ ] JWT Token
  - [ ] Token returned, required for protected endpoints
  - [ ] Expired/invalid tokens
- [ ] Password Reset
  - [ ] Request reset (`POST /api/auth/request-reset`)
  - [ ] Reset password (`POST /api/auth/reset-password`)
  - [ ] Email sent, token validity, reset flow
- [ ] Email Verification (`POST /api/auth/verify-email`)
  - [ ] Valid/invalid/expired tokens

## 2. Profile
- [ ] Get Profile (`GET /api/auth/me`)
  - [ ] With/without valid token
- [ ] Update Profile (`PUT /api/auth/me`)
  - [ ] Field validation, avatar upload

## 3. Attendance
- [ ] Clock In/Out
  - [ ] Clock in (`POST /api/attendance/check-in`)
  - [ ] Clock out (`POST /api/attendance/check-out`)
  - [ ] Duplicate clock-in/out, time validation
- [ ] Breaks
  - [ ] Start break (`POST /api/attendance/start-break`)
  - [ ] End break (`POST /api/attendance/end-break`)
  - [ ] Overlapping breaks, break types
- [ ] Attendance Summary
  - [ ] My attendance (`GET /api/attendance/my-attendance`)
  - [ ] Summary by user (`GET /api/attendance/summary/:userId`)

## 4. Leave Management
- [ ] Request Leave (`POST /api/leave/request`)
  - [ ] Overlapping, invalid dates, leave types
- [ ] View Leave
  - [ ] My leaves (`GET /api/leave/my-leaves`)
  - [ ] All leaves (admin) (`GET /api/leave/all`)
- [ ] Approve/Reject Leave
  - [ ] Approve (`POST /api/leave/approve`)
  - [ ] Reject (`POST /api/leave/reject`)

## 5. Payroll
- [ ] View Payslips
  - [ ] User payslips (`GET /api/payroll/user/:userId`)
  - [ ] Download PDF/CSV
- [ ] Admin Payroll Actions
  - [ ] Generate payroll (`POST /api/payroll/generate`)
  - [ ] Employee payroll (`GET /api/payroll/employee/:employeeId`)

## 6. Notifications
- [ ] Get Notifications (`GET /api/notifications`)
- [ ] Mark as Read/Clear
  - [ ] Mark all read (`POST /api/notifications/mark-all-read`)
  - [ ] Clear all (`POST /api/notifications/clear-all`)

## 7. File Uploads
- [ ] Upload Avatar/Document
  - [ ] Upload avatar (`POST /api/auth/upload-avatar`)
  - [ ] Upload document (`POST /api/auth/upload-document`)
  - [ ] File size/type limits, invalid files
- [ ] Download/View Files
  - [ ] Avatars (`GET /uploads/avatars/:filename`)
  - [ ] Documents (`GET /uploads/documents/:filename`)

## 8. Admin Features
- [ ] User Management
  - [ ] List users (`GET /api/auth/users`)
  - [ ] Create user (`POST /api/auth/users`)
  - [ ] Update user (`PUT /api/auth/users/:id`)
  - [ ] Delete user (`DELETE /api/auth/users/:id`)
- [ ] Company/Settings
  - [ ] Company settings (`GET/PUT /api/admin/settings/company`)
  - [ ] Payroll cycle (`GET/PUT /api/admin/settings/payroll-cycle`)
  - [ ] Tax settings (`GET/PUT /api/admin/settings/tax`)

## 9. Analytics & Reports
- [ ] Attendance/Payroll Analytics
  - [ ] Summary (`GET /api/analytics/summary`)
  - [ ] Admin overview (`GET /api/analytics/admin/overview`)
  - [ ] Generate report (`GET /api/analytics/admin/generate-report`)

## 10. General
- [ ] CORS Headers (all endpoints)
- [ ] Error Handling (invalid input, unauthorized, forbidden, not found)
- [ ] Rate Limiting/Security (brute force, SQL injection, XSS, etc.) 