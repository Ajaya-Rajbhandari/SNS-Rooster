# SNS-Rooster HR Mobile App Documentation

This document provides a comprehensive overview of the SNS-Rooster HR mobile application, covering its purpose, technical details, and deployment instructions. It is intended for developers who will be working on this project.

## 1. Project Overview

SNS-Rooster is a mobile application designed to serve as a Human Resources (HR) management system for both employees and administrators. It streamlines various HR processes, making them accessible and efficient.

### Key Features:

-   **Clock In/Out:** Employees can easily record their attendance.
-   **Break Tracking:** Track and manage break times during shifts.
-   **Leave Requests:** Employees can submit and track leave applications (e.g., annual, sick, casual, maternity, paternity leave).
-   **Timesheet Logs:** Maintain detailed records of working hours.
-   **Admin Dashboard:** Administrators have a centralized interface to manage employee data, approve leave requests, and oversee other HR functions.

## 2. Project Structure

The project follows a standard Flutter application structure. The core application logic and UI components are located within the `lib` directory.

### Main Files in `lib`:

-   <mcfile name="main.dart" path="lib/main.dart"></mcfile>: The entry point of the Flutter application. It initializes the app and defines the root widget.
-   <mcfile name="splash_screen.dart" path="lib/splash_screen.dart"></mcfile>: Handles the initial loading screen and any necessary app initialization before navigating to the main content.
-   <mcfile name="login_screen.dart" path="lib/login_screen.dart"></mcfile>: Manages user authentication and login processes.
-   <mcfile name="employee_dashboard_screen.dart" path="lib/employee_dashboard_screen.dart"></mcfile>: The main dashboard for employees, providing access to features like clock in/out, timesheets, and leave requests.
-   <mcfile name="admin_dashboard_screen.dart" path="lib/admin_dashboard_screen.dart"></mcfile>: The main dashboard for administrators, offering tools for managing employees, leave approvals, and other administrative tasks.
-   <mcfile name="leave_request_screen.dart" path="lib/leave_request_screen.dart"></mcfile>: Handles the submission and tracking of leave requests for employees.
-   <mcfile name="config/leave_config.dart" path="lib/config/leave_config.dart"></mcfile>: Contains configuration related to leave management, such as total and used leave days for different leave types.

### Folder Structure:

-   <mcfolder name="assets/" path="assets/"></mcfolder>: Contains all static assets used in the application.
    -   <mcfolder name="images/" path="assets/images/"></mcfolder>: Stores image assets like `google_logo.png` and `logo.png`.
    -   <mcfolder name="fonts/" path="assets/fonts/"></mcfolder>: Contains custom font files, including various weights and styles of OpenSans and ProductSans (e.g., `OpenSans-Bold.ttf`, `OpenSans-Regular.ttf`, `ProductSans-Bold.ttf`, `ProductSans-Italic.ttf`, `ProductSans-Regular.ttf`).

## 3. Flutter and Dart Info

### Required Versions:

-   **Flutter SDK:** `^3.8.1`
-   **Dart SDK:** Compatible with Flutter `^3.8.1` (typically `^3.0.0` or higher)

### Key Dependencies (from `pubspec.yaml`):

-   `cupertino_icons: ^1.0.8`: A set of iOS-style icons for Flutter applications.
-   `flutter_lints: ^5.0.0`: Provides a recommended set of lints for Flutter projects to encourage good coding practices.

*(Note: Firebase dependencies like `firebase_core`, `cloud_firestore`, `firebase_auth`, and `firebase_storage` are expected to be added as the project progresses, but are not currently listed in the provided `pubspec.yaml`.)*

## 4. Firebase Setup

This application is designed to integrate with Firebase for backend services. The following Firebase services are expected to be used:

-   **Firebase Authentication (Firebase Auth):** For user login and registration.
-   **Cloud Firestore:** A NoSQL document database for storing application data (e.g., employee details, leave requests, timesheets).
-   **Firebase Storage:** For storing user-generated content or other files (e.g., profile pictures, document uploads).

