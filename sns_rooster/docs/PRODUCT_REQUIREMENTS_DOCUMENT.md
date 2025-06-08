# SNS Rooster - Product Requirements Document (PRD)

## 1. Project Overview
SNS Rooster is an employee management and attendance tracking system designed to streamline organizational workforce management. It provides secure user authentication, role-based access control, real-time attendance tracking, and employee profile management. The system targets both administrators and employees with tailored dashboards and functionalities.

## 2. Technology Stack
- **Backend:** Node.js, Express.js, MongoDB (MERN stack backend)
- **Frontend:** Flutter (cross-platform mobile app)
- **State Management:** Provider package in Flutter
- **Authentication:** JWT tokens with role-based access control
- **Database:** MongoDB with Mongoose ODM
- **API Communication:** RESTful APIs secured with JWT and CORS

## 3. Folder and File Structure

### Backend (`rooster-backend/`)
```
rooster-backend/
├── config/                 # Database connection setup
├── middleware/             # Express middleware (auth, error handling)
├── models/                 # Mongoose schemas (User.js, Attendance.js)
├── routes/                 # API route handlers (authRoutes.js, attendanceRoutes.js)
├── scripts/                # Utility scripts (e.g., create-admin.js)
└── server.js               # Express app entry point
```

### Frontend (`sns_rooster/`)
```
sns_rooster/
├── lib/
│   ├── main.dart                   # Flutter app entry point
│   ├── providers/                  # State management providers (auth, attendance, profile)
│   ├── screens/                    # UI screens organized by feature and role
│   │   ├── splash/
│   │   ├── login/
│   │   ├── admin/
│   │   └── employee/
│   ├── models/                     # Data models (user.dart, attendance.dart)
│   └── widgets/                    # Reusable UI components
├── assets/                        # Static assets (images, fonts)
├── android/, ios/, web/           # Platform-specific Flutter code
├── pubspec.yaml                   # Flutter dependencies and assets config
└── docs/                         # Documentation files
```

## 4. Backend and Frontend Connection
- The backend exposes RESTful API endpoints under `/api/auth` and `/api/attendance`.
- The frontend Flutter app communicates with the backend via HTTP requests using the `http` package.
- Authentication is handled by sending login credentials to `/api/auth/login`, receiving a JWT token, and storing it locally using `SharedPreferences`.
- Subsequent API requests include the JWT token in the `Authorization` header for protected routes.
- Role-based navigation is implemented on the frontend to direct users to admin or employee dashboards based on their role in the JWT payload.

## 5. Key Backend Functions and APIs

### Authentication (`routes/authRoutes.js`)
- `POST /api/auth/login`: User login, returns JWT token and user profile.
- `POST /api/auth/register`: Admin-only user registration.
- `POST /api/auth/reset-password`: Request password reset (token generation).
- `POST /api/auth/reset-password/:token`: Reset password using token.
- `GET /api/auth/me`: Get current user profile (token verification).
- `GET /api/auth/users`: Admin/manager get users list.
- `PATCH /api/auth/users/:id`: Update user profile (admin or self).
- `DELETE /api/auth/users/:id`: Admin-only user deletion.

### Attendance (`routes/attendanceRoutes.js`)
- `POST /api/attendance/check-in`: User check-in for the day.
- `PATCH /api/attendance/check-out`: User check-out.
- `POST /api/attendance/start-break`: Start break during work.
- `PATCH /api/attendance/end-break`: End break.
- `GET /api/attendance/user/:userId`: Admin/manager get attendance for a user.
- `GET /api/attendance/`: Admin get all attendance records.

## 6. Frontend State Management and Screens

### Providers
- **AuthProvider:** Manages authentication state, login/logout, token storage, and user info.
- **AttendanceProvider:** Manages attendance state and API calls for check-in/out and breaks.
- **ProfileProvider:** Manages user profile data.

### Screens
- **SplashScreen:** Initial loading and auth status check.
- **LoginScreen:** User login and password reset UI.
- **EmployeeDashboardScreen:** Dashboard for employees.
- **AdminDashboardScreen:** Dashboard for admins.
- **ProfileScreen:** User profile management.
- **AttendanceScreen:** Attendance overview for employees.
- **AttendanceManagementScreen:** Admin interface for attendance management.
- **UserManagementScreen:** Admin interface for user management.
- Additional screens for timesheet, leave requests, notifications.

## 7. Rules and Conventions for AI Understanding
- **Naming:** Files and folders are named by feature and role for clarity.
- **API Prefixes:** Backend APIs are grouped under `/api/auth` and `/api/attendance`.
- **Role-based Access:** Roles are 'admin', 'manager', and 'employee' with different permissions.
- **State Management:** Flutter uses Provider pattern with ChangeNotifier.
- **Token Handling:** JWT tokens stored securely in SharedPreferences and included in API headers.
- **Error Handling:** Backend uses middleware for error responses; frontend shows error messages via UI.
- **Code Modularity:** Backend separates concerns into middleware, routes, models, and utils.
- **Frontend UI:** Screens are organized by user roles and features for maintainability.

## 8. Functions Needing Attention
- Password reset email sending is marked TODO in backend (`authRoutes.js`).
- Ensure secure storage and handling of JWT tokens on frontend.
- Validate all user inputs on both frontend and backend.
- Add comprehensive tests for backend routes and frontend providers.

## 9. How to Run and Develop
- Backend: `npm install` and `npm run dev` in `rooster-backend/`.
- Frontend: `flutter pub get` and `flutter run` in `sns_rooster/`.
- Configure environment variables for MongoDB URI and JWT secret.
- API base URL is configured in `auth_provider.dart`.

---

This document provides a clear, structured overview of the SNS Rooster project, enabling AI agents and developers to understand the architecture, tech stack, file organization, and key functionalities.
