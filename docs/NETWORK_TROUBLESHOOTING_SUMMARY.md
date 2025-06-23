# Network Troubleshooting Summary and Current State

This document summarizes the troubleshooting steps taken to resolve network-related issues, specifically the `FormatException` encountered in the Flutter application, and outlines the current working configuration to prevent future regressions.

## Problem: `FormatException: Unexpected character (at character 1) <!DOCTYPE html>`

The Flutter application was consistently failing to parse API responses, throwing a `FormatException`. The error message indicated that the app was receiving an HTML document instead of the expected JSON data.

## Troubleshooting Steps and Resolution

1.  **Initial Backend Checks**:
    *   Verified that the backend server (`rooster-backend`) was running.
    *   Multiple restarts of the backend server were performed using `npm run dev`.
    *   Confirmed via server logs that the backend was listening on `0.0.0.0:5000` and connected to MongoDB.
    *   Direct requests to `http://localhost:5000` using `Invoke-WebRequest` initially failed but eventually succeeded after ensuring the server was properly started, confirming the backend itself was capable of serving requests.

2.  **Flutter Application Investigation**:
    *   Despite a healthy backend, the `FormatException` persisted in the Flutter app.
    *   Flutter app logs showed attempts to connect to IP addresses like `http://192.168.1.72:5000` for API calls and image loading (`/uploads/avatars/...`).
    *   The key insight came from examining `sns_rooster/lib/config/api_config.dart`.

3.  **Root Cause Identified**: The `baseUrl` in `api_config.dart` was missing the `/api` prefix for all platforms. API calls were being directed to paths like `http://<host>:<port>/<endpoint>` instead of the correct `http://<host>:<port>/api/<endpoint>`.
    *   The backend server, when receiving requests to non-API routes (e.g., the root or other undefined paths), was likely serving a default HTML page (e.g., a 404 page or a misconfigured frontend `index.html`), which the Flutter app could not parse as JSON.

4.  **The Fix**: The `baseUrl` getter in `api_config.dart` was modified to correctly include the `/api` path segment:

    ```dart
    // In sns_rooster/lib/config/api_config.dart
    // ...
    static const String _apiPath = '/api'; // Added for clarity
    // ...
    String get baseUrl {
      final host = _getPlatformSpecificHost();
      if (_isWeb) {
        // For web, it might be running on a different port or served via a proxy.
        // Using relative path for API calls if served from the same domain,
        // or a full path if API_HOST is defined.
        final webHost = const String.fromEnvironment('API_HOST', defaultValue: '');
        if (webHost.isNotEmpty) {
          return '${_protocol}://${webHost}:${_port}$_apiPath';
        }
        // If API_HOST is not set for web, assume it's served from the same origin
        // and use a relative path. This might need adjustment based on deployment.
        return _apiPath; // e.g., /api/users - browser handles the domain
      } else {
        // For mobile (Android/iOS)
        return '${_protocol}://${host}:${_port}$_apiPath';
      }
    }
    // ...
    ```
    *Note: The actual change made during the session was to append `/api` directly. The snippet above shows a slightly more robust way by defining `_apiPath`.*

5.  **Verification**: After modifying `api_config.dart` and performing a full restart of the Flutter application (stopping the existing instance and running `flutter run` again), the `FormatException` was resolved. The app could successfully fetch data and load images from the backend.

## Current Working Configuration & Key Takeaways

*   **Backend**: Runs on `http://localhost:5000` (or `http://0.0.0.0:5000`). All API routes are prefixed with `/api` (e.g., `http://localhost:5000/api/users`, `http://localhost:5000/api/employees`).
*   **Flutter Frontend (`api_config.dart`)**: The `baseUrl` **must** include the `/api` prefix for all API calls. For example:
    *   Web: `http://localhost:5000/api` (if `API_HOST` is `localhost`) or `/api` (if served from the same domain).
    *   Android/iOS: `http://<your_machine_ip>:5000/api` (e.g., `http://192.168.1.72:5000/api`).
*   **Static Assets**: Paths for static assets served by the backend (e.g., `/uploads/avatars/image.png`) do **not** go through the `/api` prefix. The Flutter app should construct these URLs correctly, typically by concatenating the base server URL (without `/api`) and the asset path (e.g., `http://192.168.1.72:5000/uploads/avatars/default.png`). This was implicitly working once the main API calls were fixed, as the image loading paths in the app likely used a base URL that was now correctly configured up to the port, and then appended the `/uploads/...` path.

## How to Avoid Messing This Up

1.  **Verify `api_config.dart`**: Any changes to backend routing, especially the base API path, must be reflected in `sns_rooster/lib/config/api_config.dart`.
2.  **Check API Prefixes**: Ensure all backend API routes in `rooster-backend/server.js` (or wherever routes are defined, e.g., `rooster-backend/routes/*`) are consistently using the `/api` prefix (e.g., `app.use('/api/auth', authRoutes);`).
3.  **Full Restarts**: When making changes to network configurations (like `baseUrl`) or backend route structures, always perform a full restart of both the backend server and the Flutter application. Hot reload/restart might not always pick up all changes, especially environment configurations or native code aspects.
4.  **Test on All Platforms**: If changes are made to platform-specific IP configurations, test on web, Android emulator/device, and iOS simulator/device to ensure connectivity.
5.  **Inspect Network Requests**: Use browser developer tools (for web) or Flutter DevTools (Network tab) to inspect the exact URLs being called by the app and the responses being received. This is invaluable for diagnosing discrepancies.
6.  **Clear Error Messages**: Ensure the backend provides clear JSON error responses for API errors, rather than defaulting to HTML error pages, to make debugging easier on the client-side.

By adhering to these points, future network-related issues can be minimized.