# API Contract for SNS Rooster Frontend

This document defines the API endpoints, request/response shapes, and error cases for the SNS Rooster frontend (admin and employee flows). Use this contract to build mock services and later connect to the real backend.

## Authentication

### Login (POST /api/auth/login)
- **Request Body:**
  ```json
  { "email": "user@example.com", "password": "your_password" }
  ```
- **Response (200 OK):**
  ```json
  { "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "user": { "_id": "user_id", "name": "User Name", "email": "user@example.com", "role": "admin", "isProfileComplete": true, ... } }
  ```
- **Error (401 Unauthorized):**
  ```json
  { "message": "Invalid email or password" }
  ```

### Logout (POST /api/auth/logout)
- **Request Headers:** Authorization: Bearer <token>
- **Response (200 OK):**
  ```json
  { "message": "Logged out successfully" }
  ```

## Admin Endpoints

### Get All Users (GET /api/users)
- **Request Headers:** Authorization: Bearer <token>
- **Response (200 OK):**
  ```json
  { "users": [ { "_id": "user_id", "name": "User Name", "email": "user@example.com", "role": "employee", "department": "IT", "position": "Developer", "isActive": true, "lastLogin": "2023-10-01T12:00:00Z", ... } ] }
  ```
- **Error (401 Unauthorized):**
  ```json
  { "message": "Unauthorized" }
  ```

### Create User (POST /api/auth/register)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body:**
  ```json
  { "name": "New User", "email": "newuser@example.com", "password": "new_password", "role": "employee", "department": "IT", "position": "Developer" }
  ```
- **Response (201 Created):**
  ```json
  { "message": "User created successfully", "user": { "_id": "new_user_id", "name": "New User", "email": "newuser@example.com", "role": "employee", "isProfileComplete": false, ... } }
  ```
- **Error (400 Bad Request):**
  ```json
  { "message": "Email already in use" }
  ```

### Update User (PATCH /api/users/:userId)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body (example):**
  ```json
  { "name": "Updated Name", "department": "HR", "isActive": true }
  ```
- **Response (200 OK):**
  ```json
  { "message": "User updated successfully", "user": { "_id": "user_id", "name": "Updated Name", "department": "HR", "isActive": true, ... } }
  ```
- **Error (404 Not Found):**
  ```json
  { "message": "User not found" }
  ```

### Delete User (DELETE /api/users/:userId)
- **Request Headers:** Authorization: Bearer <token>
- **Response (200 OK):**
  ```json
  { "message": "User deleted successfully" }
  ```
- **Error (404 Not Found):**
  ```json
  { "message": "User not found" }
  ```

## Employee Endpoints

### Get Profile (GET /api/me)
- **Request Headers:** Authorization: Bearer <token>
- **Response (200 OK):**
  ```json
  { "user": { "_id": "user_id", "name": "Employee Name", "email": "employee@example.com", "role": "employee", "department": "IT", "position": "Developer", "isProfileComplete": true, ... } }
  ```
- **Error (401 Unauthorized):**
  ```json
  { "message": "Unauthorized" }
  ```

### Update Profile (PATCH /api/me)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body (example):**
  ```json
  { "name": "Updated Employee Name", "department": "HR", "position": "Manager" }
  ```
- **Response (200 OK):**
  ```json
  { "message": "Profile updated successfully", "user": { "_id": "user_id", "name": "Updated Employee Name", "department": "HR", "position": "Manager", ... } }
  ```
- **Error (400 Bad Request):**
  ```json
  { "message": "Invalid input" }
  ```

### Attendance (POST /api/attendance/check-in)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body (optional):**
  ```json
  { "note": "Optional note" }
  ```
- **Response (200 OK):**
  ```json
  { "message": "Check-in recorded", "attendance": { "_id": "attendance_id", "userId": "user_id", "checkIn": "2023-10-01T09:00:00Z", ... } }
  ```
- **Error (400 Bad Request):**
  ```json
  { "message": "Already checked in" }
  ```

### Attendance (POST /api/attendance/check-out)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body (optional):**
  ```json
  { "note": "Optional note" }
  ```
- **Response (200 OK):**
  ```json
  { "message": "Check-out recorded", "attendance": { "_id": "attendance_id", "userId": "user_id", "checkIn": "2023-10-01T09:00:00Z", "checkOut": "2023-10-01T17:00:00Z", ... } }
  ```
- **Error (400 Bad Request):**
  ```json
  { "message": "Not checked in" }
  ```

### Leave Request (POST /api/leave-requests)
- **Request Headers:** Authorization: Bearer <token>
- **Request Body:**
  ```json
  { "leaveType": "annual", "startDate": "2023-10-01", "endDate": "2023-10-05", "reason": "Vacation" }
  ```
- **Response (201 Created):**
  ```json
  { "message": "Leave request submitted", "leaveRequest": { "_id": "leave_request_id", "userId": "user_id", "leaveType": "annual", "startDate": "2023-10-01", "endDate": "2023-10-05", "status": "pending", ... } }
  ```
- **Error (400 Bad Request):**
  ```json
  { "message": "Invalid leave request" }
  ```

### Get Leave Requests (GET /api/leave-requests)
- **Request Headers:** Authorization: Bearer <token>
- **Response (200 OK):**
  ```json
  { "leaveRequests": [ { "_id": "leave_request_id", "userId": "user_id", "leaveType": "annual", "startDate": "2023-10-01", "endDate": "2023-10-05", "status": "pending", ... } ] }
  ```
- **Error (401 Unauthorized):**
  ```json
  { "message": "Unauthorized" }
  ```

---

## Notes

- **Mock Data:** Use this contract to build mock services (e.g., in `sns_rooster/lib/services/mock_service.dart`) so that your frontend (admin and employee screens) can be fully built and tested without a backend.
- **Real API:** Once the frontend is complete, replace the mock calls with real HTTP calls (using `http` or `dio`).
- **Error Handling:** Always handle network errors, timeouts, and API error responses (e.g., 401, 404, 400) in your UI.

---

**Next Steps:**

- **Create a mock service (e.g., `MockAuthService`, `MockEmployeeService`) in your Flutter project.**
- **Build all admin and employee screens using the mock data.**
- **Review and demo the frontend (with mock data) before connecting to the backend.** 