# sns-rooster
# SNS Rooster - Employee Management System

A comprehensive employee management system built with Flutter (frontend) and Node.js (backend) for tracking attendance, managing users, and handling employee data.

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 or higher)
- Flutter SDK (v3.0 or higher)
- MongoDB (local or cloud instance)

### Backend Setup
```bash
cd rooster-backend
npm install
node server.js
```

### Frontend Setup
```bash
cd sns_rooster
flutter pub get
flutter run
```

## 📁 Project Structure

```
SNS-Rooster-app/
├── rooster-backend/          # Node.js backend API
│   ├── routes/              # API route definitions
│   ├── models/              # Database models
│   ├── middleware/          # Authentication & validation
│   └── server.js           # Main server file
├── sns_rooster/             # Flutter frontend app
│   ├── lib/
│   │   ├── screens/        # UI screens
│   │   ├── models/         # Data models
│   │   ├── services/       # API services
│   │   └── providers/      # State management
│   └── pubspec.yaml
└── docs/                    # Documentation
```

## 🔧 Features

- **User Management**: Create, update, and manage user accounts
- **Role-based Access**: Admin, Manager, and Employee roles
- **Attendance Tracking**: Clock in/out functionality
- **Employee Management**: Comprehensive employee data handling
- **Profile Management**: Complete profile editing with image upload
- **Authentication**: Secure JWT-based authentication
- **Analytics & Reporting**: Dynamic work hours, attendance breakdown, and custom date range analytics with modern charts and tooltips
- **Cross-platform**: Works on Android, iOS, and Web

## 📊 Analytics & Reporting (June 2024)

- Dynamic analytics range: 7, 30, or custom days
- Custom range dialog with date preview
- Dynamic work hours chart and labels
- Enhanced pie chart percentage display
- Custom-styled tooltips
- Backend supports flexible range and status inference
- See [Analytics & UI/UX Improvements Documentation](docs/features/ANALYTICS_UI_IMPROVEMENTS.md) for full details

## 📚 Documentation

- **[Development Setup Guide](docs/DEVELOPMENT_SETUP.md)** - Complete setup instructions
- **[Network Troubleshooting](docs/NETWORK_TROUBLESHOOTING.md)** - Resolve connectivity issues
- **[API Documentation](docs/api/API_CONTRACT.md)** - Backend API reference
- **[System Architecture](docs/SYSTEM_ARCHITECTURE.md)** - Technical overview

## 🐛 Common Issues

### "Network error occurred" in Flutter app
This usually indicates connectivity issues between the Flutter app and backend server.

**Quick Fix:**
1. Ensure backend server is running on `http://0.0.0.0:5000`
2. Update Flutter app base URL to use your machine's IP address
3. Check firewall settings

**Detailed Solution:** See [Network Troubleshooting Guide](docs/NETWORK_TROUBLESHOOTING.md)

### API endpoints returning 404
Verify that:
- Backend server is running
- API routes are properly mounted
- Flutter app uses correct endpoint URLs

## 🧪 Testing

### Backend API Testing
```bash
# Test server connectivity
node test-backend.js

# Test user authentication
node test-users-api.js

# Test network connectivity
node test-ip-connection.js
```

### Frontend Testing
```bash
cd sns_rooster
flutter test
```

## 🌐 Network Configuration

### Development
- Backend: `http://0.0.0.0:5000` (accessible from all interfaces)
- Frontend: Configured to use host machine IP address

### Platform-specific URLs
- **Android Emulator**: `http://10.0.2.2:5000/api` or `http://[HOST_IP]:5000/api`
- **iOS Simulator**: `http://localhost:5000/api`
- **Web**: `http://localhost:5000/api`
- **Physical Device**: `http://[HOST_IP]:5000/api`

## 🔐 Security

- JWT-based authentication
- Role-based access control
- Input validation and sanitization
- CORS configuration
- Environment variable configuration

## 🚀 Deployment

### Backend
- Configure environment variables
- Use process manager (PM2)
- Set up reverse proxy (nginx)
- Enable HTTPS

### Frontend
- Build for production: `flutter build`
- Deploy to app stores or web hosting
- Configure production API URLs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For issues and questions:
1. Check the [troubleshooting documentation](docs/NETWORK_TROUBLESHOOTING.md)
2. Review the [development setup guide](docs/DEVELOPMENT_SETUP.md)
3. Test network connectivity with provided scripts
4. Create an issue with detailed information

## Recent Updates

### Profile System Enhancements (Latest)
- **Backend**: Updated profile update endpoint to accept `firstName` and `lastName` fields
- **Backend**: Added backward compatibility for legacy `name` field
- **Frontend**: Fixed duplicate email fields in profile screen
- **Frontend**: Implemented profile image upload and display functionality
- **Frontend**: Updated user avatar widget with image support and fallback initials
- **Frontend**: Updated app drawer to display full name using `firstName` and `lastName`
- **Dependencies**: Added `image_picker` for profile image selection

### Previous Updates
- Fixed `/api/auth/me` endpoint for profile fetching
- Updated `auth.js` middleware for better token validation
- Enhanced error handling for profile fetching
- Verified API endpoints with comprehensive testing

# Attendance & Break Logic Fixes (June 2025)

## Overview
This update documents the major fixes and improvements made to the attendance and break logic in the SNS Rooster backend and frontend, including:
- Consistent UTC date handling for attendance records
- Proper unique index usage in MongoDB
- Robust status and button logic in the Flutter UI
- Debug logging for backend diagnosis

## Key Fixes

### 1. UTC Date Handling for Attendance
- All attendance queries and document creation now use **UTC midnight** for the `date` field.
- This prevents duplicate key errors and ensures correct attendance tracking for all users, regardless of timezone.
- Example:
  ```js
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
  ```

### 2. MongoDB Index Correction
- Removed the unique index on `date` alone (`date_1`).
- Kept only the compound unique index on `{ user, date }` (`user_1_date_1`).
- This allows each user to have one attendance per day, but multiple users can clock in on the same day.

### 3. Backend Controller Improvements
- All attendance-related controllers (`checkIn`, `checkOut`, `startBreak`, `endBreak`, `getAttendanceStatus`) now use UTC date logic.
- Added debug logging for all major actions and error cases.
- Improved error messages for duplicate and invalid actions.

### 4. Frontend UI Logic
- The Flutter dashboard now correctly reflects all attendance states:
  - Not Clocked In: Only "Clock In" enabled
  - Clocked In: "Clock Out" and "Start Break" enabled
  - On Break: "End Break" enabled, "Clock Out" disabled
  - Clocked Out: Only "Clock In" enabled
- Status and quick actions update immediately after each action.

### 5. How to Fix for Future Issues
- Always use UTC for all date fields in backend logic.
- Ensure only the `{ user, date }` index is unique in MongoDB.
- If you see duplicate key errors, check your indexes with `db.attendances.getIndexes()` and remove any unique `date_1` index.

## References
- See also: `docs/api/API_DOCUMENTATION.md`, `SECURITY_ACCESS_CONTROL_DOCUMENTATION.md`, `LAYOUT_FIX_DOCUMENTATION.md`, `CLOCK_IN_RESET_FIX.md`

---

_Last updated: June 23, 2025_
