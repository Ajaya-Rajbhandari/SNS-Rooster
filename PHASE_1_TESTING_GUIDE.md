# 🧪 PHASE 1 TESTING GUIDE

## 📋 Overview

This guide provides comprehensive testing instructions for the Phase 1 security and infrastructure improvements implemented in the SNS Rooster system.

**Testing Options:**
1. **Automated Tests** - Comprehensive test suite
2. **Manual Tests** - Step-by-step verification
3. **Quick Tests** - Basic functionality checks

---

## 🚀 AUTOMATED TESTING

### Option 1: Full Test Suite (Recommended)

This will start the server and run all tests automatically:

```bash
cd rooster-backend
npm run test-phase1-full
```

### Option 2: Tests Only (Server must be running)

If you already have the server running:

```bash
cd rooster-backend
npm run test-phase1
```

### What the Automated Tests Cover:

1. **Environment Variables** - Validates required environment variables
2. **Health Endpoints** - Tests all health check endpoints
3. **Security Headers** - Verifies security headers are present
4. **Rate Limiting** - Tests API rate limiting functionality
5. **Input Validation** - Tests input validation on endpoints
6. **Error Tracking** - Verifies error tracking system
7. **Performance Tracking** - Tests performance monitoring
8. **Backup Script** - Validates backup script existence
9. **Security Middleware** - Tests security middleware integration
10. **CORS Configuration** - Tests CORS settings

---

## 🔧 MANUAL TESTING

### Prerequisites

1. **Start the server:**
   ```bash
   cd rooster-backend
   npm run dev
   ```

2. **Ensure MongoDB is running**

3. **Set up environment variables** (if not already done)

### Test 1: Health Check Endpoints

#### 1.1 Basic Health Check
```bash
curl http://localhost:5000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-XX...",
  "uptime": 123,
  "database": {
    "status": "connected",
    "readyState": 1
  },
  "memory": {
    "rss": 45,
    "heapUsed": 23,
    "heapTotal": 34,
    "external": 12
  },
  "environment": "development",
  "version": "1.0.0"
}
```

#### 1.2 Detailed Health Check
```bash
curl http://localhost:5000/health/detailed
```

**Expected Response:** Should include database, errorTracking, performance, and errors sections.

#### 1.3 Performance Metrics
```bash
curl http://localhost:5000/health/performance
```

**Expected Response:** Should show performance data for API endpoints.

#### 1.4 Error Summary
```bash
curl http://localhost:5000/health/errors
```

**Expected Response:** Should show error tracking summary.

### Test 2: Security Headers

```bash
curl -I http://localhost:5000/health
```

**Expected Headers:**
- `Content-Security-Policy` - Should be present
- `X-Frame-Options` - Should be present
- `X-Content-Type-Options` - Should be present
- `X-XSS-Protection` - Should be present

### Test 3: Rate Limiting

#### 3.1 General API Rate Limiting
```bash
# Make 105 requests quickly
for i in {1..105}; do
  curl http://localhost:5000/health
done
```

**Expected Result:** Some requests should return 429 (Too Many Requests)

#### 3.2 Authentication Rate Limiting
```bash
# Make 10 login attempts quickly
for i in {1..10}; do
  curl -X POST http://localhost:5000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"wrongpassword"}'
done
```

**Expected Result:** Some requests should return 429 (Too Many Requests)

### Test 4: Input Validation

#### 4.1 Invalid Email Format
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid-email","password":"password123"}'
```

**Expected Response:** 400 Bad Request with validation error

#### 4.2 Weak Password
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "password": "weak",
    "role": "employee"
  }'
```

**Expected Response:** 400 Bad Request with password strength error

#### 4.3 Invalid Role
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "password": "StrongPass123!",
    "role": "invalid_role"
  }'
