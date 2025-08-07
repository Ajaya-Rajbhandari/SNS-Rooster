# Manual Testing Checklist

## Overview
This document provides a comprehensive manual testing checklist for all the features we've implemented in the SNS Rooster Admin Portal.

## 🧪 **Test Environment Setup**

### Prerequisites
- [ ] Backend server running on port 3000
- [ ] Admin portal running on port 3001
- [ ] Database connection established
- [ ] Email service configured
- [ ] Super admin account created

### Test Data Preparation
- [ ] Create test company
- [ ] Create test super admin user
- [ ] Prepare CSV test files
- [ ] Set up email verification testing

---

## 🔐 **1. Password Generation Rules Testing**

### Test Case 1.1: Individual Password Rules
**Objective**: Test each password generation rule individually

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "ADD USER"
2. **Test firstName+lastName rule**:
   - [ ] Enter: First Name: "John", Last Name: "Doe"
   - [ ] Select password rule: "firstName+lastName"
   - [ ] Verify generated password: "john+doe"
   - [ ] Create user and verify password works

3. **Test email+123 rule**:
   - [ ] Enter: Email: "jane@company.com"
   - [ ] Select password rule: "email+123"
   - [ ] Verify generated password: "jane@company.com+123"
   - [ ] Create user and verify password works

4. **Test firstName123 rule**:
   - [ ] Enter: First Name: "Bob"
   - [ ] Select password rule: "firstName123"
   - [ ] Verify generated password: "bob123"
   - [ ] Create user and verify password works

5. **Test lastName123 rule**:
   - [ ] Enter: Last Name: "Wilson"
   - [ ] Select password rule: "lastName123"
   - [ ] Verify generated password: "wilson123"
   - [ ] Create user and verify password works

6. **Test email rule**:
   - [ ] Enter: Email: "alice@company.com"
   - [ ] Select password rule: "email"
   - [ ] Verify generated password: "alice@company.com"
   - [ ] Create user and verify password works

7. **Test default rule**:
   - [ ] Select password rule: "default"
   - [ ] Verify generated password: "defaultPassword123"
   - [ ] Create user and verify password works

#### Expected Results:
- [ ] All password rules generate correct passwords
- [ ] Users can log in with generated passwords
- [ ] Password field shows real-time updates when rule changes
- [ ] Manual password override works correctly

---

## 📁 **2. CSV Import Testing**

### Test Case 2.1: CSV Template Download
**Objective**: Test CSV template download functionality

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "BULK OPERATIONS"
2. **Click**: "Download Template" button
3. **Verify**: CSV file downloads with correct format
4. **Check**: Template contains all required headers:
   - [ ] FirstName
   - [ ] LastName
   - [ ] Email
   - [ ] Role
   - [ ] CompanyId
   - [ ] Department
   - [ ] Position
   - [ ] PasswordRule

#### Expected Results:
- [ ] CSV file downloads successfully
- [ ] Template contains example data
- [ ] Headers match expected format

### Test Case 2.2: CSV Import with Password Rules
**Objective**: Test CSV import with different password rules

#### Test Steps:
1. **Prepare CSV file** with test data:
   ```csv
   FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule
   John,Doe,john.doe@test.com,employee,company_id,IT,Developer,firstName+lastName
   Jane,Smith,jane.smith@test.com,admin,company_id,HR,Manager,email+123
   Bob,Wilson,bob@test.com,employee,company_id,Sales,Manager,firstName123
   ```

2. **Navigate to**: Admin Portal → Users → "BULK OPERATIONS"
3. **Click**: "Import CSV" button
4. **Upload**: Test CSV file
5. **Verify**: Data is parsed correctly
6. **Check**: Generated passwords match rules:
   - [ ] john+doe (firstName+lastName)
   - [ ] jane.smith@test.com+123 (email+123)
   - [ ] bob123 (firstName123)

7. **Click**: "Create Users"
8. **Verify**: Users are created successfully

#### Expected Results:
- [ ] CSV file uploads without errors
- [ ] Data is parsed and displayed in table
- [ ] Password rules generate correct passwords
- [ ] Users are created successfully
- [ ] Success message shows correct count

### Test Case 2.3: CSV Validation Testing
**Objective**: Test CSV validation and error handling

#### Test Steps:
1. **Test missing headers**:
   - [ ] Create CSV with missing "Email" header
   - [ ] Upload and verify error message
   - [ ] Verify no users are created

2. **Test invalid email format**:
   - [ ] Create CSV with invalid email "invalid-email"
   - [ ] Upload and verify error message
   - [ ] Verify user is not created

3. **Test duplicate emails**:
   - [ ] Create CSV with existing email
   - [ ] Upload and verify error message
   - [ ] Verify duplicate user is not created

4. **Test empty required fields**:
   - [ ] Create CSV with empty FirstName
   - [ ] Upload and verify error message
   - [ ] Verify user is not created

#### Expected Results:
- [ ] Clear error messages for validation failures
- [ ] Failed records are reported correctly
- [ ] Valid records are still processed
- [ ] No partial data corruption

