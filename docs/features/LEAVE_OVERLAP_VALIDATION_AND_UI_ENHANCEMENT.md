# Leave Overlap Validation and UI Enhancement

## Overview
This document describes two new features added to the SNS Rooster app:

1. **Backend prevention of overlapping leave requests**
2. **Frontend UI enhancement: '?' icon for leave type legend in the leave calendar**

---

## 1. Backend: Prevent Overlapping Leave Requests

### Description
When an employee submits a new leave request, the backend now checks for any existing leave (with status 'Pending' or 'Approved') that overlaps with the requested dates. If an overlap is found, the request is rejected.

### Behavior
- **If there is an overlap:**
  - The API responds with HTTP 400 and a message: `You already have a leave request that overlaps with these dates.`
- **If there is no overlap:**
  - The leave request is processed as usual.

### Example
```
POST /api/leave/apply
{
  "employeeId": "...",
  "leaveType": "Annual Leave",
  "startDate": "2025-06-25",
  "endDate": "2025-06-27",
  ...
}
```
- If the employee already has a leave (Pending/Approved) covering any of these dates, the request will be rejected.

---

## 2. Frontend: '?' Icon for Leave Type Legend

### Description
The leave calendar now features a small question mark (`?`) icon next to the "Leave Calendar" title. When tapped, a dialog appears showing the color legend for each leave type. This replaces the always-visible legend, making the UI cleaner and more user-friendly.

### Behavior
- The legend is hidden by default.
- Tapping the `?` icon opens a dialog with the leave type color legend.
- The calendar displays colored dots for each leave type on the relevant dates.

### Example UI
- See the "Leave Calendar" section in the app for the new icon and dialog.

---

## Screenshots
(Add screenshots here if desired)

---

## Commit Message
```
feat: prevent overlapping leave requests in backend and add '?' legend dialog to leave calendar UI

- Backend: Rejects new leave requests that overlap with existing pending/approved leaves for the same employee
- Frontend: Adds a '?' icon to the leave calendar for showing the leave type legend in a dialog, removes always-visible legend
```

## See Also

- [FEATURES_AND_WORKFLOW.md](FEATURES_AND_WORKFLOW.md) – Payroll, payslip, and workflow documentation
- [LAYOUT_FIX_DOCUMENTATION.md](LAYOUT_FIX_DOCUMENTATION.md) – UI layout fixes and dashboard/profile sync 