```

**Expected Response:** 400 Bad Request with role validation error

### Test 5: Error Tracking

#### 5.1 Generate Errors
```bash
# Generate some errors
curl http://localhost:5000/api/nonexistent-endpoint
curl -X POST http://localhost:5000/api/auth/login -d '{}'
curl http://localhost:5000/api/auth/users
```

#### 5.2 Check Error Tracking
```bash
curl http://localhost:5000/health/errors
```

**Expected Response:** Should show error summary with recent errors

#### 5.3 Check Error Log Files
```bash
ls -la rooster-backend/logs/errors/
```

**Expected Result:** Should see error log files

### Test 6: Performance Tracking

#### 6.1 Generate Performance Data
```bash
# Make several requests
for i in {1..10}; do
  curl http://localhost:5000/health
  curl http://localhost:5000/health/memory
  sleep 0.1
done
```

#### 6.2 Check Performance Data
```bash
curl http://localhost:5000/health/performance
```

**Expected Response:** Should show performance metrics for endpoints

### Test 7: Database Backup

#### 7.1 Test Backup Script
```bash
cd rooster-backend
npm run backup
```

**Expected Result:** Should create a backup file in the `backups` directory

#### 7.2 Check Backup Directory
```bash
ls -la rooster-backend/backups/
```

**Expected Result:** Should see backup files and log files

---

## 🔍 QUICK TESTS

### Quick Health Check
```bash
curl http://localhost:5000/health | jq '.status'
```

**Expected:** `"healthy"`

### Quick Security Headers Check
```bash
curl -I http://localhost:5000/health | grep -E "(Content-Security-Policy|X-Frame-Options)"
```

**Expected:** Should show security headers

### Quick Rate Limiting Check
```bash
# Make 5 quick requests
for i in {1..5}; do curl http://localhost:5000/health; done
```

**Expected:** All should succeed (within rate limit)

---

## 📊 TEST RESULTS INTERPRETATION

### ✅ All Tests Passed
- Phase 1 implementation is working correctly
- System is ready for production
- Proceed to Phase 2 implementation

### ⚠️ Some Tests Failed
- Review failed tests
- Check server logs for errors
- Verify environment variables
- Fix issues and re-run tests

### ❌ Many Tests Failed
- Check server startup
- Verify MongoDB connection
- Check environment configuration
- Review implementation

---

## 🐛 TROUBLESHOOTING

### Common Issues:

#### 1. Server Won't Start
```bash
# Check environment variables
echo $JWT_SECRET
echo $MONGODB_URI

# Check MongoDB connection
mongo $MONGODB_URI --eval "db.runCommand('ping')"
```

#### 2. Tests Fail with Connection Errors
```bash
# Check if server is running
curl http://localhost:5000/health

# Check server logs
tail -f rooster-backend/logs/app.log
```

#### 3. Rate Limiting Not Working
```bash
# Check if rate limiting middleware is loaded
curl -I http://localhost:5000/health | grep -i "x-ratelimit"
```

#### 4. Security Headers Missing
```bash
# Check if helmet is configured
curl -I http://localhost:5000/health | grep -E "(Content-Security-Policy|X-Frame-Options)"
```

#### 5. Error Tracking Not Working
```bash
# Check error log directory
ls -la rooster-backend/logs/errors/

# Check error tracking endpoint
curl http://localhost:5000/health/errors
```

---

## 📋 TEST CHECKLIST

### Before Testing:
- [ ] Server is running
- [ ] MongoDB is connected
- [ ] Environment variables are set
- [ ] No other processes using port 5000

### During Testing:
- [ ] Health endpoints respond correctly
- [ ] Security headers are present
- [ ] Rate limiting works
- [ ] Input validation works
- [ ] Error tracking works
- [ ] Performance tracking works
- [ ] Backup script works

### After Testing:
- [ ] All tests passed
- [ ] No critical errors in logs
- [ ] System is stable
- [ ] Ready for Phase 2

---

## 🎯 SUCCESS CRITERIA

### Minimum Success Rate: 90%
- At least 9 out of 10 test categories should pass
- Critical tests (security, health checks) must pass
- Non-critical tests can have minor issues

### Critical Tests (Must Pass):
- Environment Variables
- Basic Health Check
- Security Headers
- Rate Limiting
- Input Validation

### Non-Critical Tests (Can Fail):
- Performance Tracking (if no requests made)
- Error Tracking (if no errors generated)
- Backup Script (if MongoDB tools not installed)

---

**Next Steps:** After successful testing, proceed to Phase 2 implementation. 