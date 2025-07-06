# Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up Firebase Cloud Messaging for push notifications in your SNS Rooster app.

## Prerequisites

1. Firebase project already set up (you have `google-services.json`)
2. Node.js and npm installed
3. Flutter SDK installed

## Step 1: Install Dependencies

### Frontend (Flutter)
```bash
cd sns_rooster
flutter pub get
```

### Backend (Node.js)
```bash
cd rooster-backend
npm install
```

## Step 2: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **Service Accounts**
4. Click **Generate new private key**
5. Download the JSON file and save it as `serviceAccountKey.json` in the `rooster-backend` directory

## Step 3: Configure Firebase Admin SDK

### For Local Development
1. Place the `serviceAccountKey.json` file in the `rooster-backend` directory
2. The FCM controller will automatically detect and use the local file

### For Cloud Deployment (Recommended)
1. Run the setup script to get the environment variable format:
   ```bash
   cd rooster-backend
   node scripts/setup-firebase-env.js
   ```

2. Copy the `FIREBASE_SERVICE_ACCOUNT` value from the script output

3. Set it as an environment variable in your cloud platform:
   - **Render**: Go to your service → Environment → Add Environment Variable
   - **Heroku**: `heroku config:set FIREBASE_SERVICE_ACCOUNT="..."`
   - **Railway**: Add it in the Variables tab
   - **Vercel**: Add it in the Environment Variables section

4. The FCM controller will automatically use the environment variable in production

## Step 4: iOS Setup (if needed)

If you plan to support iOS:

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your iOS project:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into the Runner folder
   - Make sure it's added to the Runner target

## Step 5: Test the Setup

### 1. Start the Backend
```bash
cd rooster-backend
npm start
```

### 2. Run the Flutter App
```bash
cd sns_rooster
flutter run
```

### 3. Check FCM Token
- Open the app and log in
- Check the console logs for FCM token
- The token should be automatically saved to the backend

## Step 6: Send Test Notifications

### Using Firebase Console
1. Go to Firebase Console > **Messaging**
2. Click **Send your first message**
3. Enter notification details
4. Select your app as the target
5. Send the message

### Using Backend API
```bash
# Send notification to specific user
curl -X POST http://localhost:5000/api/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "userId": "USER_ID",
    "title": "Test Notification",
    "body": "This is a test notification",
    "data": {
      "type": "attendance",
      "screen": "attendance"
    }
  }'

# Send notification to topic
curl -X POST http://localhost:5000/api/send-topic-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "topic": "all_users",
    "title": "General Announcement",
    "body": "This is a general announcement",
    "data": {
      "type": "announcement"
    }
  }'
```

## Step 7: Notification Types

The app supports different notification types:

### 1. Attendance Notifications
- Clock in/out reminders
- Break time notifications
- Overtime alerts

### 2. Leave Notifications
- Leave request approvals/rejections
- Leave balance updates
- Holiday reminders

### 3. Payroll Notifications
- Payroll processing updates
- Tax document availability
- Salary notifications

### 4. Admin Notifications
- Employee attendance alerts
- Leave request notifications
- System maintenance alerts

## Step 8: Topic Subscriptions

Users are automatically subscribed to topics based on their role:

- **All users**: `all_users`
- **Admins**: `admins`
- **Employees**: `employees`

## Step 9: Customization

### Notification Icons
- Android: Update `android/app/src/main/res/mipmap-*` icons
- iOS: Update app icons in Xcode

### Notification Sounds
- Android: Place sound files in `android/app/src/main/res/raw/`
- iOS: Add sound files to the Xcode project

### Notification Colors
- Android: Update `android/app/src/main/res/values/colors.xml`
- iOS: Update notification appearance in Xcode

## Troubleshooting

### Common Issues

1. **FCM Token Not Generated**
   - Check Firebase configuration
   - Ensure `google-services.json` is properly placed
   - Check internet connectivity

2. **Notifications Not Received**
   - Verify FCM token is saved to backend
   - Check notification permissions
   - Ensure app is not in battery optimization mode

3. **Backend Errors**
   - Check Firebase Admin SDK configuration
   - Verify service account key file
   - Check MongoDB connection

4. **iOS Specific Issues**
   - Ensure `GoogleService-Info.plist` is added to Xcode project
   - Check notification permissions in iOS Settings
   - Verify APNs certificate

### Debug Commands

```bash
# Check FCM token in Flutter app
flutter logs | grep "FCM"

# Check backend FCM logs
cd rooster-backend
npm start

# Test FCM token endpoint
curl -X GET http://localhost:5000/api/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Security Considerations

1. **Service Account Key**: Keep `serviceAccountKey.json` secure and never commit it to version control
2. **FCM Tokens**: Tokens are stored securely in the database
3. **API Access**: FCM endpoints require authentication
4. **Topic Access**: Users can only subscribe to appropriate topics

## Production Deployment

1. **Environment Variables**: Set up production Firebase project
2. **Service Account**: Use production service account key
3. **Database**: Ensure MongoDB is properly configured
4. **SSL**: Use HTTPS for all API calls
5. **Monitoring**: Set up Firebase Analytics and Crashlytics

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Firebase Console logs
3. Check Flutter and backend console logs
4. Verify all configuration files are properly set up

## Next Steps

After setup is complete:

1. Test notifications on different devices
2. Implement notification preferences
3. Add notification history
4. Set up automated notifications (attendance reminders, etc.)
5. Implement notification analytics 