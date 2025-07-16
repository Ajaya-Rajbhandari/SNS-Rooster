# Production Deployment Guide

## Overview
This guide covers deploying the SNS Rooster application to production with proper logging, security, and performance configurations.

## Pre-Deployment Checklist

### 1. Environment Variables
Ensure all production environment variables are set:

```bash
# Required for Production
NODE_ENV=production
JWT_SECRET=your-secure-jwt-secret-here
MONGODB_URI=your-mongodb-production-connection-string
EMAIL_PROVIDER=resend
RESEND_API_KEY=your-resend-api-key
FCM_SERVER_KEY=your-fcm-server-key

# Optional but Recommended
PORT=5000
HOST=0.0.0.0
LOG_LEVEL=error
```

### 2. Security Configuration
- ✅ HTTPS enforcement enabled
- ✅ JWT secret is secure and unique
- ✅ Database connection uses SSL
- ✅ CORS configured for production domains
- ✅ Input validation enabled

### 3. Database Setup
- ✅ Production MongoDB instance configured
- ✅ Database indexes optimized
- ✅ Backup strategy in place
- ✅ Connection pooling configured

## Deployment Steps

### Step 1: Clean Up Debug Logs
Before deploying to production, clean up debug logs:

```bash
cd rooster-backend
npm run cleanup-logs
```

This will:
- Comment out debug console.log statements
- Remove development-only logging
- Keep essential error and warning logs

### Step 2: Install Dependencies
```bash
# Backend
cd rooster-backend
npm install --production

# Frontend (if deploying web version)
cd ../sns_rooster
flutter build web --release
```

### Step 3: Start Production Server
```bash
# Using npm script
npm run start-prod

# Or manually
NODE_ENV=production node server.js
```

### Step 4: Verify Deployment
Check that:
- Server starts without errors
- Only essential logs appear in console
- Log files are created in `logs/` directory
- All API endpoints respond correctly

## Logging Configuration

### Production Logging Behavior
- **Console Output**: Only errors and warnings
- **File Logging**: All logs saved to files
- **Log Files**:
  - `logs/error.log` - Error-level logs only
  - `logs/combined.log` - All logs (info, warn, error)
- **Sensitive Data**: Automatically redacted

### Log Management
```bash
# View recent logs
tail -f logs/combined.log

# View only errors
tail -f logs/error.log

# Check log file sizes
ls -lh logs/

# Rotate logs (if needed)
mv logs/combined.log logs/combined.log.old
mv logs/error.log logs/error.log.old
```

### Log Levels
- **ERROR**: System errors, crashes, security issues
- **WARN**: Potential issues, deprecated features
- **INFO**: Important events, user actions
- **DEBUG**: Detailed debugging (development only)

## Monitoring and Maintenance

### Health Checks
Monitor these endpoints:
- `GET /api/health` - Basic health check
- `GET /api/analytics/admin/overview` - System overview
- Database connection status
- Log file sizes and rotation

### Performance Monitoring
- Monitor response times
- Check memory usage
- Track database query performance
- Monitor file upload sizes

### Security Monitoring
- Monitor failed authentication attempts
- Check for suspicious API calls
- Review error logs for security issues
- Monitor file upload patterns

## Troubleshooting

### Common Issues

#### 1. Server Won't Start
```bash
# Check environment variables
echo $NODE_ENV
echo $JWT_SECRET

# Check port availability
netstat -tulpn | grep :5000

# Check logs
tail -f logs/error.log
```

#### 2. Database Connection Issues
```bash
# Test MongoDB connection
node -e "require('mongoose').connect(process.env.MONGODB_URI).then(() => console.log('Connected')).catch(console.error)"

# Check connection string format
echo $MONGODB_URI
```

#### 3. Log Files Not Created
```bash
# Check directory permissions
ls -la logs/

# Check disk space
df -h

# Manually create logs directory
mkdir -p logs
```

### Debug Mode (Emergency)
If you need to enable debug logging temporarily:

```bash
# Set environment variable
export NODE_ENV=development

# Restart server
npm run dev-debug
```

## Backup and Recovery

### Database Backup
```bash
# MongoDB backup
mongodump --uri="your-mongodb-uri" --out=backup/

# Restore from backup
mongorestore --uri="your-mongodb-uri" backup/
```

### Log Backup
```bash
# Archive old logs
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/

# Clean up old log files
find logs/ -name "*.log" -mtime +30 -delete
```

## Scaling Considerations

### Horizontal Scaling
- Use load balancer for multiple instances
- Configure session sharing or stateless design
- Use external MongoDB cluster

### Vertical Scaling
- Increase server resources
- Optimize database queries
- Implement caching strategies

## Security Best Practices

### 1. Environment Variables
- Never commit secrets to version control
- Use secure secret management
- Rotate secrets regularly

### 2. Network Security
- Use HTTPS only in production
- Configure proper CORS settings
- Implement rate limiting

### 3. Data Protection
- Encrypt sensitive data at rest
- Use secure file upload validation
- Implement proper access controls

## Support and Maintenance

### Regular Maintenance Tasks
- [ ] Monitor log files daily
- [ ] Check database performance weekly
- [ ] Review security logs monthly
- [ ] Update dependencies quarterly
- [ ] Test backup and recovery procedures

### Emergency Contacts
- Database Administrator: [Contact Info]
- System Administrator: [Contact Info]
- Security Team: [Contact Info]

---

**Last Updated**: July 16, 2025
**Version**: 1.0.0 