---

## 👥 **3. User-Employee Workflow Testing**

### Test Case 3.1: User Creation First
**Objective**: Test that users are created before employees

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "ADD USER"
2. **Create user**:
   - [ ] Fill user details (name, email, role, company)
   - [ ] Select password rule
   - [ ] Create user
   - [ ] Verify user appears in user list

3. **Navigate to**: Admin Portal → Employees
4. **Verify**: User does not appear in employee list yet

#### Expected Results:
- [ ] User is created successfully
- [ ] User appears in user management
- [ ] No employee record exists yet
- [ ] Email verification is sent (if applicable)

### Test Case 3.2: Employee Creation from User
**Objective**: Test employee creation from existing user

#### Test Steps:
1. **Navigate to**: Admin Portal → Employees
2. **Select company** (if not already selected)
3. **Click**: "ADD EMPLOYEE"
4. **Verify**: User Selection Dialog opens
5. **Check**: Available users are displayed:
   - [ ] Only users from selected company
   - [ ] Only users without existing employee records
   - [ ] Excludes super admin users
   - [ ] Shows user details (name, email, role, department)

6. **Select user** and click "Select"
7. **Verify**: Employee creation form opens with user data pre-filled
8. **Fill employee details**:
   - [ ] Position
   - [ ] Department
   - [ ] Employee Type
   - [ ] Employee ID
   - [ ] Salary information

9. **Create employee**
10. **Verify**: Employee appears in employee list

#### Expected Results:
- [ ] User selection dialog shows correct users
- [ ] Employee form is pre-filled with user data
- [ ] Employee is created successfully
- [ ] Employee is linked to user
- [ ] User no longer appears in available users list

### Test Case 3.3: User-Employee Relationship Validation
**Objective**: Test relationship validation rules

#### Test Steps:
1. **Try to create employee for user with existing employee**:
   - [ ] Select user who already has employee record
   - [ ] Verify user is not available in selection dialog

2. **Try to create employee for user from different company**:
   - [ ] Create user in Company A
   - [ ] Try to create employee in Company B
   - [ ] Verify error message

3. **Try to create employee for non-existent user**:
   - [ ] Use fake user ID
   - [ ] Verify error message

#### Expected Results:
- [ ] Users with existing employees are not selectable
- [ ] Cross-company employee creation is prevented
- [ ] Invalid user IDs are rejected
- [ ] Clear error messages are shown

---

## 📧 **4. Email Verification Testing**

### Test Case 4.1: Email Verification for New Users
**Objective**: Test email verification for users created via super admin

#### Test Steps:
1. **Create user** via super admin portal
2. **Check email** for verification link
3. **Click verification link**
4. **Verify**: User can now log in

#### Expected Results:
- [ ] Verification email is sent
- [ ] Email contains correct verification link
- [ ] Link points to correct frontend URL
- [ ] User can verify email successfully
- [ ] User can log in after verification

### Test Case 4.2: Email Verification for Bulk Users
**Objective**: Test email verification for bulk-created users

#### Test Steps:
1. **Create multiple users** via CSV import
2. **Check emails** for verification links
3. **Verify each user** via email link
4. **Test login** for each verified user

#### Expected Results:
- [ ] All users receive verification emails
- [ ] Each email contains unique verification link
- [ ] All users can verify successfully
- [ ] All users can log in after verification

### Test Case 4.3: Super Admin Email Verification
**Objective**: Test that super admins don't need email verification

#### Test Steps:
1. **Create super admin user**
2. **Check**: No verification email is sent
3. **Verify**: Super admin can log in immediately

#### Expected Results:
- [ ] No verification email sent to super admin
- [ ] Super admin is auto-verified
- [ ] Super admin can log in immediately

---

## 🔄 **5. Bulk Operations Testing**

### Test Case 5.1: Bulk User Creation
**Objective**: Test bulk user creation functionality

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "BULK OPERATIONS"
2. **Add multiple users manually**:
   - [ ] Click "Add User" multiple times
   - [ ] Fill in user details
   - [ ] Select different password rules
   - [ ] Verify passwords are generated correctly

3. **Create users**:
   - [ ] Click "Create Users"
   - [ ] Verify success message
   - [ ] Check user list for new users

#### Expected Results:
- [ ] Multiple users can be added
- [ ] Password rules work for each user
- [ ] All users are created successfully
- [ ] Success message shows correct count

### Test Case 5.2: Bulk User Update
**Objective**: Test bulk user update functionality

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "BULK OPERATIONS"
2. **Switch to "Bulk Update" tab**
3. **Select multiple users**:
   - [ ] Use checkboxes to select users
   - [ ] Verify selection count is displayed

4. **Update user fields**:
   - [ ] Change role for selected users
   - [ ] Update department
   - [ ] Update position
   - [ ] Change status

5. **Apply updates**:
   - [ ] Click "Update Users"
   - [ ] Verify success message
   - [ ] Check user list for changes

