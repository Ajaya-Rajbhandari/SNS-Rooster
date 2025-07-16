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
- **[Logging System](docs/LOGGING_SYSTEM.md)** - Comprehensive logging documentation
- **[Production Deployment](docs/PRODUCTION_DEPLOYMENT.md)** - Production deployment guide

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

# Production-Ready Logging & Recent Features (July 2025)

## Overview
This update documents the production-ready logging system and recent feature enhancements in the SNS Rooster backend and frontend, including:
- Environment-aware logging system
- Production debug log suppression
- Enhanced break management with notifications
- Timesheet approval system
- Event management with real-time notifications

## Production Logging System

### Backend Logging (Winston)
- **Development**: Full debug logging with console output
- **Production**: Only errors and warnings logged to console, all logs saved to files
- **Log Files**: 
  - `logs/error.log` - Error-level logs only
  - `logs/combined.log` - All logs (info, warn, error)
- **Log Rotation**: 5MB max file size, 5 files max
- **Security**: Sensitive data automatically redacted in production

### Frontend Logging (Flutter)
- **Development**: Full debug logging enabled
- **Production**: Only error logs and critical info
- **Security**: Sensitive data (tokens, emails, etc.) automatically sanitized
- **Performance**: Network and performance logging in development only

### Environment Configuration
```dart
// Flutter - lib/config/environment_config.dart
EnvironmentConfig.isProduction // Controls logging behavior
EnvironmentConfig.enableDebugLogging // Development-only features
```

## Recent Feature Enhancements

### 1. Break Management System
- **Break Type Selection**: Shows allowed duration for each break type
- **Time Monitoring**: Automatic notifications for break time violations
- **Admin Controls**: Real-time break management with status updates
- **Notifications**: FCM push notifications for break warnings and violations

### 2. Timesheet Approval System
- **Status Management**: Pending, Approved, Rejected statuses
- **Admin Interface**: Dedicated timesheet approval screen
- **Notifications**: Automatic notifications for status changes
- **Filtering**: Status-based filtering for easy management

### 3. Event Management
- **Real Events**: Admin can create and manage company events
- **Employee Participation**: Join/leave functionality with notifications
- **Time-based Access**: Join buttons only active when events start
- **Real-time Updates**: Live event status and participant lists

### 4. Department-wise Analytics
- **Attendance Stats**: Present, absent, and on-leave counts per department
- **Real-time Data**: Live dashboard updates with actual attendance data
- **Admin Overview**: Comprehensive department performance metrics

### 5. Notification System
- **FCM Integration**: Push notifications for all major events
- **Database Notifications**: Persistent notification storage
- **Event Notifications**: Automatic notifications for event creation, joins, leaves
- **Break Notifications**: Time-based warnings and violation alerts

## Production Deployment

### Environment Variables
```bash
# Production
NODE_ENV=production
JWT_SECRET=your-secure-jwt-secret
MONGODB_URI=your-mongodb-connection-string
EMAIL_PROVIDER=resend
RESEND_API_KEY=your-resend-api-key
FCM_SERVER_KEY=your-fcm-server-key

# Frontend
FLUTTER_ENV=production
```

### Logging Configuration
- Debug logs automatically suppressed in production
- Only essential logs (errors, warnings) shown in console
- All logs saved to files for monitoring and debugging
- Sensitive data automatically redacted

### Security Features
- HTTPS enforcement in production
- Certificate pinning for secure connections
- JWT token validation with secure secrets
- Input validation and sanitization
- CORS configuration for production domains

## Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| Debug Logs | ✅ Enabled | ❌ Disabled |
| Console Output | ✅ Full | ⚠️ Errors Only |
| File Logging | ✅ Enabled | ✅ Enabled |
| Sensitive Data | ✅ Visible | ❌ Redacted |
| HTTPS | ⚠️ Optional | ✅ Required |
| Performance Logs | ✅ Enabled | ❌ Disabled |

## References
- See also: `docs/api/API_DOCUMENTATION.md`, `SECURITY_ACCESS_CONTROL_DOCUMENTATION.md`, `LAYOUT_FIX_DOCUMENTATION.md`, `CLOCK_IN_RESET_FIX.md`

---

_Last updated: July 16, 2025_
