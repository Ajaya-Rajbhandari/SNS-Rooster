# SNS Rooster

A comprehensive employee management and attendance tracking system built with Flutter and Node.js.

## Features

### Current Features
- **Authentication & Authorization**
  - Secure login with JWT
  - Role-based access control (Admin/Employee)
  - Session management
  - Secure token storage

- **Employee Management**
  - Profile management
  - Department assignment
  - Role management
  - User activation/deactivation

- **Leave Management**
  - Leave request submission
  - Leave approval workflow
  - Leave balance tracking
  - Leave history view

- **Attendance Tracking**
  - Check-in/Check-out
  - Break time tracking
  - Attendance history
  - Late arrival tracking

### Planned Features
- **Timesheet Management**
  - Daily time entry
  - Weekly/monthly view
  - Overtime tracking
  - Timesheet approval workflow
  - Export functionality

- **Enhanced Leave Management**
  - Leave calendar view
  - Leave request templates
  - Leave balance calculator
  - Leave history reports

- **Notifications System**
  - Push notifications
  - Email notifications
  - In-app notifications
  - Notification preferences

- **Reports and Analytics**
  - Attendance reports
  - Leave reports
  - Timesheet reports
  - Employee performance metrics
  - Custom report generation

## Tech Stack

### Frontend
- Flutter (v3.0+)
- Provider for state management
- SharedPreferences for local storage
- HTTP package for API communication

### Backend
- Node.js with Express.js
- MongoDB with Mongoose
- JWT for authentication
- RESTful API architecture

## Getting Started

### Prerequisites
- Node.js (v14+)
- MongoDB (v4.4+)
- Flutter (v3.0+)
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd SNS-Rooster
```

2. Backend Setup:
```bash
cd rooster-backend
npm install
cp .env.example .env
# Edit .env with your configuration
npm run dev
```

3. Frontend Setup:
```bash
cd sns_rooster
flutter pub get
# Update API URL in auth_provider.dart
flutter run
```

## Project Structure

### Frontend (`sns_rooster/`)
```
lib/
├── main.dart              # App entry point
├── providers/            # State management
├── screens/             # UI screens
│   ├── splash/
│   ├── login/
│   ├── admin/
│   └── employee/
├── models/              # Data models
└── widgets/            # Reusable components
```

### Backend (`rooster-backend/`)
```
├── config/             # Configuration
├── middleware/         # Express middleware
├── models/            # Mongoose schemas
├── routes/            # API routes
└── server.js          # Entry point
```

## Documentation

Detailed documentation is available in the `docs/` directory:
- [System Architecture](docs/SYSTEM_ARCHITECTURE.md)
- [Authentication Guide](docs/AUTHENTICATION.md)
- [API Documentation](docs/API.md)
- [Development Guide](docs/DEVELOPMENT.md)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
