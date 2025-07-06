# Frontend Manual QA Checklist

A comprehensive manual QA checklist for SNS Rooster frontend (Flutter web/mobile). Use this to verify user flows, UI, and integration with the backend.

---

## 1. Authentication & User Flows
- [ ] Login (admin & employee)
- [ ] Login with invalid credentials (error handling)
- [ ] Logout flow
- [ ] Password reset (request, email, reset)
- [ ] Email verification (deep link, verify, error states)
- [ ] Registration (if available)

## 2. Profile
- [ ] View profile (avatar, info, roles)
- [ ] Edit profile (fields, avatar upload)
- [ ] Avatar displays correctly in all locations (profile, dashboard, side nav)

## 3. Dashboard
- [ ] Admin dashboard loads and displays correct data
- [ ] Employee dashboard loads and displays correct data
- [ ] Navigation between dashboard and other screens

## 4. Attendance
- [ ] Clock in/out
- [ ] Break start/end
- [ ] Attendance summary and details

## 5. Leave Management
- [ ] Request leave
- [ ] View leave status/history
- [ ] Approve/reject leave (admin)

## 6. Payroll
- [ ] View payslips
- [ ] Download payslip PDF/CSV
- [ ] Payroll summary (admin)

## 7. Notifications
- [ ] Receive and view notifications
- [ ] Mark notifications as read/clear

## 8. File Uploads
- [ ] Upload documents (web & mobile)
- [ ] Upload avatar (web & mobile)
- [ ] Download/view uploaded files

## 9. Navigation & Routing
- [ ] Deep links (verify email, reset password)
- [ ] Navigation drawer/side nav works as expected
- [ ] Back button and browser navigation (web)

## 10. UI/UX & Responsiveness
- [ ] Responsive layout (web, mobile, tablet)
- [ ] Consistent theming (light/dark mode)
- [ ] Loading indicators and feedback
- [ ] Error messages and edge cases
- [ ] Accessibility (labels, contrast, keyboard navigation)

## 11. General
- [ ] CORS/network errors handled gracefully
- [ ] App shell loads without errors
- [ ] No debug prints or console errors in production
- [ ] Performance (app loads quickly, no jank) 