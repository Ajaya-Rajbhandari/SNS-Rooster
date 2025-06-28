# SNS Rooster - Complete Setup Guide

## Prerequisites

Before setting up the project, ensure you have the following installed:

- **Node.js** (v14 or higher) - [Download here](https://nodejs.org/)
- **MongoDB** (v4.4 or higher) or MongoDB Atlas account
- **Flutter** (v3.0 or higher) - [Installation guide](https://flutter.dev/docs/get-started/install)
- **Git** - [Download here](https://git-scm.com/)

## Project Structure

```
SNS-Rooster-app/
├── rooster-backend/          # Node.js backend API
├── sns_rooster/              # Flutter mobile app
└── docs/                     # Documentation
```

## Backend Setup

### 1. Navigate to Backend Directory
```bash
cd rooster-backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Environment Configuration
The `.env` file is already configured with:
- MongoDB Atlas connection
- JWT secret key
- Development environment settings

### 4. Start the Backend Server
```bash
npm run dev
```

The server will start on `http://localhost:5000`

## Frontend Setup

### 1. Navigate to Flutter Directory
```bash
cd sns_rooster
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API URL
The API URL in `lib/providers/auth_provider.dart` is configured for:
- **Physical Device**: `http://192.168.1.67:5000/api`
- **Desktop/Web**: `http://localhost:5000/api`
- **Android Emulator**: `http://10.0.2.2:5000/api`

### 4. Run the Flutter App
```bash
flutter run
```

## Network Configuration

### For Physical Devices
1. Find your computer's IP address:
   - Windows: `ipconfig`
   - Mac/Linux: `ifconfig`
2. Update the `_baseUrl` in `auth_provider.dart` with your IP
3. Ensure your device and computer are on the same network

### For Android Emulator
- Use `http://10.0.2.2:5000/api` (10.0.2.2 maps to localhost)

### For iOS Simulator
- Use `http://localhost:5000/api`

## Database Setup

The project is configured to use MongoDB Atlas (cloud database). The connection string is already set in the `.env` file.

### Creating Admin User
To create an admin user, run:
```bash
cd rooster-backend
node scripts/create-admin.js
```

## Testing the Setup

### 1. Backend Health Check
Visit `http://localhost:5000` in your browser. You should see:
```json
{"message": "Welcome to SNS Rooster API"}
```

### 2. Frontend Connection
1. Launch the Flutter app
2. Try to register or login
3. Check the backend console for API requests

## Common Issues

### Backend Issues
- **Port 5000 in use**: Change the PORT in `.env` file
- **MongoDB connection failed**: Check your internet connection and MongoDB Atlas credentials

### Frontend Issues
- **Network error**: Verify the API URL matches your setup
- **Build errors**: Run `flutter clean` then `flutter pub get`

### Device Connection Issues
- **Physical device can't reach API**: Ensure both devices are on same WiFi network
- **Emulator connection issues**: Use the correct IP address for your platform

## Development Workflow

1. **Start Backend**: `npm run dev` in `rooster-backend/`
2. **Start Frontend**: `flutter run` in `sns_rooster/`
3. **Hot Reload**: Press `r` in Flutter terminal for hot reload
4. **Backend Auto-reload**: Nodemon automatically restarts on file changes

## API Endpoints

- **Authentication**: `/api/auth/*`
- **Employees**: `/api/employees/*`
- **Attendance**: `/api/attendance/*`

Refer to `docs/API_CONTRACT.md` for detailed API documentation.

## Next Steps

1. Create an admin user using the script
2. Test user registration and login
3. Explore the employee management features
4. Set up attendance tracking

## Support

If you encounter issues:
1. Check the console logs for both backend and frontend
2. Verify network connectivity
3. Ensure all dependencies are installed
4. Check the API URL configuration

## See Also

- [DEVELOPMENT_SETUP.md](../DEVELOPMENT_SETUP.md) – Development and environment setup
- [NETWORK_TROUBLESHOOTING.md](../NETWORK_TROUBLESHOOTING.md) – Network and connectivity troubleshooting
- [PROJECT_ORGANIZATION_GUIDE.md](../PROJECT_ORGANIZATION_GUIDE.md) – Project structure and documentation standards