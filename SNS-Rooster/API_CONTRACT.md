# SNS Rooster API & Data Model Contract

This document defines the data models and API contract for the SNS Rooster Employee Management System. It is intended to guide both frontend and backend development, ensuring consistency and smooth integration.

---

## 1. User
```json
{
  "_id": "string",                // Unique user ID
  "name": "string",               // Full name
  "email": "string",              // Email address (unique)
  "role": "employee | admin",     // User role
  "department": "string",         // Department name
  "position": "string",           // Job title/position
  "isActive": true,                // Is the user active?
  "isProfileComplete": true,       // Has the user completed their profile?
  "lastLogin": "2023-10-01T12:00:00Z", // Last login (ISO8601)
  "avatar": "assets/images/profile_placeholder.png" // Avatar URL or asset path
}
```

---

## 2. Attendance Record
```json
{
  "_id": "string",                // Unique attendance record ID
  "userId": "string",             // Reference to User
  "checkIn": "2023-10-01T09:00:00Z",   // Check-in time (ISO8601)
  "checkOut": "2023-10-01T18:00:00Z",  // Check-out time (ISO8601 or null)
  "breaks": [                      // List of breaks taken
    {
      "startTime": "2023-10-01T12:30:00Z",
      "endTime": "2023-10-01T13:00:00Z"
    }
  ],
  "totalBreakDuration": 1800000,   // Total break duration (ms)
  "status": "Present | Absent | Leave" // Attendance status
}
```

---

## 3. Leave Request
```json
{
  "_id": "string",                // Unique leave request ID
  "userId": "string",             // Reference to User
  "leaveType": "annual | sick | casual | ...", // Type of leave
  "startDate": "2023-10-10",      // Start date (YYYY-MM-DD)
  "endDate": "2023-10-12",        // End date (YYYY-MM-DD)
  "status": "pending | approved | rejected", // Approval status
  "reason": "string"               // Reason for leave
}
```

---

## 4. Notification (Future)
```json
{
  "_id": "string",                // Unique notification ID
  "userId": "string",             // Reference to User
  "title": "string",              // Notification title
  "body": "string",               // Notification message
  "type": "info | alert | reminder | ...", // Notification type
  "createdAt": "2023-10-01T12:00:00Z", // Timestamp (ISO8601)
  "read": false                    // Has the user read this notification?
}
```

---

## 5. Analytics (Frontend/Backend)
- **Work Hours Trend:**
  - Input: List of attendance records (see above)
  - Output: Array of { date: "YYYY-MM-DD", workHours: float }
- **Attendance Breakdown:**
  - Output: { present: int, absent: int, leave: int } for a given period
- **Leave Types Breakdown:**
  - Output: { annual: int, sick: int, casual: int, ... }
- **Stat Cards/Highlights:**
  - Longest streak, most productive day, average check-in time, etc.

---

## Relationships
- **User** has many **Attendance Records**
- **User** has many **Leave Requests**
- **User** has many **Notifications**

---

## Notes & Extensibility
- All timestamps use ISO8601 format (UTC recommended).
- Add fields as needed for future features (e.g., device info, geo-location, custom leave types).
- Use enums/strings for status/type fields for flexibility.
- For analytics, aggregate data on the backend or frontend as needed.

---

_Last updated: 2024-06-09_ 