# SNS Rooster API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "user": {
      "_id": "user_id",
      "email": "user@example.com",
      "name": "John Doe",
      "role": "employee",
      "department": "IT"
    }
  }
}
```

### Register (Admin Only)
```http
POST /auth/register
Content-Type: application/json
Authorization: Bearer <admin_token>

{
  "email": "newuser@example.com",
  "password": "password123",
  "name": "New User",
  "role": "employee",
  "department": "IT",
  "position": "Developer"
}
```

### Get Current User
```http
GET /auth/me
Authorization: Bearer <token>
```

## Attendance

### Check In
```http
POST /attendance/check-in
Authorization: Bearer <token>
```

### Check Out
```http
POST /attendance/check-out
Authorization: Bearer <token>
```

### Get Attendance History
```http
GET /attendance/history
Authorization: Bearer <token>
Query Parameters:
  - startDate: YYYY-MM-DD
  - endDate: YYYY-MM-DD
```

## Leave Management

### Submit Leave Request
```http
POST /leave/request
Authorization: Bearer <token>
Content-Type: application/json

{
  "leaveType": "annual",
  "startDate": "2024-03-01",
  "endDate": "2024-03-05",
  "reason": "Family vacation"
}
```

### Get Leave History
```http
GET /leave/history
Authorization: Bearer <token>
```

### Approve/Reject Leave Request (Admin Only)
```http
PUT /leave/:id/approve
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "status": "approved",
  "comments": "Approved"
}
```

## Profile Management

### Get Profile
```http
GET /profile
Authorization: Bearer <token>
```

### Update Profile
```http
PUT /profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Name",
  "department": "New Department",
  "position": "New Position"
}
```

### Update Profile Picture
```http
POST /profile/picture
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "picture": <file>
}
```

## Error Responses

### Authentication Error
```json
{
  "success": false,
  "error": "Authentication failed"
}
```

### Validation Error
```json
{
  "success": false,
  "error": "Validation failed",
  "details": {
    "field": "error message"
  }
}
```

### Server Error
```json
{
  "success": false,
  "error": "Internal server error"
}
```

## Rate Limiting
- 100 requests per minute per IP
- 1000 requests per hour per user

## Authentication
- All protected endpoints require a valid JWT token
- Token should be included in the Authorization header
- Token format: `Bearer <token>`

## Response Format
All responses follow this format:
```json
{
  "success": boolean,
  "data": object | null,
  "error": string | null
}
```

## Status Codes
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 429: Too Many Requests
- 500: Internal Server Error 