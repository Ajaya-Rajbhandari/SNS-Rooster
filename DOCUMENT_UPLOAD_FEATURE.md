# Document Upload & Break Types Feature Documentation

## Overview
This document covers both the document upload feature and the break types/attendance improvements, including recent bug fixes and backend/frontend integration notes.

---

# Document Upload Feature Documentation

## Overview
The document upload feature allows users to upload and manage their identification documents (ID Card and Passport) through the profile screen. This feature includes file picking, validation, upload progress tracking, and visual feedback.

## Features Implemented

### 1. File Selection
- **Multiple Sources**: Users can select files from:
  - Camera (take a photo)
  - Gallery/File system
- **Supported Formats**: PDF, JPG, PNG
- **File Size Limit**: Maximum 5MB per file

### 2. Document Types
- **ID Card**: Government-issued identification card
- **Passport**: International travel document

### 3. Validation
- **File Type Validation**: Only PDF, JPG, and PNG files are accepted
- **File Size Validation**: Files larger than 5MB are rejected
- **Error Handling**: Clear error messages for validation failures

### 4. Upload Process
- **Progress Indication**: Loading spinner during upload
- **Success Feedback**: Visual confirmation when upload completes
- **Error Handling**: User-friendly error messages for upload failures

### 5. UI Components
- **Upload Buttons**: Dynamic buttons that change appearance based on upload status
- **Status Indicators**: Visual feedback showing uploaded documents
- **Document List**: Display of uploaded documents with metadata

## Technical Implementation

### Files Modified

#### 1. `profile_provider.dart`
- Added `uploadDocument()` method
- Handles HTTP multipart requests for file uploads
- Includes mock API simulation for development
- Error handling and response processing

#### 2. `profile_screen.dart`
- Implemented `_pickAndUploadDocument()` method
- Added UI helper methods:
  - `_buildDocumentUploadButton()`
  - `_buildDocumentStatusList()`
- Integrated file picker functionality
- Added validation logic
- Enhanced UI with upload status indicators

### Dependencies Used
- **image_picker**: For file selection from camera/gallery
- **http**: For API communication
- **Flutter Material**: For UI components

## API Integration

### Upload Endpoint
```
POST /api/upload-document
Content-Type: multipart/form-data

Parameters:
- file: The document file (PDF/JPG/PNG)
- documentType: 'idCard' or 'passport'
- userId: User identifier
```

### Response Format
```json
{
  "success": true,
  "message": "Document uploaded successfully",
  "data": {
    "fileName": "document.pdf",
    "uploadDate": "2024-01-15T10:30:00Z",
    "status": "uploaded",
    "fileUrl": "https://api.example.com/documents/123"
  }
}
```

## User Experience Flow

1. **Access**: User navigates to Profile screen
2. **Upload**: User taps "Upload ID Card" or "Upload Passport" button
3. **Selection**: System presents options: Camera or Gallery
4. **Validation**: File is validated for type and size
5. **Upload**: File is uploaded with progress indication
6. **Feedback**: Success/error message is displayed
7. **Status**: UI updates to show upload status

## Error Handling

### File Validation Errors
- **Invalid file type**: "Please select a PDF, JPG, or PNG file"
- **File too large**: "File size must be less than 5MB"
- **No file selected**: "Please select a file to upload"

### Upload Errors
- **Network issues**: "Upload failed. Please check your connection and try again"
- **Server errors**: "Server error occurred. Please try again later"
- **Authentication errors**: "Authentication failed. Please log in again"

## Security Considerations

1. **File Type Validation**: Only specific file types are allowed
2. **File Size Limits**: Prevents large file uploads
3. **Authentication**: Upload requires valid user session
4. **Server-side Validation**: Additional validation on the backend

## Future Enhancements

1. **Document Preview**: Allow users to preview uploaded documents
2. **Document Deletion**: Option to remove uploaded documents
3. **Multiple Files**: Support for multiple document uploads per type
4. **OCR Integration**: Automatic text extraction from documents
5. **Document Verification**: Integration with verification services
6. **Compression**: Automatic image compression for large files

## Testing

### Manual Testing Checklist
- [ ] Upload ID Card from camera
- [ ] Upload ID Card from gallery
- [ ] Upload Passport from camera
- [ ] Upload Passport from gallery
- [ ] Test file type validation (try uploading .txt file)
- [ ] Test file size validation (try uploading >5MB file)
- [ ] Test network error handling (disconnect internet)
- [ ] Verify UI updates after successful upload
- [ ] Check document status display

### Unit Tests (Recommended)
- File validation logic
- Upload method functionality
- Error handling scenarios
- UI state management

## Deployment Notes

1. **Backend API**: Ensure document upload endpoint is implemented
2. **File Storage**: Configure secure file storage solution
3. **Permissions**: Verify camera and storage permissions are configured
4. **Environment**: Update API endpoints for production

## Support

For technical issues or questions about this feature, please refer to:
- Code comments in the implementation files
- Flutter documentation for image_picker
- HTTP package documentation for file uploads

---

# Attendance and Break Types Debugging & Improvements

## Recent Fixes & Learnings (June 2025)

### 1. Break Types Fetching (Frontend)
- The break types API now expects a top-level JSON array, not an object with a `breakTypes` key.
- Flutter code updated to parse the response as a list:
  ```dart
  final List<dynamic> data = json.decode(response.body);
  return List<Map<String, dynamic>>.from(data);
  ```
- Added user-friendly error handling:
  - If the token is expired/invalid (401), the user sees a red snackbar and is redirected to login.
  - Other errors show a clear message.

### 2. Backend JWT & Role Handling
- The backend `auth.js` middleware now copies both `userId` and `role` from the decoded JWT to `req.user`:
  ```js
  req.user = { userId: decoded.userId, role: decoded.role };
  ```
- This ensures role-based access checks work for break types and other endpoints.

### 3. Debugging Lessons
- Always check the actual backend response structure before parsing in Flutter.
- Use debug prints to inspect API responses and catch mismatches early.
- Ensure backend and frontend JWT secret usage is consistent.

### 4. User Experience
- If no break types are available, the user is informed.
- If the session is expired, the user is prompted to log in again.

---

# Changelog (June 2025)
- Fixed: Break types fetch error due to response structure mismatch.
- Fixed: Backend role missing in `req.user` causing forbidden errors.
- Improved: User-friendly error handling for break type fetch failures.
- Documented: Lessons learned and best practices for future debugging.