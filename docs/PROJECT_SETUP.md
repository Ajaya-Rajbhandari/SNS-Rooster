# SNS Rooster Project Setup Guide

## Table of Contents
1. Introduction
2. Prerequisites
3. Project Structure Overview
4. Quick Start
    - Backend Setup
    - Frontend Setup
5. Environment & Network Configuration
    - Switching Environments (Home/Office/Emulator/Device)
    - API URL Configuration
    - Automated Scripts & Tools
6. Database Setup
    - MongoDB Atlas/Local
    - Admin User Creation
7. Testing the Setup
    - Backend Health Check
    - Frontend Connection
    - Connectivity Scripts
8. Development Workflow
    - Hot Reload/Restart
    - Backend Auto-reload
    - Common Commands
9. Troubleshooting & Common Issues
    - Backend Issues
    - Frontend Issues
    - Network Issues
    - Device/Emulator Issues
10. Push Notifications Setup
    - Reference to FCM_SETUP_GUIDE.md
11. Support & Further Reading
    - Links to ENVIRONMENT_SWITCHING_GUIDE.md, FCM_SETUP_GUIDE.md, NETWORK_TROUBLESHOOTING.md, etc.

---

## 1. Introduction
Welcome to the SNS Rooster Project Setup Guide! This guide will help you set up the backend and frontend, configure your environment, and troubleshoot common issues. It is intended for developers new to the project or setting up on a new machine.

---

## 2. Prerequisites
- **Node.js** (v14 or higher)
- **MongoDB** (v4.4 or higher) or MongoDB Atlas account
- **Flutter** (v3.0 or higher)
- **Git**

---

## 3. Project Structure Overview
```
SNS-Rooster-app/
├── rooster-backend/          # Node.js backend API
├── sns_rooster/              # Flutter mobile app
└── docs/                     # Documentation
```

---

## 4. Quick Start

### Backend Setup
1. Navigate to backend directory:
   ```bash
   cd rooster-backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the backend server:
   ```bash
   npm run dev
   ```
   The server will start on `http://localhost:5000`.

### Frontend Setup
1. Navigate to Flutter directory:
   ```bash
   cd sns_rooster
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the Flutter app:
   ```bash
   flutter run
   ```

---

## 5. Environment & Network Configuration

### Switching Environments (Home/Office/Emulator/Device)
- Use the [ENVIRONMENT_SWITCHING_GUIDE.md](setup/ENVIRONMENT_SWITCHING_GUIDE.md) for scripts, environment variables, and manual methods.
- Update the API URL in your Flutter app depending on your network and device.
- For Android Emulator: `http://10.0.2.2:5000/api`
- For iOS Simulator/Web: `http://localhost:5000/api`
- For Physical Device: `http://[YOUR_IP]:5000/api`

### Automated Scripts & Tools
- Use `switch-environment.ps1` for quick IP switching.
- Use VS Code tasks or environment variables for team development.

---

## 6. Database Setup

- The project is configured to use MongoDB Atlas by default. The connection string is set in the `.env` file in `rooster-backend/`.
- To create an admin user, run:
  ```bash
  cd rooster-backend
  node scripts/create-admin.js
  ```

---

## 7. Testing the Setup

### Backend Health Check
- Visit `http://localhost:5000` in your browser. You should see:
  ```json
  {"message": "Welcome to SNS Rooster API"}
  ```

### Frontend Connection
- Launch the Flutter app and try to register or login.
- Check the backend console for API requests.

### Connectivity Scripts
- Use provided scripts like `test-backend.js`, `test-ip-connection.js`, and `test-emulator-connection.js` for network testing.

---

## 8. Development Workflow

- **Start Backend:** `npm run dev` in `rooster-backend/`
- **Start Frontend:** `flutter run` in `sns_rooster/`
- **Hot Reload:** Press `r` in Flutter terminal for hot reload
- **Backend Auto-reload:** Nodemon automatically restarts on file changes
- **Common Commands:**
  - `flutter clean && flutter pub get` (fixes build issues)
  - `npm install` (backend dependencies)

---

## 9. Troubleshooting & Common Issues

### Backend Issues
- **Port 5000 in use:** Change the PORT in `.env` file
- **MongoDB connection failed:** Check your internet connection and MongoDB Atlas credentials

### Frontend Issues
- **Network error:** Verify the API URL matches your setup
- **Build errors:** Run `flutter clean` then `flutter pub get`

### Network Issues
- **Physical device can't reach API:** Ensure both devices are on same WiFi network
- **Emulator connection issues:** Use the correct IP address for your platform

### Device/Emulator Issues
- **Restart the app** after changing network or API URL
- **Clear cache** if persistent issues

---

## 10. Push Notifications Setup
- See [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) for detailed Firebase Cloud Messaging setup and troubleshooting.

---

## 11. Support & Further Reading
- [ENVIRONMENT_SWITCHING_GUIDE.md](setup/ENVIRONMENT_SWITCHING_GUIDE.md)
- [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)
- [NETWORK_TROUBLESHOOTING.md](NETWORK_TROUBLESHOOTING.md)
- [PROJECT_ORGANIZATION_GUIDE.md](PROJECT_ORGANIZATION_GUIDE.md)

---

If you encounter issues:
1. Check the console logs for both backend and frontend
2. Verify network connectivity
3. Ensure all dependencies are installed
4. Check the API URL configuration
5. Refer to the troubleshooting and environment guides above 