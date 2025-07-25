# 📧 Email Service Setup Guide

## **Overview**
The SNS Rooster system uses a configurable email service for sending password reset emails, notifications, and other important communications. This guide will help you set up email functionality.

## **Current Issue**
The email service is currently not configured, which is why you're seeing the error:
```
Cannot read properties of null (reading 'sendMail')
```

## **Quick Fix for Development**

### **Option 1: Development Mode (Recommended for Testing)**
The system will automatically log emails to the console in development mode. No configuration needed!

```bash
# Just start the server - emails will be logged to console
npm start
```

### **Option 2: Configure Real Email Service**

## **Email Provider Options**

### **1. Gmail (Recommended for Testing)**

#### **Setup Steps:**
1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password:**
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. **Set Environment Variables:**

```bash
# .env file
EMAIL_PROVIDER=gmail
EMAIL_FROM=your-gmail@gmail.com
GMAIL_USER=your-gmail@gmail.com
GMAIL_APP_PASSWORD=your-16-digit-app-password
```

### **2. SMTP (Generic)**

#### **Setup Steps:**
```bash
# .env file
EMAIL_PROVIDER=smtp
EMAIL_FROM=your-email@domain.com
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@domain.com
SMTP_PASS=your-password
SMTP_PORT=587
SMTP_SECURE=false
```

### **3. SendGrid**

#### **Setup Steps:**
1. Create SendGrid account
2. Generate API key
3. Set environment variables:

```bash
# .env file
EMAIL_PROVIDER=sendgrid
EMAIL_FROM=your-verified-sender@domain.com
SENDGRID_API_KEY=your-sendgrid-api-key
```

### **4. Mailgun**

#### **Setup Steps:**
```bash
# .env file
EMAIL_PROVIDER=mailgun
EMAIL_FROM=your-email@yourdomain.com
MAILGUN_SMTP_LOGIN=your-mailgun-login
MAILGUN_SMTP_PASSWORD=your-mailgun-password
```

### **5. Amazon SES**

#### **Setup Steps:**
```bash
# .env file
EMAIL_PROVIDER=ses
EMAIL_FROM=your-verified-email@domain.com
AWS_SES_ACCESS_KEY_ID=your-aws-access-key
AWS_SES_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
```

### **6. Outlook**

#### **Setup Steps:**
```bash
# .env file
EMAIL_PROVIDER=outlook
EMAIL_FROM=your-outlook@outlook.com
OUTLOOK_EMAIL=your-outlook@outlook.com
OUTLOOK_PASSWORD=your-outlook-password
```

## **Testing Email Configuration**

### **1. Test Script**
Run the test script to verify email configuration:

```bash
cd rooster-backend
node scripts/test-forgot-password.js
```

### **2. Manual Testing**
1. Start the backend server
2. Go to admin portal login page
3. Click "Forgot Password?"
4. Enter super admin email
5. Check console logs for email content

## **Environment Variables Reference**

### **Required Variables**
```bash
# Email Provider (choose one)
EMAIL_PROVIDER=smtp|gmail|sendgrid|mailgun|ses|outlook

# From Address
EMAIL_FROM=your-email@domain.com

# Admin Portal URL (for reset links)
ADMIN_PORTAL_URL=http://localhost:3001
```

### **Provider-Specific Variables**

#### **Gmail**
```bash
GMAIL_USER=your-gmail@gmail.com
GMAIL_APP_PASSWORD=your-16-digit-app-password
```

#### **SMTP**
```bash
SMTP_HOST=smtp.example.com
SMTP_USER=your-email@example.com
SMTP_PASS=your-password
SMTP_PORT=587
SMTP_SECURE=false
```

#### **SendGrid**
```bash
SENDGRID_API_KEY=your-sendgrid-api-key
```

#### **Mailgun**
```bash
MAILGUN_SMTP_LOGIN=your-mailgun-login
MAILGUN_SMTP_PASSWORD=your-mailgun-password
```

#### **Amazon SES**
```bash
AWS_SES_ACCESS_KEY_ID=your-aws-access-key
AWS_SES_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=us-east-1
```

#### **Outlook**
```bash
OUTLOOK_EMAIL=your-outlook@outlook.com
OUTLOOK_PASSWORD=your-outlook-password
```

## **Troubleshooting**

### **Common Issues**

#### **1. "Cannot read properties of null (reading 'sendMail')"**
- **Cause**: Email service not configured
- **Solution**: Set up environment variables or use development mode

#### **2. "Authentication failed"**
- **Cause**: Wrong credentials
- **Solution**: Check username/password, use app passwords for Gmail

#### **3. "Connection timeout"**
- **Cause**: Wrong SMTP settings
- **Solution**: Verify host, port, and security settings

#### **4. "Sender not verified" (SES)**
- **Cause**: Email not verified in SES
- **Solution**: Verify sender email in AWS SES console

### **Debug Steps**
1. Check environment variables are set correctly
2. Verify email provider credentials
3. Test with simple SMTP settings first
4. Check server logs for detailed error messages

## **Development vs Production**

### **Development Mode**
- Emails are logged to console
- No real email service needed
- Perfect for testing and development

### **Production Mode**
- Real email service required
- Set `NODE_ENV=production`
- Configure proper email provider

## **Security Considerations**

### **Best Practices**
1. **Use App Passwords** for Gmail (not regular passwords)
2. **Environment Variables** for sensitive data
3. **Verified Senders** for production services
4. **Rate Limiting** to prevent abuse
5. **Secure Connections** (TLS/SSL)

### **Email Content Security**
- No sensitive data in email content
- Secure reset links with expiration
- Professional branding and security notices

## **Quick Start for Testing**

### **Step 1: Development Mode (No Setup Required)**
```bash
cd rooster-backend
npm start
```
Emails will be logged to console automatically.

### **Step 2: Test Forgot Password**
1. Go to `http://localhost:3001/login`
2. Click "Forgot Password?"
3. Enter `superadmin@snstechservices.com.au`
4. Check console for email content

### **Step 3: Configure Real Email (Optional)**
Follow the provider-specific setup above.

---

## **✅ Next Steps**

1. **For Testing**: Use development mode (no setup needed)
2. **For Production**: Choose an email provider and configure environment variables
3. **Test**: Use the test script to verify configuration
4. **Monitor**: Check logs for email delivery status

**The forgot password feature will work in development mode immediately!** 🎉 