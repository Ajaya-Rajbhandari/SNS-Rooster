# SNS Rooster Quick Start Guide

## Prerequisites
- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- Flutter (v3.0 or higher)
- Git

## Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd SNS-Rooster
```

### 2. Backend Setup
```bash
# Navigate to backend directory
cd rooster-backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your configuration
# Required variables:
# MONGODB_URI=mongodb://localhost:27017/sns_rooster
# JWT_SECRET=your-secret-key
# PORT=5000

# Start development server
npm run dev
```

### 3. Frontend Setup
```bash
# Navigate to Flutter project directory
cd sns_rooster

# Get dependencies
flutter pub get

# Update API URL in auth_provider.dart
# const String baseUrl = 'http://localhost:5000/api';

# Run the app
flutter run
```

## Development Workflow

### Backend Development
1. The backend uses `nodemon` for automatic reloading
2. API routes are in `rooster-backend/routes/`
3. Models are in `rooster-backend/models/`
4. Middleware is in `rooster-backend/middleware/`

### Frontend Development
1. State management is handled by `provider` package
2. Screens are organized by role in `lib/screens/`
3. Common widgets are in `lib/widgets/common/`
4. API calls are managed by providers in `lib/providers/`

## Testing

### Backend Tests
```bash
cd rooster-backend
npm test
```

### Frontend Tests
```bash
cd sns_rooster
flutter test
```

## Common Tasks

### Creating a New User
1. Start the backend server
2. Use the registration endpoint:
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "role": "employee",
    "department": "IT",
    "position": "Developer"
  }'
```

### Adding a New Feature
1. Create necessary backend routes in `rooster-backend/routes/`
2. Add corresponding models if needed
3. Create frontend provider in `sns_rooster/lib/providers/`
4. Add UI components in `sns_rooster/lib/screens/`

## Troubleshooting

### Backend Issues
1. **MongoDB Connection Error**
   - Check if MongoDB is running
   - Verify MONGODB_URI in .env
   - Check network connectivity

2. **JWT Authentication Error**
   - Verify JWT_SECRET in .env
   - Check token expiration
   - Ensure proper Authorization header

### Frontend Issues
1. **API Connection Error**
   - Verify backend server is running
   - Check baseUrl in auth_provider.dart
   - Ensure proper CORS configuration

2. **State Management Issues**
   - Check provider initialization
   - Verify notifyListeners() calls
   - Ensure proper widget tree structure

## Deployment

### Backend Deployment
1. Set up production environment variables
2. Configure MongoDB Atlas
3. Deploy to Node.js hosting (e.g., Heroku)
4. Set up SSL certificate

### Frontend Deployment
1. Update API URL for production
2. Build release version:
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```
3. Deploy to app stores

## Contributing
1. Create a new branch for features
2. Follow existing code style
3. Add tests for new features
4. Update documentation
5. Submit pull request

## Support
For issues and questions:
1. Check existing documentation
2. Review closed issues
3. Create new issue with:
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details 