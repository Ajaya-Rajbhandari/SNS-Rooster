# SNS Rooster Project Organization Guide

## 📁 **Project Structure Overview**

```
SNS-Rooster-app/
├── docs/                          # 📚 All documentation
│   ├── api/
│   │   └── API_CONTRACT.md        # 🎯 Single API documentation
│   ├── CLEANUP_SUMMARY.md         # 📋 Cleanup history
│   ├── DEVELOPMENT_SETUP.md       # 🛠️ Setup instructions
│   ├── NETWORK_TROUBLESHOOTING.md # 🌐 Network issues
│   ├── PRODUCT_REQUIREMENTS_DOCUMENT.md # 📋 Requirements
│   └── PROJECT_ORGANIZATION_GUIDE.md # 📖 This file
├── rooster-backend/               # 🔧 Backend API
│   ├── package.json              # 📦 Backend dependencies
│   ├── controllers/              # 🎮 API controllers
│   ├── models/                   # 📊 Database models
│   ├── routes/                   # 🛣️ API routes
│   ├── middleware/               # 🔒 Authentication & validation
│   └── scripts/                  # 🧪 Test & utility scripts
├── sns_rooster/                  # 📱 Flutter mobile app
│   ├── pubspec.yaml             # 📦 Flutter dependencies
│   ├── package.json             # 📦 TypeScript only
│   ├── lib/                     # 📱 Flutter source code
│   ├── functions/               # 🔥 Firebase functions
│   │   └── package.json         # 📦 Firebase dependencies
│   └── docs/                    # 📚 App-specific docs
└── assets/                      # 🎨 Shared assets
```

## 🎯 **Key Principles**

### **1. Single Source of Truth**
- **API Documentation**: Only `docs/api/API_CONTRACT.md`
- **Dependencies**: Each project manages its own dependencies
- **Configuration**: Environment-specific configs in respective projects

### **2. Clear Separation of Concerns**
- **Backend**: Node.js/Express API in `rooster-backend/`
- **Frontend**: Flutter mobile app in `sns_rooster/`
- **Functions**: Firebase functions in `sns_rooster/functions/`
- **Documentation**: Centralized in `docs/`

### **3. Consistent Naming**
- **Files**: Use kebab-case for files and directories
- **APIs**: Use RESTful naming conventions
- **Variables**: Follow language-specific conventions

## 📦 **Dependency Management**

### **Backend Dependencies** (`rooster-backend/package.json`)
```json
{
  "dependencies": {
    "bcrypt": "^6.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.5.0",
    "express": "^5.1.0",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.15.1",
    "multer": "^2.0.1"
  }
}
```

### **Flutter Dependencies** (`sns_rooster/pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  # ... other Flutter packages
```

### **TypeScript Dependencies** (`sns_rooster/package.json`)
```json
{
  "devDependencies": {
    "typescript": "^4.9.5"
  }
}
```

### **Firebase Functions** (`sns_rooster/functions/package.json`)
```json
{
  "dependencies": {
    "firebase-admin": "^13.4.0",
    "firebase-functions": "^6.3.2"
  }
}
```

## 📚 **Documentation Standards**

### **API Documentation** (`docs/api/API_CONTRACT.md`)
- **Data Models**: Complete JSON schemas
- **Endpoints**: HTTP method, path, description, auth requirements
- **Examples**: Request/response examples
- **Error Handling**: All possible error responses
- **Authentication**: JWT token requirements

### **Setup Documentation** (`docs/DEVELOPMENT_SETUP.md`)
- **Prerequisites**: Required software and versions
- **Installation**: Step-by-step setup instructions
- **Configuration**: Environment variables and settings
- **Testing**: How to run tests and verify setup

### **Troubleshooting** (`docs/NETWORK_TROUBLESHOOTING.md`)
- **Common Issues**: Frequently encountered problems
- **Solutions**: Step-by-step resolution steps
- **Debugging**: Tools and techniques for debugging

## 🧪 **Testing Strategy**

### **Backend Testing** (`rooster-backend/scripts/`)
- **API Tests**: Test all endpoints
- **Authentication Tests**: Verify JWT functionality
- **Database Tests**: Test data persistence
- **Integration Tests**: End-to-end workflows

### **Frontend Testing** (`sns_rooster/test/`)
- **Unit Tests**: Individual component testing
- **Widget Tests**: UI component testing
- **Integration Tests**: App flow testing

## 🔒 **Security Guidelines**

### **Authentication**
- **JWT Tokens**: Use for API authentication
- **Password Hashing**: bcrypt for password storage
- **Environment Variables**: Store sensitive data in .env files

### **File Uploads**
- **Validation**: Validate file types and sizes
- **Storage**: Secure file storage with proper permissions
- **Access Control**: Restrict file access based on user roles

### **API Security**
- **Rate Limiting**: Prevent abuse
- **Input Validation**: Sanitize all inputs
- **CORS**: Configure cross-origin requests properly

## 🚀 **Development Workflow**

### **Feature Development**
1. **Create branch**: `git checkout -b feature/feature-name`
2. **Update API**: Add endpoints in `rooster-backend/`
3. **Update docs**: Modify `docs/api/API_CONTRACT.md`
4. **Update frontend**: Implement in `sns_rooster/`
5. **Test**: Run tests in both projects
6. **Document**: Update relevant documentation
7. **Merge**: Create pull request and merge

### **Bug Fixes**
1. **Identify**: Locate the issue in appropriate project
2. **Fix**: Implement the solution
3. **Test**: Verify the fix works
4. **Document**: Update documentation if needed
5. **Deploy**: Deploy the fix

## 📋 **Maintenance Checklist**

### **Weekly**
- [ ] Review and merge pull requests
- [ ] Check for security updates
- [ ] Monitor error logs
- [ ] Update dependencies if needed

### **Monthly**
- [ ] Review API documentation accuracy
- [ ] Audit unused dependencies
- [ ] Check build artifact cleanup
- [ ] Review and update setup guides

### **Quarterly**
- [ ] Major dependency updates
- [ ] Security audit
- [ ] Performance review
- [ ] Documentation overhaul

## 🎨 **Code Style Guidelines**

### **Backend (JavaScript/Node.js)**
- **ESLint**: Use ESLint for code quality
- **Prettier**: Consistent code formatting
- **JSDoc**: Document functions and classes
- **Error Handling**: Proper try-catch blocks

### **Frontend (Flutter/Dart)**
- **Dart Analysis**: Use `flutter analyze`
- **Formatting**: Use `dart format`
- **Documentation**: Use DartDoc comments
- **State Management**: Consistent provider usage

## 🔧 **Tools and Utilities**

### **Development Tools**
- **VS Code**: Recommended IDE with extensions
- **Postman**: API testing
- **Flutter Inspector**: UI debugging
- **MongoDB Compass**: Database management

### **Build Tools**
- **Node.js**: Backend runtime
- **Flutter SDK**: Mobile development
- **Firebase CLI**: Functions deployment
- **Git**: Version control

## 📞 **Support and Resources**

### **Documentation**
- **API Docs**: `docs/api/API_CONTRACT.md`
- **Setup Guide**: `docs/DEVELOPMENT_SETUP.md`
- **Troubleshooting**: `docs/NETWORK_TROUBLESHOOTING.md`

### **External Resources**
- **Flutter Docs**: https://docs.flutter.dev/
- **Express.js Docs**: https://expressjs.com/
- **MongoDB Docs**: https://docs.mongodb.com/
- **Firebase Docs**: https://firebase.google.com/docs

---

**Last Updated**: 2024-12-16  
**Version**: 1.0  
**Maintainer**: Development Team 