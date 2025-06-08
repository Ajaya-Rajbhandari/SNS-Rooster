# SNS Rooster System Architecture Documentation

## Purpose
This document provides a comprehensive overview of the SNS Rooster application, detailing its architecture, components, and interactions. It is designed to enable both human developers and artificial intelligence agents to quickly understand, navigate, and contribute to the project. The primary goal of SNS Rooster is to provide a robust and efficient solution for employee management and attendance tracking within an organization.

## Key Features
- **User Authentication & Authorization**: Secure login, registration (for admins), and role-based access control for distinguishing between 'admin' and 'employee' roles.
- **Employee Management**: CRUD (Create, Read, Update, Delete) operations for employee profiles, including activation/deactivation.
- **Attendance Tracking**: Real-time check-in and check-out functionality, with detailed attendance records.
- **Data Reporting**: (Future enhancement) Generation of attendance reports and employee statistics.
- **Scalable MERN Stack**: Built on MongoDB, Express.js, Node.js, and Flutter for a robust and performant application.

## System Overview
SNS Rooster is a MERN stack (MongoDB, Express.js, React Native/Flutter, Node.js) application designed for employee management and attendance tracking. The system implements a secure, role-based authentication system with real-time attendance tracking and employee management features.

## Architecture Diagram
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │     │  Express.js     │     │    MongoDB      │
│   (Frontend)    │◄───►│   (Backend)     │◄───►│   (Database)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                        │
        │                       │                        │
        ▼                       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  SharedPrefs    │     │    JWT Auth     │     │   Collections   │
│  (Local Storage)│     │  (Middleware)   │     │  (Data Models)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## 1. Database Layer (MongoDB)

### Collections

#### Users Collection
```javascript
{
  _id: ObjectId,
  email: String,
  password: String (hashed),
  name: String,
  role: String ('admin' | 'employee'),
  department: String,
  position: String,
  isActive: Boolean,
  createdAt: Date,
  updatedAt: Date,
  lastLogin: Date
}
```

#### Attendance Collection
```javascript
{
  _id: ObjectId,
  userId: ObjectId (ref: 'Users'),
  checkIn: Date,
  checkOut: Date,
  status: String ('present' | 'absent' | 'late'),
  breaks: [{
    start: Date,
    end: Date,
    duration: Number
  }],
  totalBreakDuration: Number,
  createdAt: Date,
  updatedAt: Date
}
```

### Indexes
- Users: `email` (unique)
- Attendance: `userId` + `checkIn` (compound)

## 2. Backend Layer (Node.js/Express.js)

### Project Structure
```
rooster-backend/
├── config/
│   └── db.js           # MongoDB connection
├── middleware/
│   ├── auth.js         # JWT verification
│   └── error.js        # Error handling
├── models/
│   ├── User.js         # User schema
│   └── Attendance.js   # Attendance schema
├── routes/
│   ├── authRoutes.js   # Authentication endpoints
│   └── attendanceRoutes.js # Attendance endpoints
├── utils/
│   └── validators.js   # Input validation
└── server.js           # Entry point
```

### Key Components

#### 1. Database Connection (`config/db.js`)
```javascript
const mongoose = require('mongoose');
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  }
};
```

#### 2. Authentication Middleware (`middleware/auth.js`)
```javascript
const jwt = require('jsonwebtoken');
const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization').replace('Bearer ', '');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Authentication required' });
  }
};
```

#### 3. API Routes

##### Authentication Routes (`routes/authRoutes.js`)
```javascript
// POST /api/auth/login
router.post('/login', async (req, res) => {
  // 1. Validate credentials
  // 2. Generate JWT
  // 3. Return user data and token
});

// POST /api/auth/register
router.post('/register', auth, async (req, res) => {
  // 1. Validate admin role
  // 2. Create new user
  // 3. Return success
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  // 1. Verify token
  // 2. Return user data
});
```

##### Attendance Routes (`routes/attendanceRoutes.js`)
```javascript
// POST /api/attendance/check-in
router.post('/check-in', auth, async (req, res) => {
  // 1. Create attendance record
  // 2. Return status
});

// POST /api/attendance/check-out
router.post('/check-out', auth, async (req, res) => {
  // 1. Update attendance record
  // 2. Calculate duration
  // 3. Return status
});
```

## 3. Frontend Layer (Flutter)

### Project Structure
```
sns_rooster/
├── lib/
│   ├── main.dart              # Entry point
│   ├── providers/
│   │   ├── auth_provider.dart # Auth state management
│   │   └── attendance_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   ├── login/
│   │   ├── admin/
│   │   └── employee/
│   ├── models/
│   │   ├── user.dart
│   │   └── attendance.dart
│   └── widgets/
│       └── common/
└── assets/
    └── images/
```

### Key Components

#### 1. State Management (`providers/`)

##### AuthProvider
```dart
class AuthProvider with ChangeNotifier {
  // State
  String? _token;
  Map<String, dynamic>? _user;
  
  // Methods
  Future<void> login(String email, String password) async {
    // 1. API call
    // 2. Store token
    // 3. Update state
  }
  
  Future<void> logout() async {
    // 1. Clear state
    // 2. Clear storage
    // 3. Notify listeners
  }
}
```

