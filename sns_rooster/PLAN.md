# Integration Plan for Mock Services (SNS Rooster Frontend)

## Overview

We are integrating mock services (defined in `sns_rooster/lib/services/mock_service.dart`) into our frontend (admin and employee screens) so that we can build and test the UI without a backend. This "API-first" approach (using a flag "useMock") lets us simulate API responses (with a delay) and later swap in real HTTP calls (using "http" or "dio") once the frontend is complete.

## Steps

1. **Review API Contract (API_CONTRACT.md)**  
   - Ensure that our API endpoints (for auth, admin, employee, attendance, leave requests) are documented (with request/response shapes and error cases).  
   - This contract (or a similar OpenAPI/Swagger doc) is our "source of truth" for frontend–backend integration.

2. **Integrate Mock Services (mock_service.dart)**  
   - In our providers (or screens) (e.g., `AuthProvider`, `EmployeeProvider`, `AttendanceProvider`, etc.), import and instantiate the mock service classes (e.g., `MockAuthService`, `MockEmployeeService`, `MockAttendanceService`, `MockLeaveRequestService`).  
   - Use a flag (e.g., "useMock" (set to true)) so that our providers call the mock methods (which simulate a delay and return hardcoded JSON) instead of real API calls.  
   - For example, in `AuthProvider` (or a login screen), call `mockAuthService.login(email, password)` (which returns a mock token and user) so that the UI (and navigation) can be built and tested.

3. **Build (and Test) All Screens Using Mock Data**  
   - Complete all admin and employee screens (e.g., dashboard, employee management, leave requests, attendance, profile, etc.) using the mock data.  
   - Ensure that all user flows (e.g., login, logout, add/edit/delete employee, check-in/check-out, submit leave requests) "work" (i.e., update the UI as expected) with the mock responses.

4. **Demo (and Stakeholder Review)**  
   - Demo the full frontend (using mock data) to stakeholders (or your team) so that you can get feedback and sign-off on the UI/UX.  
   - This step ensures that the frontend is "done" (and that you're not drifting away from your backend contract).

5. **Switch to Real API Calls (or Remove Mock Layer)**  
   - Once the frontend is complete (and tested with mock data), update your providers (or services) so that "useMock" is false (or remove the mock layer entirely).  
   - Replace the mock calls (e.g., "throw UnimplementedError") with real HTTP calls (using "http" or "dio") (e.g., "POST /api/auth/login", "GET /api/users", etc.).  
   - (Optionally, you can use a dependency injection or a "service locator" (e.g., GetIt) so that you swap in a "real" service at runtime.)

6. **End-to-End (E2E) Testing & Polish**  
   - Test the full app (with the real backend) end-to-end.  
   - Fix any contract mismatches (or edge cases) and polish the UI/UX.

## Benefits

- **Faster UI Development:** You can build (and iterate) on the UI without waiting for (or switching to) the backend.
- **Clear Contract:** The API contract (or mock service) "documents" what the frontend expects (and what the backend must provide).
- **Easier Debugging:** Mock data is predictable (and you can "force" error cases) so that you can debug (or demo) the UI easily.
- **Less Context Switching:** Your team (or an AI agent) can focus on the frontend (or backend) without drift.

## Next Steps

- **Integrate (or Update) Providers:**  
  For example, in your `AuthProvider` (or a login screen), instantiate (or inject) a `MockAuthService` (and call its "login" method) so that you can test the login (and navigation) flow.  
  (Similarly, update your employee, attendance, and leave request providers (or screens) to use the corresponding mock services.)  
- **Build (or Update) Screens:**  
  Complete (or update) all admin and employee screens (using the mock data) so that the UI (and state) "work" as expected.  
- **Demo (and Review):**  
  Once the UI is "done" (with mock data), demo it (and get feedback) before connecting to the real backend. 