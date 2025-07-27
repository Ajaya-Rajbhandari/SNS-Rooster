# Gmail Email Service Setup Guide

## Overview
The SNS Rooster backend uses Gmail for sending emails. This guide will help you set up Gmail credentials for the email service.

## Prerequisites
- A Gmail account
- 2-Factor Authentication enabled on your Gmail account

## Step 1: Enable 2-Factor Authentication
1. Go to your Google Account settings: https://myaccount.google.com/
2. Navigate to "Security"
3. Enable "2-Step Verification" if not already enabled

## Step 2: Generate App Password
1. Go to your Google Account settings: https://myaccount.google.com/
2. Navigate to "Security"
3. Find "App passwords" (only visible if 2-Factor Authentication is enabled)
4. Click "App passwords"
5. Select "Mail" as the app and "Other" as the device
6. Click "Generate"
7. Copy the generated 16-character password

## Step 3: Set Environment Variables
Add the following environment variables to your `.env` file:

```env
# Email Configuration
EMAIL_PROVIDER=gmail
EMAIL_FROM=your-email@gmail.com
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-16-character-app-password
```

## Step 4: Test Configuration
Run the email service test to verify the configuration:

```bash
node test-email-service.js
```

## Important Notes
- **Never use your regular Gmail password** - Always use an App Password
- **Keep your App Password secure** - Don't commit it to version control
- **App Passwords are 16 characters** - They don't have spaces or special formatting
- **One App Password per app** - Generate a new one for each application

## Troubleshooting

### "Invalid credentials" error
- Make sure you're using an App Password, not your regular password
- Verify that 2-Factor Authentication is enabled
- Check that the Gmail address is correct

### "Less secure app access" error
- App Passwords bypass this restriction
- Make sure you're using the App Password correctly

### "Authentication failed" error
- Regenerate the App Password
- Make sure the email address matches exactly

## Security Best Practices
1. Use different App Passwords for different environments (dev, staging, prod)
2. Rotate App Passwords regularly
3. Monitor your Gmail account for suspicious activity
4. Use environment variables, never hardcode credentials

## Production Deployment
For production deployment on Render:
1. Add the environment variables in your Render dashboard
2. Set `EMAIL_PROVIDER=gmail`
3. Set `GMAIL_USER` to your Gmail address
4. Set `GMAIL_APP_PASSWORD` to your App Password
5. Set `EMAIL_FROM` to your Gmail address

## Testing
After setup, test the email service:
```bash
# Test locally
node test-email-service.js

# Test production
node test-production-email.js
```

The email service should now work correctly with Gmail! 