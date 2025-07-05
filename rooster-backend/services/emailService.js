const nodemailer = require('nodemailer');
const path = require('path');
const fs = require('fs');
let Resend = null;
try {
  Resend = require('resend').Resend;
} catch (e) {
  // Resend SDK not installed
}

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
          this.transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
              user: process.env.GMAIL_USER,
              pass: process.env.GMAIL_APP_PASSWORD, // Use app password, not regular password
            },
          });
          break;
          
        case 'sendgrid':
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
          
        default: // Custom SMTP
          this.transporter = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
              user: process.env.SMTP_USER,
              pass: process.env.SMTP_PASSWORD,
            },
          });
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
    const fromEmail = process.env.FROM_EMAIL || 'noreply@yourcompany.com';
    const fromName = process.env.FROM_NAME || 'SNS Rooster HR';
    
    const mailOptions = {
      from: `"${fromName}" <${fromEmail}>`,
      to: to,
      subject: subject,
      html: htmlContent,
      text: textContent || this.htmlToText(htmlContent),
    };

    try {
      if (this.resend) {
        console.log('DEBUG: Using Resend to send email');
        // Use Resend SDK
        const result = await this.resend.emails.send({
          from: fromEmail,
          to,
          subject,
          html: htmlContent,
          text: mailOptions.text,
        });
        console.log(`✅ [Resend] Email sent to ${to}: ${subject}`);
        return result;
      } else if (this.transporter) {
        console.log('DEBUG: Using transporter to send email');
        const result = await this.transporter.sendMail(mailOptions);
        console.log(`✅ Email sent to ${to}: ${subject}`);
        return result;
      } else {
        console.log('DEBUG: Logging email to console (dev mode)');
        // Development fallback - log email to console
        console.log('\n📧 === EMAIL (Development Mode) ===');
        console.log(`To: ${to}`);
        console.log(`Subject: ${subject}`);
        console.log(`Content: ${textContent || this.htmlToText(htmlContent)}`);
        console.log('=================================\n');
        return { messageId: 'dev-mode-' + Date.now() };
      }
    } catch (error) {
      console.error('❌ Email sending failed:', error);
      throw new Error(`Failed to send email: ${error.message}`);
    }
  }

  // Email verification
  async sendVerificationEmail(user, verificationToken) {
    const verificationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/verify-email?token=${verificationToken}`;
    
    const subject = 'Verify Your Email Address - SNS Rooster HR';
    const htmlContent = this.getEmailVerificationTemplate(user, verificationUrl);
    
    return this.sendEmail(user.email, subject, htmlContent);
  }

  // Password reset
  async sendPasswordResetEmail(user, resetToken) {
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
    
    const subject = 'Password Reset Request - SNS Rooster HR';
    const htmlContent = this.getPasswordResetTemplate(user, resetUrl);
    
    return this.sendEmail(user.email, subject, htmlContent);
  }

  // Welcome email for new employees
  async sendWelcomeEmail(user, tempPassword = null) {
    const loginUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/login`;
    
    const subject = 'Welcome to SNS Rooster HR System';
    const htmlContent = this.getWelcomeTemplate(user, loginUrl, tempPassword);
    
    return this.sendEmail(user.email, subject, htmlContent);
  }

  // Account locked notification
  async sendAccountLockedEmail(user) {
    const subject = 'Account Temporarily Locked - SNS Rooster HR';
    const htmlContent = this.getAccountLockedTemplate(user);
    
    return this.sendEmail(user.email, subject, htmlContent);
  }

  // Notify admin of user password reset request
  async sendAdminForgotPasswordNotification(user) {
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@yourcompany.com';
    const subject = `Password Reset Requested for ${user.email}`;
    const htmlContent = `<p>User <strong>${user.email}</strong> has requested a password reset.</p><p>Please log in to the admin panel to reset their password and notify them of the new credentials.</p>`;
    return this.sendEmail(adminEmail, subject, htmlContent);
  }

  // Email Templates
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
                <h2>Hello ${user.firstName},</h2>
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
                <p>© 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
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
                <h2>Hello ${user.firstName},</h2>
                <p>We received a request to reset your password for your SNS Rooster HR account.</p>
                
                <div class="warning">
                    <strong>Security Notice:</strong> If you didn't request this password reset, please ignore this email and contact your administrator immediately.
                </div>
                
                <p>Click the button below to reset your password:</p>
                <a href="${resetUrl}" class="button">Reset Password</a>
                
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; color: #FF9800;">${resetUrl}</p>
                
                <p><strong>This link will expire in 1 hour for security reasons.</strong></p>
                
                <p>After clicking the link, you'll be able to create a new password for your account.</p>
            </div>
            <div class="footer">
                <p>© 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
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
            .button { display: inline-block; padding: 12px 30px; background: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
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
                <h2>Hello ${user.firstName},</h2>
                <p>Welcome to the SNS Rooster HR System! Your account has been successfully created by your administrator.</p>
                
                ${tempPassword ? `
                <div class="credentials">
                    <h3>Your Login Credentials:</h3>
                    <p><strong>Email:</strong> ${user.email}</p>
                    <p><strong>Temporary Password:</strong> ${tempPassword}</p>
                    <p><em>Please change your password after first login for security.</em></p>
                </div>
                ` : ''}
                
                <p>Before you can access the system, please verify your email address and complete your profile.</p>
                
                <a href="${loginUrl}" class="button">Access HR System</a>
                
                <h3>What's Next?</h3>
                <ol>
                    <li>Verify your email address (check for a separate verification email)</li>
                    <li>Log in to the system</li>
                    <li>Complete your employee profile</li>
                    <li>Set up your preferences</li>
                </ol>
                
                <p>If you have any questions, please contact your HR administrator.</p>
            </div>
            <div class="footer">
                <p>© 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
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
                <h1>Account Temporarily Locked</h1>
            </div>
            <div class="content">
                <h2>Hello ${user.firstName},</h2>
                
                <div class="warning">
                    <strong>Security Alert:</strong> Your account has been temporarily locked due to multiple failed login attempts.
                </div>
                
                <p>For your account security, we've temporarily locked your SNS Rooster HR account after detecting several unsuccessful login attempts.</p>
                
                <p><strong>Your account will be automatically unlocked in 2 hours.</strong></p>
                
                <h3>What to do:</h3>
                <ul>
                    <li>Wait 2 hours and try logging in again</li>
                    <li>Make sure you're using the correct password</li>
                    <li>If you've forgotten your password, use the "Forgot Password" feature</li>
                    <li>Contact your administrator if you believe this was an error</li>
                </ul>
                
                <p>If you didn't attempt to log in, please contact your administrator immediately as this could indicate unauthorized access attempts.</p>
            </div>
            <div class="footer">
                <p>© 2024 SNS Rooster HR System. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  // Utility function to convert HTML to plain text
  htmlToText(html) {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .trim();
  }
}

module.exports = new EmailService(); 