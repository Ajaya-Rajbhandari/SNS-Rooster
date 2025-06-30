# Notification System Implementation

## Overview
This document describes the notification system for the SNS Rooster app, including triggers, backend logic, and best practices for both admin and employee notifications.

---

## Notification Triggers

### 1. Leave Requests
- **Employee applies for leave:**
  - Notify all admins: `[Employee Name] has submitted a leave request from [start] to [end].`
- **Admin approves/rejects leave:**
  - Notify the employee: `Your leave request from [start] to [end] has been approved/rejected.`

### 2. Profile Completion
- **Employee profile incomplete:**
  - Notify admin: `[Employee Name] has not completed their profile.`
  - Notify employee: `Your profile is incomplete. Please update your information.`

### 3. Document Upload/Approval
- **Employee uploads document:**
  - Notify admin: `[Employee Name] uploaded a new document for review.`
- **Admin approves/rejects document:**
  - Notify employee: `Your document was approved/rejected.`

### 4. Timesheet Submission/Approval
- **Employee submits timesheet:**
  - Notify admin: `[Employee Name] submitted a new timesheet.`
- **Admin approves/rejects timesheet:**
  - Notify employee: `Your timesheet for [period] was approved/rejected.`

### 5. Break/Attendance Exception
- **Employee requests break/attendance exception:**
  - Notify admin: `[Employee Name] requested a break exception.`
- **Admin approves/rejects exception:**
  - Notify employee: `Your break exception was approved/rejected.`

### 6. Missing Actions (Reminders)
- **Employee hasn't submitted timesheet by deadline:**
  - Notify admin: `[Employee Name] has not submitted their timesheet.`
- **Employee hasn't uploaded required document:**
  - Notify admin: `[Employee Name] has not uploaded their ID document.`

---

## Implementation Approach

- **Backend:**
  - In each relevant controller (leave, employee, document, timesheet, break), after the action is performed, create a notification using the Notification model.
  - Use `role: 'admin'` for admin notifications, and `user: <employeeId>` for employee notifications.
  - For reminders, use scheduled scripts or on-demand checks.

- **Frontend:**
  - NotificationProvider fetches and displays notifications for the current user.
  - NotificationBell shows unread count and navigates to the notification screen.
  - Tapping a notification can navigate to a relevant page using the `link` field.

---

## Best Practices
- Use both popups and notifications for critical actions.
- Only show notifications relevant to the user's role or userId.
- Register all actionable notification links in the app's routes.
- Use scheduled scripts for periodic reminders (e.g., incomplete profiles).

---

## Next Steps
- Implement notification logic in all relevant backend controllers.
- Continue to expand notification triggers as new features are added. 