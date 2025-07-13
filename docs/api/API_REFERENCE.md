# SNS Rooster API Reference

## Table of Contents
1. [Introduction](#introduction)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Models](#data-models)
    - [User](#user)
    - [Attendance Record](#attendance-record)
    - [Leave Request](#leave-request)
    - [Notification](#notification)
    - [Analytics](#analytics)
4. [API Endpoints](#api-endpoints)
    - [Authentication](#authentication-endpoints)
    - [Profile Management](#profile-management-endpoints)
    - [Employee Management](#employee-management-endpoints)
    - [Attendance](#attendance-endpoints)
    - [Admin Attendance](#admin-attendance-endpoints)
    - [Payroll](#payroll-endpoints)
5. [Model Relationships](#model-relationships)
6. [Status & Type Enums](#status--type-enums)
7. [Best Practices & Notes](#best-practices--notes)
8. [References](#references)
9. [Changelog](#changelog)

---

## Introduction

This document is the single source of truth for the SNS Rooster API.  
It covers data models, endpoints, authentication, and best practices for both frontend and backend developers.

---

## Authentication & Authorization

- **JWT-based authentication**: All protected endpoints require a valid JWT in the `Authorization` header.
- **Roles**: `admin`, `employee`, (optionally: `manager`, `super_admin`)
- **Role-based access control**: See endpoint tables for required roles.

**Example Auth Flow:**
1. User logs in via `/api/auth/login` and receives a JWT.
2. JWT is sent in the `Authorization: Bearer <token>` header for all subsequent requests.
3. Backend verifies JWT and role for each request.

---

## Data Models

### User

```json
{
  "_id": "string",
  "firstName": "string",
  "lastName": "string",
  "name": "string",
  "email": "string",
  "role": "employee | admin",
  "department": "string",
  "position": "string",
  "phone": "string",
  "address": "string",
  "emergencyContact": "string",
  "emergencyPhone": "string",
  "passport": "string",
  "education": [
    {
      "institution": "string",
      "degree": "string",
      "fieldOfStudy": "string",
      "startDate": "YYYY-MM-DD",
      "endDate": "YYYY-MM-DD",
      "certificate": "string"
    }
  ],
  "certificates": [
    {
      "name": "string",
      "file": "string"
    }
  ],
  "isActive": true,
  "isProfileComplete": true,
  "lastLogin": "2023-10-01T12:00:00Z",
  "avatar": "string"
}
```

---

### Attendance Record

```json
{
  "_id": "string",
  "userId": "string",
  "checkIn": "2023-10-01T09:00:00Z",
  "checkOut": "2023-10-01T18:00:00Z",
  "breaks": [
    {
      "startTime": "2023-10-01T12:30:00Z",
      "endTime": "2023-10-01T13:00:00Z"
    }
  ],
  "totalBreakDuration": 1800000,
  "status": "Present | Absent | Leave"
}
```

---

### Leave Request

```json
{
  "_id": "string",
  "userId": "string",
  "leaveType": "annual | sick | casual | ...",
  "startDate": "2023-10-10",
  "endDate": "2023-10-12",
  "status": "pending | approved | rejected",
  "reason": "string"
}
```

---

### Notification

```json
{
  "_id": "string",
  "userId": "string",
  "title": "string",
  "body": "string",
  "type": "info | alert | reminder | ...",
  "createdAt": "2023-10-01T12:00:00Z",
  "read": false
}
```

---

### Analytics

- **Work Hours Trend:**  
  Input: List of attendance records  
  Output: Array of `{ date: "YYYY-MM-DD", workHours: float }`
- **Attendance Breakdown:**  
  Output: `{ present: int, absent: int, leave: int }`
- **Leave Types Breakdown:**  
  Output: `{ annual: int, sick: int, casual: int, ... }`
- **Stat Cards/Highlights:**  
  Longest streak, most productive day, average check-in time, etc.

---

## API Endpoints

### Authentication Endpoints (`/api/auth`)

| Method  | Endpoint                 | Description                                 | Auth | Role          |
| ------- | ------------------------ | ------------------------------------------- | ---- | -------------|
| POST    | `/login`                 | Authenticates a user and returns a JWT.     | No   | -             |
| POST    | `/register`              | Registers a new user.                       | JWT  | Admin         |
| POST    | `/reset-password`        | Initiates password reset process.           | No   | -             |
| POST    | `/reset-password/:token` | Resets password using a token.              | No   | -             |
| GET     | `/me`                    | Retrieves the authenticated user's profile. | JWT  | Authenticated |
| PATCH   | `/me`                    | Updates the authenticated user's profile.   | JWT  | Authenticated |

---

### Profile Management Endpoints

- **PATCH** `/auth/me`  
  Update user profile information.  
  Fields: `firstName`, `lastName`, `name`, `email`, `phone`, `address`, `emergencyContact`, `emergencyPhone`

- **GET** `/auth/me`  
  Retrieve current user's profile information.

---

### Employee Management Endpoints (`/api/employees`)

| Method   | Endpoint     | Description                        | Auth | Role                |
| -------- | ------------ | ---------------------------------- | ---- | --------------------|
| GET      | `/`          | Retrieves all employees.           | JWT  | Admin, Manager       |
| GET      | `/:id`       | Retrieves a single employee by ID. | JWT  | Admin, Manager, Self |
| POST     | `/`          | Creates a new employee.            | JWT  | Admin                |
| PUT      | `/:id`       | Updates an employee's details.     | JWT  | Admin, Manager, Self |
| DELETE   | `/:id`       | Deletes an employee.               | JWT  | Admin                |
| GET      | `/dashboard` | Retrieves employee dashboard data. | JWT  | Authenticated        |

---

### Attendance Endpoints (`/api/attendance`)

| Method  | Endpoint          | Description                                            | Auth | Role          |
| ------- | ----------------- | ------------------------------------------------------| ---- | -------------|
| POST    | `/check-in`       | Records user's daily check-in.                        | JWT  | Authenticated |
| PATCH   | `/check-out`      | Records user's daily check-out.                       | JWT  | Authenticated |
| POST    | `/start-break`    | Records the start of a user's break.                  | JWT  | Authenticated |
| PATCH   | `/end-break`      | Records the end of a user's break.                    | JWT  | Authenticated |
| GET     | `/my-attendance`  | Retrieves the authenticated user's attendance records.| JWT  | Authenticated |
| GET     | `/status/:userId` | Retrieves attendance status for a user.               | JWT  | Authenticated |

---

### Admin Attendance Endpoints (`/api/admin/attendance`)

| Method | Endpoint                      | Description                               | Auth | Role  |
| ------ | ----------------------------- | ----------------------------------------- | ---- | ------|
| POST   | `/admin/start-break/:userId`  | Admin starts a break for a specific user. | JWT  | Admin |
| POST   | `/admin/end-break/:userId`    | Admin ends a break for a specific user.   | JWT  | Admin |
| GET    | `/break-types`                | Retrieves available break types.          | JWT  | Authenticated |
| GET    | `/admin/break-status/:userId` | Admin retrieves break status for a user.  | JWT  | Admin |

---

### Payroll Endpoints (`/api/payroll`)

| Method | Endpoint                | Description                                        | Auth | Role  |
| ------ | ----------------------- | --------------------------------------------------| ---- | ------|
| GET    | `/`                     | Retrieves all payroll records.                     | JWT  | Admin |
| GET    | `/employee/:employeeId` | Retrieves payroll records for a specific employee. | JWT  | Admin, Employee |
| POST   | `/`                     | Creates a new payroll record.                      | JWT  | Admin |

---

## Model Relationships

- **User** has many **Attendance Records**
- **User** has many **Leave Requests**
- **User** has many **Notifications**

---

## Status & Type Enums

- **User.role:** `employee`, `admin`
- **Attendance.status:** `Present`, `Absent`, `Leave`
- **Leave.status:** `pending`, `approved`, `rejected`
- **Notification.type:** `info`, `alert`, `reminder`, etc.
- **Leave.leaveType:** `annual`, `sick`, `casual`, etc.

---

## Best Practices & Notes

- All timestamps use ISO8601 format (UTC recommended).
- Use enums/strings for status/type fields for flexibility.
- Add fields as needed for future features (e.g., device info, geo-location).
- For analytics, aggregate data on the backend or frontend as needed.
- Error responses follow standard JSON error format.

---

## References

- [Features and Workflow](../features/FEATURES_AND_WORKFLOW.md)
- [Security and Access Control](../security/SECURITY_ACCESS_CONTROL_DOCUMENTATION.md)
- [Network Troubleshooting](../NETWORK_TROUBLESHOOTING.md)

---

## Changelog

- **2024-12-16:** Initial merge of API contract and documentation.

--- 