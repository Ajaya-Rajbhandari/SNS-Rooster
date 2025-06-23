# API Documentation

This document outlines the REST API endpoints available in the SNS-Rooster-app backend.

## Authentication Routes (`/api/auth`)

| Method  | Endpoint                 | Description                                 | Authentication | Authorization |
| ------- | ------------------------ | ------------------------------------------- | -------------- | ------------- |
| `POST`  | `/login`                 | Authenticates a user and returns a JWT.     | None           | None          |
| `POST`  | `/register`              | Registers a new user.                       | JWT            | Admin         |
| `POST`  | `/reset-password`        | Initiates password reset process.           | None           | None          |
| `POST`  | `/reset-password/:token` | Resets password using a token.              | None           | None          |
| `GET`   | `/me`                    | Retrieves the authenticated user's profile. | JWT            | Authenticated |
| `PATCH` | `/me`                    | Updates the authenticated user's profile.   | JWT            | Authenticated |

## Employee Routes (`/api/employees`)

| Method   | Endpoint     | Description                        | Authentication | Authorization        |
| -------- | ------------ | ---------------------------------- | -------------- | -------------------- |
| `GET`    | `/`          | Retrieves all employees.           | JWT            | Admin, Manager       |
| `GET`    | `/:id`       | Retrieves a single employee by ID. | JWT            | Admin, Manager, Self |
| `POST`   | `/`          | Creates a new employee.            | JWT            | Admin                |
| `PUT`    | `/:id`       | Updates an employee's details.     | JWT            | Admin, Manager, Self |
| `DELETE` | `/:id`       | Deletes an employee.               | JWT            | Admin                |
| `GET`    | `/dashboard` | Retrieves employee dashboard data. | JWT            | Authenticated        |

## Attendance Routes (`/api/attendance`)

| Method  | Endpoint          | Description                                            | Authentication | Authorization |
| ------- | ----------------- | ------------------------------------------------------ | -------------- | ------------- |
| `POST`  | `/check-in`       | Records user's daily check-in.                         | JWT            | Authenticated |
| `PATCH` | `/check-out`      | Records user's daily check-out.                        | JWT            | Authenticated |
| `POST`  | `/start-break`    | Records the start of a user's break.                   | JWT            | Authenticated |
| `PATCH` | `/end-break`      | Records the end of a user's break.                     | JWT            | Authenticated |
| `GET`   | `/my-attendance`  | Retrieves the authenticated user's attendance records. | JWT            | Authenticated |
| `GET`   | `/status/:userId` | Retrieves attendance status for a user.                | JWT            | Authenticated |

## Admin Attendance Routes (`/api/admin/attendance`)

| Method | Endpoint                      | Description                               | Authentication | Authorization |
| ------ | ----------------------------- | ----------------------------------------- | -------------- | ------------- |
| `POST` | `/admin/start-break/:userId`  | Admin starts a break for a specific user. | JWT            | Admin         |
| `POST` | `/admin/end-break/:userId`    | Admin ends a break for a specific user.   | JWT            | Admin         |
| `GET`  | `/break-types`                | Retrieves available break types.          | JWT            | Authenticated |
| `GET`  | `/admin/break-status/:userId` | Admin retrieves break status for a user.  | JWT            | Admin         |

## Payroll Routes (`/api/payroll`)

| Method | Endpoint                | Description                                        | Authentication | Authorization |
| ------ | ----------------------- | -------------------------------------------------- | -------------- | ------------- |
| `GET`  | `/`                     | Retrieves all payroll records.                     | None           | None          |
| `GET`  | `/employee/:employeeId` | Retrieves payroll records for a specific employee. | None           | None          |
| `POST` | `/`                     | Creates a new payroll record.                      | None           | None          |
