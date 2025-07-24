# Troubleshooting Guide

## Common Issues and Solutions

### 1. TypeScript Compilation Errors

#### Grid Component Errors
**Problem**: `No overload matches this call` errors with Material-UI Grid components.

**Solution**: 
- We've replaced Grid components with CSS Grid using Box components
- This provides better compatibility across MUI versions
- The layout is now more reliable and responsive

#### Import Errors
**Problem**: Cannot find module or component.

**Solution**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### 2. Port Conflicts

#### Port Already in Use
**Problem**: `EADDRINUSE` error when starting the application.

**Solution**:
```powershell
# Find processes using the port
netstat -ano | findstr :3001

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

#### Multiple Applications on Same Port
**Problem**: Admin portal and Flutter web trying to use port 3000.

**Solution**:
- Admin portal is configured to use port 3001
- Flutter web uses port 3000
- Backend uses port 5000

### 3. API Connection Issues

#### CORS Errors
**Problem**: `Access to fetch at 'http://localhost:5000' from origin 'http://localhost:3001' has been blocked by CORS policy`

**Solution**:
- Ensure backend is running on port 5000
- Check that CORS is configured to allow `http://localhost:3001`
- Restart backend server after CORS changes

#### Network Errors
**Problem**: `Network Error` or `Failed to fetch`

**Solution**:
- Verify backend server is running
- Check API base URL in `src/config/api.ts`
- Ensure no firewall blocking localhost connections

### 4. Authentication Issues

#### Login Not Working
**Problem**: Login form submits but doesn't redirect.

**Solution**:
- Check browser console for errors
- Verify backend authentication endpoint is working
- Check localStorage for token storage

#### Token Expired
**Problem**: Getting 401 errors after some time.

**Solution**:
- The app automatically handles token refresh
- If issues persist, clear localStorage and login again

### 5. Build Issues

#### Build Fails
**Problem**: `npm run build` fails with errors.

**Solution**:
```bash
# Clear build cache
npm run build -- --reset-cache

# Check for TypeScript errors
npx tsc --noEmit
```

#### Development Server Won't Start
**Problem**: `npm start` fails to start.

**Solution**:
```bash
# Clear cache and reinstall
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### 6. Performance Issues

#### Slow Loading
**Problem**: Dashboard takes a long time to load.

**Solution**:
- Check network tab for slow API calls
- Verify backend response times
- Consider implementing loading states

#### Memory Leaks
**Problem**: Application becomes slower over time.

**Solution**:
- Check for proper cleanup in useEffect hooks
- Ensure event listeners are removed
- Monitor component re-renders

### 7. Browser Compatibility

#### Modern Browser Required
**Problem**: App doesn't work in older browsers.

**Solution**:
- Use Chrome, Firefox, Safari, or Edge (latest versions)
- Enable JavaScript
- Clear browser cache

#### Mobile Issues
**Problem**: Layout breaks on mobile devices.

**Solution**:
- Test responsive design
- Check viewport meta tag
- Verify CSS Grid fallbacks

### 8. Development Environment

#### Node.js Version
**Problem**: Incompatible Node.js version.

**Solution**:
- Use Node.js 18 or higher
- Check version: `node --version`
- Update if needed: Download from nodejs.org

#### Package Manager Issues
**Problem**: npm or yarn conflicts.

**Solution**:
```bash
# Clear npm cache
npm cache clean --force

# Use consistent package manager
# Stick with npm or yarn, don't mix
```

### 9. Database Issues

#### MongoDB Connection
**Problem**: Backend can't connect to database.

**Solution**:
- Ensure MongoDB is running
- Check connection string in backend .env
- Verify network connectivity

### 10. File System Issues

#### Permission Errors
**Problem**: Cannot create or modify files.

**Solution**:
- Run terminal as administrator
- Check folder permissions
- Ensure antivirus isn't blocking operations

## Getting Help

### Debug Steps
1. Check browser console for errors
2. Check terminal output for build errors
3. Verify all services are running
4. Test API endpoints directly
5. Clear cache and restart

### Logs to Check
- Browser console (F12)
- Terminal output
- Network tab in dev tools
- Backend server logs

### Contact Support
If issues persist:
1. Document the exact error message
2. Note the steps to reproduce
3. Include browser and OS information
4. Check if issue occurs in different browsers

## Quick Fixes

### Reset Everything
```bash
# Stop all processes
# Clear all caches
npm cache clean --force
rm -rf node_modules package-lock.json
npm install

# Restart backend
cd ../rooster-backend
npm run dev

# Restart admin portal
cd ../admin-portal
npm start
```

### Check All Services
```bash
# Backend should be on port 5000
curl http://localhost:5000

# Admin portal should be on port 3001
curl http://localhost:3001

# Flutter web should be on port 3000
curl http://localhost:3000
``` 