### Steps to Configure Firebase for Android/iOS:

1.  **Create a Firebase Project:** Go to the Firebase Console and create a new project.
2.  **Register Your App:**
    -   **Android:** Add an Android app to your Firebase project. Provide your Android package name (e.g., `com.example.snsrooster`) and download the `google-services.json` file. Place this file in the `android/app/` directory of your Flutter project.
    -   **iOS:** Add an iOS app to your Firebase project. Provide your iOS bundle ID (e.g., `com.example.snsRooster`) and download the `GoogleService-Info.plist` file. Place this file in the `ios/Runner/` directory of your Flutter project.
3.  **Add Firebase SDKs:** Add the necessary Firebase dependencies to your `pubspec.yaml` file (e.g., `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`).
4.  **Initialize Firebase:** Ensure Firebase is initialized in your `main.dart` file, typically within the `main()` function, before `runApp()` is called.

## 5. Navigation

The application uses Flutter's built-in `Navigator` for route management.

### Initial Routes and Screen Flow:

-   The application starts with the <mcfile name="splash_screen.dart" path="lib/splash_screen.dart"></mcfile>.
-   After the splash screen, it typically navigates to the <mcfile name="login_screen.dart" path="lib/login_screen.dart"></mcfile>.
-   Upon successful login, users are directed to either the <mcfile name="employee_dashboard_screen.dart" path="lib/employee_dashboard_screen.dart"></mcfile> or <mcfile name="admin_dashboard_screen.dart" path="lib/admin_dashboard_screen.dart"></mcfile> based on their role.
-   Navigation between different features (e.g., from dashboard to leave request screen) is handled using `Navigator.push()` and `Navigator.pop()`.

## 6. UI Design System

### Fonts Used:

-   **OpenSans:** Used for general body text and readability.
-   **ProductSans:** Used for headings and prominent text elements to give a distinct visual identity.

### Icons and Visual Design Approach:

-   The application adheres to **Material 3** design guidelines, providing a modern and consistent user interface.
-   Icons are primarily sourced from `cupertino_icons` and Material Design Icons.

### Widget Structure and Layout Tips:

-   The UI is built using Flutter's declarative widget tree.
-   Common layout widgets like `Column`, `Row`, `Padding`, `SizedBox`, `Expanded`, and `Card` are extensively used for structuring content.
-   Theming is applied using `Theme.of(context)` to ensure consistent styling across the app.

## 7. Deployment

### How to Build and Run the App:

1.  **Prerequisites:** Ensure you have Flutter SDK installed and configured.
2.  **Get Dependencies:** Navigate to the project root (`sns_rooster/`) in your terminal and run:
    ```bash
    flutter pub get
    ```
3.  **Run on Android Emulator/Device:**
    ```bash
    flutter run
    ```
4.  **Run on iOS Simulator/Device:**
    ```bash
    flutter run
    ```
    *(Note: For iOS, you might need to configure Xcode and sign your app.)*

### How to Build Release APK/IPA:

-   **Android APK:**
    ```bash
    flutter build apk --release
    ```
    The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`.
-   **iOS IPA:**
    ```bash
    flutter build ipa --release
    ```
    The IPA will be generated in `build/ios/archive/Runner.xcarchive`.

### Linking Firebase:

-   Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed as described in the Firebase Setup section.
-   Verify that Firebase initialization code is present and correct in `main.dart`.

## 8. Known Issues / To Do

-   **Firebase Integration:** Full integration with Firebase Auth, Firestore, and Storage is pending.
-   **Admin Functionality:** The admin dashboard requires further development to implement all management features.
-   **Error Handling:** Implement robust error handling and user feedback mechanisms for network requests and form submissions.
-   **Testing:** Comprehensive unit and integration tests need to be written.
-   **UI/UX Enhancements:** Further polish and refine the user interface for a smoother experience.
-   **Leave Request Approval Workflow:** Implement the backend logic for administrators to approve or reject leave requests.
-   **Notifications:** Add push notifications for leave request status updates and other important alerts.
