const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.resend = null;
    this.emailProvider = process.env.EMAIL_PROVIDER || 'smtp';
    this.initializeTransporter();
  }

  async initializeTransporter() {
    const emailProvider = this.emailProvider;
    try {
      switch (emailProvider.toLowerCase()) {
        case 'resend':
          if (!Resend) {
            throw new Error('Resend SDK not installed. Run `npm install resend`.');
          }
          if (!process.env.RESEND_API_KEY) {
            throw new Error('RESEND_API_KEY not set in environment.');
          }
          this.resend = new Resend(process.env.RESEND_API_KEY);
          this.transporter = null;
          console.log('✅ Email service initialized with Resend');
          break;
        case 'gmail':
          if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
            throw new Error('GMAIL_USER and GMAIL_APP_PASSWORD must be set for Gmail provider.');
          }
          this.transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
              user: process.env.GMAIL_USER,
              pass: process.env.GMAIL_APP_PASSWORD, // Use app password, not regular password
            },
          });
          break;
        case 'sendgrid':
          if (!process.env.SENDGRID_API_KEY) {
            throw new Error('SENDGRID_API_KEY must be set for SendGrid provider.');
          }
          this.transporter = nodemailer.createTransport({
            host: 'smtp.sendgrid.net',
            port: 587,
            secure: false,
            auth: {
              user: 'apikey',
              pass: process.env.SENDGRID_API_KEY,
            },
          });
          break;
        case 'mailgun':
          if (!process.env.MAILGUN_SMTP_LOGIN || !process.env.MAILGUN_SMTP_PASSWORD) {
            throw new Error('MAILGUN_SMTP_LOGIN and MAILGUN_SMTP_PASSWORD must be set for Mailgun provider.');
          }
          this.transporter = nodemailer.createTransport({
            host: 'smtp.mailgun.org',
            port: 587,
            secure: false,
            auth: {
              user: process.env.MAILGUN_SMTP_LOGIN,
              pass: process.env.MAILGUN_SMTP_PASSWORD,
            },
          });
          break;
        case 'ses': // Amazon SES
          if (!process.env.AWS_SES_ACCESS_KEY_ID || !process.env.AWS_SES_SECRET_ACCESS_KEY) {
            throw new Error('AWS_SES_ACCESS_KEY_ID and AWS_SES_SECRET_ACCESS_KEY must be set for SES provider.');
          }
          this.transporter = nodemailer.createTransport({
            host: `email-smtp.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com`,
            port: 587,
            secure: false,
            auth: {
              user: process.env.AWS_SES_ACCESS_KEY_ID,
              pass: process.env.AWS_SES_SECRET_ACCESS_KEY,
            },
          });
          break;
        case 'outlook':
          if (!process.env.OUTLOOK_EMAIL || !process.env.OUTLOOK_PASSWORD) {
            throw new Error('OUTLOOK_EMAIL and OUTLOOK_PASSWORD must be set for Outlook provider.');
          }
          this.transporter = nodemailer.createTransport({
            host: 'smtp-mail.outlook.com',
            port: 587,
            secure: false,
            auth: {
              user: process.env.OUTLOOK_EMAIL,
              pass: process.env.OUTLOOK_PASSWORD,
            },
          });
          break;
        case 'smtp':
          if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
            throw new Error('SMTP_HOST, SMTP_USER, and SMTP_PASS must be set for SMTP provider.');
          }
          this.transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT) : 587,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
              user: process.env.SMTP_USER,
              pass: process.env.SMTP_PASS,
            },
          });
          break;
        default:
          throw new Error(`Unknown EMAIL_PROVIDER: ${emailProvider}`);
      }
      // Verify connection
      if (this.transporter) {
        await this.transporter.verify();
        console.log(`✅ Email service initialized with ${emailProvider}`);
      }
    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      console.warn('📧 Emails will be logged to console in development mode');
      this.transporter = null;
    }
  }

  async sendEmail(to, subject, htmlContent, textContent = null) {
    const mailOptions = {
      from: process.env.EMAIL_FROM || 'SNS Rooster HR <no-reply@snsrooster.com>',
      to,
      subject,
      html: htmlContent,
      text: textContent || undefined,
    };
    return this.transporter.sendMail(mailOptions);
  }

  // Password reset
  async sendPasswordResetEmail(user, resetToken) {
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/#/reset-password?token=${resetToken}`;
    const subject = 'Password Reset Request - SNS Rooster HR';
    const htmlContent = this.getPasswordResetTemplate(user, resetUrl);
    return this.sendEmail(user.email, subject, htmlContent);
  }

  getPasswordResetTemplate(user, resetUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Password Reset</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #FF9800; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px 20px; background: #f9f9f9; }
            .button { display: inline-block; padding: 12px 30px; background: #FF9800; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Password Reset Request</h1>
            </div>
            <div class="content">
                <h2>Hello ${user.firstName || user.email},</h2>
                <p>We received a request to reset your password for your SNS Rooster HR account.</p>
                <div class="warning">
                    <strong>Security Notice:</strong> If you did not request this password reset, please ignore this email or contact support.
                </div>
                <p>Click the button below to reset your password:</p>
                <a href="${resetUrl}" class="button">Reset Password</a>
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #FF9800;">${resetUrl}</p>
                <p><strong>This link will expire in 1 hour for security reasons.</strong></p>
                <p>If you have any questions or did not request this, please contact support.</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  // Email verification
  async sendVerificationEmail(user, verificationToken) {
    const verificationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/#/verify-email?token=${verificationToken}`;
    const subject = 'Verify Your Email - SNS Rooster HR';
    const htmlContent = this.getEmailVerificationTemplate(user, verificationUrl);
    return this.sendEmail(user.email, subject, htmlContent);
  }

  getEmailVerificationTemplate(user, verificationUrl) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Email Verification</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2196F3; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px 20px; background: #f9f9f9; }
            .button { display: inline-block; padding: 12px 30px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Email Verification Required</h1>
            </div>
            <div class="content">
                <h2>Hello ${user.firstName || user.email},</h2>
                <p>Welcome to SNS Rooster HR System! To complete your account setup, please verify your email address.</p>
                <p><strong>Important:</strong> You must verify your email before you can log in to the system.</p>
                <p>Click the button below to verify your email address:</p>
                <a href="${verificationUrl}" class="button">Verify Email Address</a>
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #2196F3;">${verificationUrl}</p>
                <p><strong>This link will expire in 24 hours.</strong></p>
                <p>If you didn't create this account, please ignore this email.</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  // Welcome email
  async sendWelcomeEmail(user, tempPassword = null) {
    const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
    const subject = 'Welcome to SNS Rooster HR System';
    const htmlContent = this.getWelcomeTemplate(user, loginUrl, tempPassword);
    return this.sendEmail(user.email, subject, htmlContent);
  }

  getWelcomeTemplate(user, loginUrl, tempPassword) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Welcome to SNS Rooster HR</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px 20px; background: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            .credentials { background: #e8f5e8; border: 1px solid #4CAF50; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Welcome to SNS Rooster HR!</h1>
            </div>
            <div class="content">
                <h2>Hello ${user.firstName || user.email},</h2>
                <p>Welcome to the SNS Rooster HR System! Your account has been successfully created by your administrator.</p>
                <div class="credentials">
                    <h3>Your Login Credentials:</h3>
                    <p><strong>Email:</strong> ${user.email}</p>
                    <p><strong>Password:</strong> ${tempPassword || '[Set by admin]'}</p>
                    <p><em><strong>Important:</strong> Please change your password after your first login for security.</em></p>
                </div>
                <p><strong>Before you can access the system, you must verify your email address.</strong></p>
                <p>You will receive a separate email with a verification link. Please click the link in that email to verify your account. Once verified, you can log in and complete your profile.</p>
                <h3>What's Next?</h3>
                <ol>
                    <li>Check your inbox for a verification email and verify your email address</li>
                    <li>Log in to the system</li>
                    <li>Complete your employee profile</li>
                    <li>Set up your preferences</li>
                </ol>
                <p>If you have any questions, please contact support.</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  // Account locked notification
  async sendAccountLockedEmail(user) {
    const subject = 'Account Temporarily Locked - SNS Rooster HR';
    const htmlContent = this.getAccountLockedTemplate(user);
    return this.sendEmail(user.email, subject, htmlContent);
  }

  getAccountLockedTemplate(user) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Account Locked</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #f44336; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px 20px; background: #f9f9f9; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
            .warning { background: #ffebee; border: 1px solid #f44336; padding: 15px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Account Locked</h1>
            </div>
            <div class="content">
                <h2>Hello ${user.firstName || user.email},</h2>
                <div class="warning">
                    <strong>Your account has been temporarily locked due to too many failed login attempts.</strong>
                </div>
                <p>Please wait for the lockout period to expire or contact support if you need assistance.</p>
            </div>
            <div class="footer">
                <p>&copy; 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  // Send password reset code (not a link)
  async sendPasswordResetCode(user, code) {
    const subject = 'Your SNS Rooster HR Password Reset Code';
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="background: #FF9800; color: white; padding: 20px; text-align: center;">Password Reset Code</h2>
        <div style="padding: 30px 20px; background: #f9f9f9;">
          <p>Hello ${user.firstName || user.email},</p>
          <p>We received a request to reset your password for your SNS Rooster HR account.</p>
          <p style="font-size: 18px; margin: 24px 0;">Your password reset code is:</p>
          <div style="font-size: 32px; font-weight: bold; color: #FF9800; text-align: center; letter-spacing: 4px;">${code}</div>
          <p style="margin-top: 24px;">Enter this code in the app to set a new password. <strong>This code will expire in 1 hour.</strong></p>
          <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <strong>Security Notice:</strong> If you did not request this, please ignore this email or contact support.
          </div>
        </div>
        <div style="padding: 20px; text-align: center; color: #666; font-size: 12px;">
          &copy; 2024 SNS Rooster HR System. All rights reserved.
        </div>
      </div>
    `;
    return this.sendEmail(user.email, subject, htmlContent);
  }
}

module.exports = new EmailService(); 