#### Expected Results:
- [ ] Users can be selected individually or all at once
- [ ] Updates are applied to selected users only
- [ ] Success message shows correct count
- [ ] Changes are reflected in user list

### Test Case 5.3: Bulk User Delete
**Objective**: Test bulk user deletion functionality

#### Test Steps:
1. **Navigate to**: Admin Portal → Users → "BULK OPERATIONS"
2. **Switch to "Bulk Delete" tab**
3. **Select users to delete**:
   - [ ] Use checkboxes to select users
   - [ ] Verify selection count is displayed

4. **Delete users**:
   - [ ] Click "Delete Users"
   - [ ] Confirm deletion in dialog
   - [ ] Verify success message
   - [ ] Check user list for removed users

#### Expected Results:
- [ ] Confirmation dialog appears
- [ ] Selected users are deleted
- [ ] Success message shows correct count
- [ ] Users are removed from list
- [ ] Super admin users cannot be deleted

---

## 🎯 **6. Integration Testing**

### Test Case 6.1: End-to-End Workflow
**Objective**: Test complete user-employee workflow

#### Test Steps:
1. **Create users via CSV import**:
   - [ ] Import CSV with multiple users
   - [ ] Verify all users are created
   - [ ] Verify email verification is sent

2. **Create employees for users**:
   - [ ] Go to employee management
   - [ ] Create employees for imported users
   - [ ] Verify employee-user relationships

3. **Test user login**:
   - [ ] Verify emails for all users
   - [ ] Test login with generated passwords
   - [ ] Verify users can access system

#### Expected Results:
- [ ] Complete workflow works end-to-end
- [ ] All users receive verification emails
- [ ] All employees are created successfully
- [ ] All users can log in and access system

### Test Case 6.2: Data Consistency
**Objective**: Test data consistency across user and employee records

#### Test Steps:
1. **Create user and employee**
2. **Update user details**:
   - [ ] Change user name
   - [ ] Change user email
   - [ ] Change user role

3. **Verify employee data**:
   - [ ] Check if employee data is updated
   - [ ] Verify relationship is maintained

#### Expected Results:
- [ ] User updates are reflected correctly
- [ ] Employee relationship is maintained
- [ ] No data corruption occurs

---

## 🐛 **7. Error Handling Testing**

### Test Case 7.1: Network Error Handling
**Objective**: Test error handling for network issues

#### Test Steps:
1. **Disconnect network** during operation
2. **Try to create user**
3. **Verify error message**
4. **Reconnect network**
5. **Retry operation**

#### Expected Results:
- [ ] Clear error message for network issues
- [ ] Operation can be retried
- [ ] No data corruption

### Test Case 7.2: Validation Error Handling
**Objective**: Test validation error handling

#### Test Steps:
1. **Try invalid operations**:
   - [ ] Create user with invalid email
   - [ ] Create employee for non-existent user
   - [ ] Import CSV with invalid data

2. **Verify error messages**:
   - [ ] Error messages are clear and helpful
   - [ ] Error messages indicate how to fix issues

#### Expected Results:
- [ ] Clear validation error messages
- [ ] No system crashes
- [ ] User can correct and retry

---

## 📊 **8. Performance Testing**

### Test Case 8.1: Bulk Operations Performance
**Objective**: Test performance with large datasets

#### Test Steps:
1. **Create large CSV file** (100+ users)
2. **Import large CSV**:
   - [ ] Monitor import time
   - [ ] Check memory usage
   - [ ] Verify all users are created

3. **Test bulk operations**:
   - [ ] Select all users
   - [ ] Perform bulk update
   - [ ] Monitor performance

#### Expected Results:
- [ ] Large imports complete within reasonable time
- [ ] No memory leaks
- [ ] All operations complete successfully
- [ ] UI remains responsive

---

## ✅ **Test Completion Checklist**

### Documentation
- [ ] All test cases executed
- [ ] Results documented
- [ ] Issues logged with steps to reproduce
- [ ] Performance metrics recorded

### Quality Assurance
- [ ] All features work as expected
- [ ] No critical bugs found
- [ ] Performance is acceptable
- [ ] User experience is smooth

### Deployment Readiness
- [ ] All tests pass
- [ ] Documentation is complete
- [ ] Known issues are documented
- [ ] Release notes prepared

---

## 📝 **Test Results Template**

### Test Session Information
- **Date**: _______________
- **Tester**: _______________
- **Environment**: _______________
- **Version**: _______________

### Test Results Summary
- **Total Test Cases**: _______________
- **Passed**: _______________
- **Failed**: _______________
- **Skipped**: _______________

### Issues Found
1. **Issue 1**:
   - **Severity**: _______________
   - **Description**: _______________
   - **Steps to Reproduce**: _______________
   - **Expected vs Actual**: _______________

2. **Issue 2**:
   - **Severity**: _______________
   - **Description**: _______________
   - **Steps to Reproduce**: _______________
   - **Expected vs Actual**: _______________

### Recommendations
- **For Deployment**: _______________
- **For Future Testing**: _______________
- **For Documentation**: _______________ 