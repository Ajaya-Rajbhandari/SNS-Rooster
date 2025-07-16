# Logging System Documentation

## Overview
The SNS Rooster application has a comprehensive logging system that automatically adapts to different environments (development, staging, production) with appropriate security measures and performance optimizations.

## Backend Logging (Node.js)

### Logger Configuration
- **File**: `rooster-backend/config/logger.js`
- **Type**: Custom built-in logger (no external dependencies)
- **Features**: Environment-aware, file logging, sensitive data sanitization

### Log Levels
| Level | Development | Staging | Production |
|-------|-------------|---------|------------|
| DEBUG | ✅ Console + File | ❌ | ❌ |
| INFO | ✅ Console + File | ✅ File | ❌ |
| WARN | ✅ Console + File | ✅ Console + File | ✅ Console + File |
| ERROR | ✅ Console + File | ✅ Console + File | ✅ Console + File |

### Usage Examples

```javascript
const { Logger, console } = require('./config/logger');

// Error logging (always visible)
Logger.error('Database connection failed', { error: err.message });

// Warning logging
Logger.warn('User exceeded break time limit', { userId, breakType });

// Info logging (development/staging only)
Logger.info('User logged in successfully', { userId, timestamp });

// Debug logging (development only)
Logger.debug('API request received', { method, url, body });

// Console wrapper (backward compatibility)
console.log('This will be debug level in development');
console.warn('This will be warning level');
console.error('This will be error level');
```

### Log Files
- **Location**: `rooster-backend/logs/`
- **Files**:
  - `combined.log` - All logs (info, warn, error)
  - `error.log` - Error logs only

### Security Features
- **Sensitive Data Sanitization**: Automatically redacts tokens, passwords, emails in production
- **Environment Detection**: Uses `NODE_ENV` environment variable
- **File Permissions**: Secure file writing with error handling

## Frontend Logging (Flutter)

### Logger Configuration
- **File**: `sns_rooster/lib/utils/logger.dart`
- **Type**: Built-in Flutter logger with environment awareness
- **Features**: Sensitive data filtering, performance logging, network logging

### Log Levels
| Level | Development | Staging | Production |
|-------|-------------|---------|------------|
| DEBUG | ✅ Console | ❌ | ❌ |
| INFO | ✅ Console | ✅ Console | ❌ |
| WARNING | ✅ Console | ✅ Console | ❌ |
| ERROR | ✅ Console | ✅ Console | ✅ Console |

### Usage Examples

```dart
import 'package:sns_rooster/utils/logger.dart';

// Debug logging (development only)
Logger.debug('Widget rebuilt');

// Info logging
Logger.info('User profile updated');

// Warning logging
Logger.warning('Network request timeout');

// Error logging (always visible)
Logger.error('Failed to load data', stackTrace);

// Authentication logging (special handling)
Logger.auth('User login', userId: 'user123', success: true);

// Network logging (development only)
Logger.network('GET', '/api/users', 200);

// Performance logging (development only)
Logger.performance('API call', Duration(milliseconds: 150));
```

### Security Features
- **Sensitive Data Filtering**: Automatically redacts tokens, emails, passwords
- **Environment Control**: Uses `EnvironmentConfig.isProduction`
- **URL Sanitization**: Removes query parameters from logged URLs

## Environment Configuration

### Backend Environment Variables
```bash
# Development
NODE_ENV=development

# Staging
NODE_ENV=staging

# Production
NODE_ENV=production
```

### Frontend Environment Configuration
```dart
// lib/config/environment_config.dart
EnvironmentConfig.isProduction    // Controls logging behavior
EnvironmentConfig.enableDebugLogging  // Development-only features
EnvironmentConfig.currentEnvironment  // Current environment string
```

## Production Deployment

### Backend Production Setup
```bash
# Set production environment
export NODE_ENV=production

# Start server
npm run start-prod

# Or manually
NODE_ENV=production node server.js
```

### Frontend Production Build
```bash
# Flutter web
flutter build web --release --dart-define=ENVIRONMENT=production

# Flutter mobile
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### Log Cleanup for Production
```bash
# Clean up debug logs before deployment
npm run cleanup-logs
```

## Monitoring and Maintenance

### Log File Management
```bash
# View recent logs
tail -f logs/combined.log

# View only errors
tail -f logs/error.log

# Check log file sizes
ls -lh logs/

# Archive old logs
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/
```

### Log Rotation
- **Automatic**: Log files are appended to (no built-in rotation)
- **Manual**: Use system tools like `logrotate` for production
- **Size Monitoring**: Monitor log file sizes regularly

### Performance Impact
- **Development**: Full logging with minimal performance impact
- **Production**: Minimal logging, optimized for performance
- **File I/O**: Asynchronous file writing to prevent blocking

## Debugging and Troubleshooting

### Enable Debug Logging Temporarily
```bash
# Backend
export NODE_ENV=development
npm start

# Frontend
flutter run --dart-define=ENVIRONMENT=development
```

### Common Issues

#### 1. Log Files Not Created
```bash
# Check directory permissions
ls -la logs/

# Create directory manually
mkdir -p logs
```

#### 2. Sensitive Data in Logs
- Check environment configuration
- Verify sanitization patterns
- Review log content before sharing

#### 3. Performance Issues
- Monitor log file sizes
- Check for excessive logging
- Review log level configuration

## Best Practices

### 1. Log Message Guidelines
- Use descriptive, actionable messages
- Include relevant context data
- Avoid logging sensitive information
- Use appropriate log levels

### 2. Error Logging
- Always include error details
- Log stack traces for debugging
- Include user context when relevant
- Don't log sensitive user data

### 3. Performance Logging
- Log operation durations
- Monitor slow operations
- Use performance logging sparingly
- Remove performance logs in production

### 4. Security Considerations
- Never log passwords or tokens
- Sanitize user input in logs
- Review logs before sharing
- Use secure log file permissions

## Integration with Monitoring Tools

### Log Aggregation
- Use tools like ELK Stack (Elasticsearch, Logstash, Kibana)
- Configure log forwarding for centralized monitoring
- Set up alerts for error patterns

### Health Checks
- Monitor log file sizes
- Check for error patterns
- Set up automated log rotation
- Configure log retention policies

---

**Last Updated**: July 16, 2025
**Version**: 1.0.0 