##### AttendanceProvider
```dart
class AttendanceProvider with ChangeNotifier {
  final AuthProvider _auth;
  
  Future<void> checkIn() async {
    // 1. API call with auth token
    // 2. Update state
  }
  
  Future<void> checkOut() async {
    // 1. API call with auth token
    // 2. Update state
  }
}
```

#### 2. Screens

##### Splash Screen
```dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _checkAuthStatus() async {
    // 1. Initialize auth
    // 2. Route based on auth state
  }
}
```

##### Login Screen
```dart
class LoginScreen extends StatelessWidget {
  Future<void> _handleLogin() async {
    // 1. Validate input
    // 2. Call auth provider
    // 3. Handle response
  }
}
```

## 4. Data Flow

### Authentication Flow
1. **Login**
   ```
   User Input → Flutter App → Express Backend → MongoDB
   JWT Token ← Express Backend ← Flutter App ← SharedPreferences
   ```

2. **Protected Requests**
   ```
   Flutter App → JWT Token → Express Backend → MongoDB
   Response Data ← Express Backend ← Flutter App ← State Update
   ```

3. **Logout**
   ```
   User Action → Flutter App → Clear Token → Clear Storage
   Navigation ← Flutter App ← State Update
   ```

### Attendance Flow
1. **Check-in**
   ```
   User Action → Flutter App → Auth Token → Express Backend
   Attendance Record ← MongoDB ← Express Backend ← Flutter App
   ```

2. **Check-out**
   ```
   User Action → Flutter App → Auth Token → Express Backend
   Updated Record ← MongoDB ← Express Backend ← Flutter App
   ```

## 5. Security Measures

### 1. Authentication
- JWT tokens with expiration
- Secure password hashing (bcrypt)
- Role-based access control
- Token verification middleware

### 2. Data Protection
- Input validation
- MongoDB sanitization
- HTTPS enforcement
- CORS configuration

### 3. Error Handling
- Global error middleware
- Structured error responses
- Logging system
- Client-side error boundaries

## 6. Development and Deployment

### Environment Setup
```bash
# Backend
cd rooster-backend
npm install
cp .env.example .env
# Configure .env with:
# MONGODB_URI=...
# JWT_SECRET=...
# PORT=5000

# Frontend
cd sns_rooster
flutter pub get
# Configure API URL in auth_provider.dart
```

### Running Locally
```bash
# Backend
cd rooster-backend
npm run dev  # Uses nodemon

# Frontend
cd sns_rooster
flutter run
```

### Production Deployment
1. **Backend**
   - Node.js server (e.g., Heroku, DigitalOcean)
   - MongoDB Atlas
   - Environment variables
   - SSL certificate

2. **Frontend**
   - Flutter build
   - App store deployment
   - Play store deployment
   - API URL configuration

## 7. Testing

### Backend Tests
```javascript
// Jest test example
describe('Auth Routes', () => {
  test('login with valid credentials', async () => {
    // Test implementation
  });
});
```

### Frontend Tests
```dart
// Flutter test example
void main() {
  group('AuthProvider Tests', () {
    test('login success', () async {
      // Test implementation
    });
  });
}
```

## 8. Monitoring and Maintenance

### Logging
- Backend: Winston/Morgan
- Frontend: Custom logging system
- Error tracking: Sentry

### Performance
- MongoDB indexes
- API response caching
- Image optimization
- State management optimization

### Updates
- Version control
- Changelog maintenance
- Dependency updates
- Security patches

## 9. How to Use This Documentation (for AI Agents)
This documentation is structured to facilitate programmatic understanding and navigation. AI agents can leverage the following approaches:

- **Section Parsing**: Each major section (e.g., "Database Layer", "Backend Layer", "Frontend Layer") provides a logical grouping of information. Agents can parse these sections to focus on specific architectural components.
- **Keyword Search**: Utilize keywords such as "schema", "route", "provider", "middleware", "authentication", "attendance" to locate relevant code snippets and descriptions.
- **Code Examples**: Code blocks are provided for key functionalities (e.g., database connection, authentication middleware, provider methods). Agents can extract and analyze these examples for implementation details.
- **Data Flow Analysis**: The "Data Flow" section explicitly details the interaction between frontend, backend, and database for core functionalities (authentication, attendance). Agents can trace these flows to understand data transformations and API calls.
- **File Path References**: Specific file paths (e.g., `config/db.js`, `auth_provider.dart`) are provided throughout the document. Agents can use these paths for targeted file access and code analysis.
- **Security & Troubleshooting**: Refer to these sections for common issues, error handling, and security considerations, which can aid in debugging and vulnerability assessment.
- **Component Identification**: The project structure diagrams and component descriptions help identify key modules and their responsibilities.

By combining these methods, AI agents can build a comprehensive understanding of the SNS Rooster project and effectively assist in development, debugging, and maintenance tasks. 