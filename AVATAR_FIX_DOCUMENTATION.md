# Avatar Display Fix Documentation

## Issue Description
User profile avatars were not displaying in the mobile app despite successful upload to the backend server. The avatar upload appeared to be stuck in a loading state, and uploaded files were being immediately deleted from the server.

## Root Causes Identified

### 1. File Deletion Issue (Backend)
The profile picture upload endpoint in `authRoutes.js` had incorrect logic ordering:
- The old avatar deletion code was placed **after** the new file was saved
- This caused the newly uploaded file to be immediately deleted
- The old avatar path variable was being overwritten before deletion

### 2. URL Construction Issue (Frontend)
The `UserAvatar` widget was constructing incorrect URLs for static files:
- Frontend was requesting: `http://192.168.1.72:5000/api/uploads/avatars/...`
- Backend serves static files at: `http://192.168.1.72:5000/uploads/avatars/...`
- The `/api` prefix was incorrectly included for static file requests

## Solutions Implemented

### Backend Fix (authRoutes.js)
```javascript
// BEFORE: Incorrect order
user.avatar = avatarUrl;
await user.save();
const oldAvatarPath = user.avatar ? path.join(__dirname, '../uploads/avatars', path.basename(user.avatar)) : null;

// AFTER: Correct order
const oldAvatarPath = user.avatar ? path.join(__dirname, '../uploads/avatars', path.basename(user.avatar)) : null;
user.avatar = avatarUrl;
await user.save();
```

**Changes Made:**
1. Store the old avatar path **before** updating the user record
2. Update the database with the new avatar path
3. Delete the old file **after** successful database update

### Frontend Fix (user_avatar.dart)
```dart
// BEFORE: Incorrect URL construction
final fullUrl = '${ApiConfig.baseUrl}$avatarUrl';

// AFTER: Correct URL construction for static files
final baseUrlWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
final fullUrl = '$baseUrlWithoutApi$avatarUrl';
```

**Changes Made:**
1. Remove `/api` prefix from base URL when constructing static file URLs
2. Ensure URLs match the backend's static file serving configuration

## Backend Static File Configuration
The backend correctly serves static files using:
```javascript
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
```

This serves files at `/uploads/avatars/...` without the `/api` prefix.

## Files Modified
1. `rooster-backend/routes/authRoutes.js` - Fixed file deletion logic
2. `sns_rooster/lib/widgets/user_avatar.dart` - Fixed URL construction

## Testing
- Backend server restarted to apply changes
- Avatar upload endpoint tested
- URL construction verified
- Static file serving confirmed working

## Result
User avatars now display correctly in the mobile app after upload, resolving both the loading state issue and the file deletion problem.