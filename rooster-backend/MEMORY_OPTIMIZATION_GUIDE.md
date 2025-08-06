# Memory Optimization Guide for SNS-Rooster Backend

## 🚨 Current Memory Issues Identified

Based on the analysis of your backend code and the Render memory limit warnings, here are the main causes of memory issues:

### 1. **Large Data Exports Without Streaming**
- **Problem**: Export functions load entire datasets into memory before sending responses
- **Impact**: Can cause 200MB+ responses (as seen in your bandwidth metrics)
- **Files Affected**: `analytics-controller.js`, `dataExport-controller.js`

### 2. **Buffer Creation for Large Files**
- **Problem**: Creating large buffers in memory for file downloads
- **Impact**: Memory spikes during report generation
- **Files Affected**: `analyticsRoutes.js`

### 3. **Inefficient Database Queries**
- **Problem**: Some routes don't use proper pagination or limits
- **Impact**: Loading too much data into memory at once
- **Files Affected**: `adminAttendanceRoutes.js`, `super-admin-controller.js`

### 4. **Memory-Intensive Logging**
- **Problem**: Error tracking service loads entire log files into memory
- **Impact**: Memory usage grows with log file size
- **Files Affected**: `errorTrackingService.js`

## ✅ Optimizations Implemented

### 1. **Memory Monitoring Middleware**
- Added real-time memory usage tracking
- Automatic warnings for high memory usage
- Response size limiting (50MB max)

### 2. **Streaming Data Exports**
- Implemented streaming for large CSV exports
- Batch processing to prevent memory spikes
- Memory-efficient data transformation

### 3. **Optimized Logging System**
- Streaming log writes instead of loading entire files
- Automatic log rotation (10MB limit)
- Efficient log file cleanup

### 4. **Response Size Limiting**
- 50MB response size limit
- Automatic detection of large responses
- Graceful error handling for oversized responses

## 🔧 How to Use the Memory Monitor

### Start Memory Monitoring
```bash
# Monitor every 30 seconds (default)
npm run memory-monitor

# Monitor every 30 seconds (explicit)
npm run memory-monitor-30s

# Monitor every 60 seconds
node scripts/memory-monitor.js 60
```

### Monitor Output Example
```
🔍 Starting memory monitor...
📊 Monitoring interval: 30 seconds

📈 Memory Usage (2025-01-06T12:00:00.000Z):
   RSS: 245 MB
   Heap Used: 180 MB
   Heap Total: 220 MB
   External: 15 MB
   Array Buffers: 5 MB

⚠️  WARNING: High heap usage: 180 MB
```

## 🚀 Additional Recommendations

### 1. **Database Query Optimization**
```javascript
// ❌ Bad: Loading all data
const users = await User.find({ companyId });

// ✅ Good: Using pagination and limits
const users = await User.find({ companyId })
  .limit(50)
  .skip((page - 1) * 50)
  .lean(); // Use lean() for better performance
```

### 2. **File Upload Limits**
```javascript
// Set reasonable file size limits
const upload = multer({
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});
```

### 3. **Response Caching**
```javascript
// Cache frequently accessed data
app.use('/api/analytics', cacheMiddleware(300), analyticsRoutes);
```

### 4. **Environment Variables for Render**
Add these to your Render environment variables:
```
NODE_OPTIONS=--max-old-space-size=512
NODE_ENV=production
```

## 📊 Monitoring Endpoints

### Memory Usage Endpoint
```
GET /health/memory
```
Returns current memory usage statistics.

### Performance Stats Endpoint
```
GET /api/performance/stats
```
Returns performance metrics including cache stats and memory usage.

## 🔍 Debugging Memory Issues

### 1. **Check Memory Usage**
```bash
# Check current memory usage
curl http://sns-rooster.onrender.com/health/memory
```

### 2. **Monitor Logs**
Look for these log messages:
- `MEMORY_WARNING`: High memory usage detected
- `RESPONSE_SIZE_WARNING`: Large response detected
- `MEMORY_CRITICAL`: Critical memory usage

### 3. **Use Memory Monitor**
```bash
npm run memory-monitor
```

## 🛠️ Render-Specific Optimizations

### 1. **Instance Type**
Consider upgrading to a larger instance type if memory issues persist:
- Free: 512MB RAM
- Starter: 1GB RAM
- Standard: 2GB RAM

### 2. **Environment Variables**
```
NODE_OPTIONS=--max-old-space-size=512
NODE_ENV=production
```

### 3. **Auto-Scaling**
Enable auto-scaling for traffic spikes:
- Min instances: 1
- Max instances: 3
- Scale up: CPU > 70% for 2 minutes
- Scale down: CPU < 30% for 5 minutes

## 📈 Performance Metrics to Monitor

### Memory Metrics
- Heap Used: Should stay under 400MB
- RSS: Should stay under 600MB
- External Memory: Should stay under 100MB

### Response Metrics
- Response Size: Should stay under 50MB
- Response Time: Should stay under 5 seconds
- Cache Hit Rate: Should be above 70%

### Database Metrics
- Query Execution Time: Should stay under 1 second
- Connection Pool Usage: Should stay under 80%
- Index Usage: Monitor slow queries

## 🚨 Emergency Actions

If memory issues persist:

1. **Immediate Actions**
   - Restart the application
   - Check for memory leaks with the monitor
   - Review recent logs for large responses

2. **Short-term Fixes**
   - Reduce response size limits
   - Implement more aggressive caching
   - Add more pagination to endpoints

3. **Long-term Solutions**
   - Upgrade Render instance
   - Implement database query optimization
   - Add CDN for static assets

## 📞 Support

If you continue to experience memory issues:
1. Run the memory monitor for 24 hours
2. Collect the generated report
3. Check Render logs for specific error patterns
4. Review the recommendations in the memory report

---

**Last Updated**: January 6, 2025
**Version**: 1.0 