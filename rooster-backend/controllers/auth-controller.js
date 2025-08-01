const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const Employee = require('../models/Employee');
const emailService = require('../services/emailService');

exports.login = async (req, res) => {
  try {
    const { email, password, companyId } = req.body;

    // DEBUG LOGGING START
    console.log('--- LOGIN DEBUG ---');
    console.log('Login attempt:', { email, password, companyId });
    
    // If companyId is provided, find user within that company
    let user;
    if (companyId) {
      user = await User.findOne({ email, companyId });
      console.log('User found in company:', !!user);
    } else {
      user = await User.findOne({ email });
      console.log('User found (no company filter):', !!user);
    }
    
    if (user) {
      console.log('DB hash:', user.password);
      const isMatch = await user.comparePassword(password);
      console.log('Password match:', isMatch);
    }
    // DEBUG LOGGING END

    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (user.isLocked) {
      try {
        await emailService.sendAccountLockedEmail(user);
      } catch (emailError) {
        console.error('Failed to send account locked email:', emailError);
      }
      
      return res.status(401).json({ 
        message: 'Account is temporarily locked due to too many failed login attempts. Please try again later or contact support.',
        accountLocked: true,
        lockUntil: user.accountLockedUntil
      });
    }

    if (!user.isActive) {
      return res.status(401).json({ message: 'Account is deactivated' });
    }

    if (process.env.NODE_ENV === 'production' && !user.isEmailVerified) {
      return res.status(401).json({ 
        message: 'Please verify your email address before logging in. Check your email for verification instructions.',
        emailNotVerified: true
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      await user.incrementLoginAttempts();
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    await user.resetLoginAttempts();
    
    user.lastLogin = new Date();
    await user.save();

    if (!process.env.JWT_SECRET) {
      console.error('ERROR: JWT_SECRET is not defined in environment variables');
      return res.status(500).json({ message: 'Server configuration error: Missing JWT_SECRET' });
    }

    try {
      const token = jwt.sign(
        {
          userId: user._id,
          email: user.email,
          role: user.role,
          companyId: user.companyId,
          isProfileComplete: user.isProfileComplete,
          isEmailVerified: user.isEmailVerified
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      res.json({
        token,
        user: user.getPublicProfile()
      });
    } catch (error) {
      console.error('Error during token generation:', error);
      res.status(500).json({ message: 'Server error during token generation' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.register = async (req, res) => {
  console.log('DEBUG: /api/auth/register endpoint hit');
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can register new users' });
    }

    const { email, password, firstName, lastName, role, department, position, sendWelcomeEmail = true } = req.body;

    const existingUser = await User.findOne({ email, companyId: req.companyId });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered in this company' });
    }

    const tempPassword = password || crypto.randomBytes(8).toString('hex');

    const isDev = process.env.NODE_ENV !== 'production';
    const user = new User({
      email,
      password: tempPassword,
      firstName,
      lastName,
      role: role || 'employee',
      department,
      position,
      companyId: req.companyId,
      isProfileComplete: false,
      isEmailVerified: isDev ? true : false, // Auto-verify in dev, require in prod
      avatar: 'https://storage.googleapis.com/sns-rooster-8cca5.firebasestorage.app/avatars/default-avatar.png',
      profilePicture: 'https://storage.googleapis.com/sns-rooster-8cca5.firebasestorage.app/avatars/default-avatar.png'
    });

    await user.save();

    const verificationToken = user.generateEmailVerificationToken();
    await user.save();

    try {
      if (sendWelcomeEmail) {
        await emailService.sendWelcomeEmail(user, tempPassword);
      }
      
      await emailService.sendVerificationEmail(user, verificationToken);
      
      console.log(`✅ User registered and emails sent to ${email}`);
    } catch (emailError) {
      console.error('Email sending failed:', emailError);
    }

    res.status(201).json({
      message: 'User registered successfully. Verification email sent.',
      user: user.getPublicProfile(),
      requiresEmailVerification: true,
      tempPassword: process.env.NODE_ENV === 'development' ? (!password ? tempPassword : undefined) : undefined
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({ message: 'Verification token is required' });
    }

    const user = await User.findOne({
      emailVerificationToken: token,
      emailVerificationExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ 
        message: 'Invalid or expired verification token. Please request a new verification email.',
        expired: true
      });
    }

    await user.verifyEmail();

    res.json({ 
      message: 'Email verified successfully! You can now log in to your account.',
      verified: true
    });
  } catch (error) {
    console.error('Email verification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.resendVerificationEmail = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.json({ message: 'If your email is registered, you will receive verification instructions.' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    const verificationToken = user.generateEmailVerificationToken();
    await user.save();

    try {
      await emailService.sendVerificationEmail(user, verificationToken);
      console.log(`✅ Verification email resent to ${email}`);
    } catch (emailError) {
      console.error('Failed to resend verification email:', emailError);
      return res.status(500).json({ message: 'Failed to send verification email' });
    }

    res.json({ 
      message: 'Verification email sent successfully. Please check your inbox.',
      sent: true
    });
  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.requestPasswordReset = async (req, res) => {
  console.log('DEBUG: /api/auth/reset-password endpoint hit');
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.json({ message: 'If your email is registered, you will receive a reset code.' });
    }

    if (!user.canRequestPasswordReset()) {
      return res.status(429).json({ 
        message: 'Too many password reset attempts. Please wait one hour before trying again.',
        rateLimited: true
      });
    }

    await user.incrementPasswordResetAttempts();

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = Date.now() + 3600000;
    await user.save();

    try {
      await emailService.sendPasswordResetEmail(user, resetToken);
      console.log(`✅ Password reset email sent to ${email}`);
    } catch (emailError) {
      console.error('Failed to send password reset email:', emailError);
      return res.status(500).json({ message: 'Failed to send password reset email' });
    }

    res.json({
      message: 'Password reset instructions sent to your email',
      resetToken: process.env.NODE_ENV === 'development' ? resetToken : undefined
    });
  } catch (error) {
    console.error('Password reset request error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    
    if (!token || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Token and new password are required.' 
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ 
        success: false, 
        message: 'Password must be at least 8 characters long.' 
      });
    }

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid or expired reset token.' 
      });
    }

    // Update user password (pre-save middleware will hash it)
    user.password = newPassword;
    user.passwordChangedAt = new Date();
    
    // Clear reset token fields
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    user.resetPasswordAttempts = 0;
    user.resetPasswordLastAttempt = undefined;
    
    await user.save();

    // Log password reset for security
    console.log(`Password reset for user: ${user.email} (${user.role}) at ${new Date().toISOString()}`);

    res.json({ 
      success: true, 
      message: 'Password has been reset successfully. You can now log in with your new password.' 
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'An error occurred while resetting your password. Please try again.' 
    });
  }
};

exports.getCurrentUserProfile = async (req, res) => {
  try {
    console.log('!!! /auth/me endpoint hit !!!', req.user ? req.user.userId : 'NO USER');
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Enrich with employee position/department if needed
    let extraFields = {};
    try {
      const empRecord = await Employee.findOne({ userId: user._id });
      console.log('EMP RECORD for user', user._id, ':', empRecord);
      if (empRecord) {
        if (!user.position && empRecord.position) user.position = empRecord.position;
        if (!user.department && empRecord.department) user.department = empRecord.department;
        // Add employment type/subtype to extraFields for response
        extraFields.employeeType = empRecord.employeeType;
        extraFields.employeeSubType = empRecord.employeeSubType;
      }
    } catch (err) {
      console.error('Warning: Failed to enrich user profile with employee info:', err);
    }

    // Merge extraFields into the public profile response
    const publicProfile = { ...user.getPublicProfile(), ...extraFields };
    res.json({ profile: publicProfile });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateCurrentUserProfile = async (req, res) => {
  try {
    console.log('PATCH /me request body:', req.body);
    const updates = Object.keys(req.body);
    const allowedUpdates = [
      'firstName', 'lastName', 'email', 'department', 'position', 'phone', 'address', 'dateOfBirth', 'gender', 'profilePicture', 'password',
      'education', 'certificates', 'emergencyContact', 'emergencyPhone', 'emergencyRelationship',
      'currentPassword'
    ];
    const isValidOperation = updates.every((update) => allowedUpdates.includes(update));

    if (!isValidOperation) {
      return res.status(400).json({ message: 'Invalid updates!' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Handle password change separately to ensure hashing
    if (req.body.password) {
      // 1. Require currentPassword
      if (!req.body.currentPassword) {
        return res.status(400).json({ message: 'Current password is required to change your password.' });
      }
      // 2. Check current password
      const isMatch = await user.comparePassword(req.body.currentPassword);
      if (!isMatch) {
        return res.status(400).json({ message: 'Current password is incorrect.' });
      }
      // 3. Prevent using the same password
      const isSame = await user.comparePassword(req.body.password);
      if (isSame) {
        return res.status(400).json({ message: 'New password must be different from the current password.' });
      }
      // 4. Password policy (example: min 6 chars)
      if (req.body.password.length < 6) {
        return res.status(400).json({ message: 'New password must be at least 6 characters long.' });
      }
      user.password = req.body.password; // Mongoose pre-save hook will hash this
      delete req.body.password; // Remove from body to avoid direct assignment
      delete req.body.currentPassword;
    }

    // Handle profile picture upload
    if (req.file) {
      console.log('UPLOAD DEBUG: req.file =', req.file);
      const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
      // Use req.file.filename if available, fallback to req.file.path
      const filename = req.file.filename || (req.file.path ? req.file.path.split('/').pop() : '');
      const publicUrl = `https://storage.googleapis.com/${bucketName}/${filename}`;
      console.log('Avatar public URL:', publicUrl);
      user.profilePicture = publicUrl;
      user.avatar = publicUrl;
    }

    // --- BEGIN: Ensure education/certificates document fields are mapped correctly ---
    if (req.body.education && Array.isArray(req.body.education)) {
      req.body.education = req.body.education.map((edu, idx) => {
        // If a document was uploaded for this education entry, ensure it is mapped to 'certificate'
        if (edu.uploadedFilePath) {
          edu.certificate = edu.uploadedFilePath;
          delete edu.uploadedFilePath;
        }
        return edu;
      });
    }
    if (req.body.certificates && Array.isArray(req.body.certificates)) {
      req.body.certificates = req.body.certificates.map((cert, idx) => {
        // If a document was uploaded for this certificate entry, ensure it is mapped to 'document'
        if (cert.uploadedFilePath) {
          cert.document = cert.uploadedFilePath;
          delete cert.uploadedFilePath;
        }
        return cert;
      });
    }
    // --- END: Ensure education/certificates document fields are mapped correctly ---

    // Sanity check: ensure avatar/profilePicture never include '/api/uploads/'
    if (user.avatar && user.avatar.startsWith('/api/uploads/')) {
      user.avatar = user.avatar.replace('/api/uploads/', '/uploads/');
    }
    if (user.profilePicture && user.profilePicture.startsWith('/api/uploads/')) {
      user.profilePicture = user.profilePicture.replace('/api/uploads/', '/uploads/');
    }

    updates.forEach((update) => {
      if (update !== 'password' && update !== 'profilePicture') {
        user[update] = req.body[update];
      }
    });

    // Map frontend field to backend schema if needed
    if (req.body.emergencyContactRelationship && !req.body.emergencyRelationship) {
      req.body.emergencyRelationship = req.body.emergencyContactRelationship;
      delete req.body.emergencyContactRelationship;
    }

    // Recalculate profile completeness after updates
    await user.recalculateProfileComplete();

    await user.save();

    // If profile is now complete, clear related notifications
    if (user.isProfileComplete) {
      const Notification = require('../models/Notification');
      const fullName = `${user.firstName} ${user.lastName}`.trim();

      // Remove any previous incomplete notifications for this user (self or admin notices)
      await Notification.deleteMany({ user: user._id, title: 'Incomplete Profile' });
      await Notification.deleteMany({
        role: 'admin',
        title: 'Incomplete Employee Profile',
        message: { $regex: new RegExp(`^${fullName} has not completed their profile\.?$`, 'i') }
      });

      // Create a new notification for admins about completion (avoid duplicates)
      const existing = await Notification.findOne({
        role: 'admin',
        title: 'Employee Profile Completed',
        message: `${fullName} has completed their profile.`
      });
      if (!existing) {
        await Notification.create({
          role: 'admin',
          title: 'Employee Profile Completed',
          message: `${fullName} has completed their profile.`,
          type: 'info',
          link: `/admin/employees/${user._id}`
        });
      }
    }

    // Fetch the updated user from the database to ensure fresh data is returned
    const updatedUser = await User.findById(user._id);
    res.json({ profile: updatedUser.getPublicProfile() });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateUserProfileByAdmin = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can update user profiles' });
    }

    const { id } = req.params;
    const updates = Object.keys(req.body);
    const allowedUpdates = [
      'firstName', 'lastName', 'email', 'role', 'department', 'position', 'isActive', 'phoneNumber', 'address', 'dateOfBirth', 'gender', 'profilePicture', 'password',
      'education', 'certificates'
    ];
    const isValidOperation = updates.every((update) => allowedUpdates.includes(update));

    if (!isValidOperation) {
      return res.status(400).json({ message: 'Invalid updates!' });
    }

    const user = await User.findOne({ _id: id, companyId: req.companyId });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Handle password change separately to ensure hashing
    if (req.body.password) {
      user.password = req.body.password; // Mongoose pre-save hook will hash this
      delete req.body.password; // Remove from body to avoid direct assignment
    }

    // Handle profile picture upload (if admin is updating it)
    if (req.file) {
      const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
      const filename = req.file.filename || (req.file.path ? req.file.path.split('/').pop() : '');
      const publicUrl = `https://storage.googleapis.com/${bucketName}/${filename}`;
      console.log('Admin avatar public URL:', publicUrl);
      user.profilePicture = publicUrl;
      user.avatar = publicUrl;
    }

    // Sanity check: ensure avatar/profilePicture never include '/api/uploads/'
    if (user.avatar && user.avatar.startsWith('/api/uploads/')) {
      user.avatar = user.avatar.replace('/api/uploads/', '/uploads/');
    }
    if (user.profilePicture && user.profilePicture.startsWith('/api/uploads/')) {
      user.profilePicture = user.profilePicture.replace('/api/uploads/', '/uploads/');
    }

    updates.forEach((update) => {
      if (update !== 'password' && update !== 'profilePicture') {
        user[update] = req.body[update];
      }
    });

    // Recalculate profile completeness after updates
    await user.recalculateProfileComplete();

    await user.save();

    // --- Sync Employee record ---
    const employee = await Employee.findOne({ userId: user._id, companyId: req.companyId });
    if (employee) {
      // Only update fields that exist in Employee schema
      const employeeFields = ['firstName', 'lastName', 'email', 'department', 'position', 'address'];
      employeeFields.forEach(field => {
        if (req.body[field] !== undefined) {
          employee[field] = req.body[field];
        }
      });
      await employee.save();
    }
    // --- End sync ---

    // If profile is now complete, clear related notifications
    if (user.isProfileComplete) {
      const Notification = require('../models/Notification');
      const fullName = `${user.firstName} ${user.lastName}`.trim();

      // Remove any previous incomplete notifications for this user (self or admin notices)
      await Notification.deleteMany({ user: user._id, title: 'Incomplete Profile' });
      await Notification.deleteMany({
        role: 'admin',
        title: 'Incomplete Employee Profile',
        message: { $regex: new RegExp(`^${fullName} has not completed their profile\.?$`, 'i') }
      });

      // Create a new notification for admins about completion (avoid duplicates)
      const existing = await Notification.findOne({
        role: 'admin',
        title: 'Employee Profile Completed',
        message: `${fullName} has completed their profile.`
      });
      if (!existing) {
        await Notification.create({
          role: 'admin',
          title: 'Employee Profile Completed',
          message: `${fullName} has completed their profile.`,
          type: 'info',
          link: `/admin/employees/${user._id}`
        });
      }
    }

    res.json({ message: 'User profile updated successfully', user: user.getPublicProfile() });
  } catch (error) {
    console.error('Admin update user profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can view all users' });
    }
    const showInactive = req.query.showInactive === 'true';
    const filter = showInactive ? { companyId: req.companyId } : { isActive: true, companyId: req.companyId };
    const users = await User.find(filter, '-password'); // Exclude password
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can view user by ID' });
    }
    const user = await User.findOne({ _id: req.params.id, companyId: req.companyId }).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Attempt to enrich with position & department from Employee collection
    try {
      const empRecord = await Employee.findOne({ userId: user._id, companyId: req.companyId });
      if (empRecord) {
        if (!user.position && empRecord.position) user.position = empRecord.position;
        if (!user.department && empRecord.department) user.department = empRecord.department;
      }
    } catch (err) {
      console.error('Warning: Failed to enrich user profile with employee info:', err);
    }

    res.json({ profile: user.getPublicProfile() });
  } catch (error) {
    console.error('Get user by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    // Prevent self-deletion for admins
    if (req.user.userId === req.params.id) {
      const self = await User.findById(req.user.userId);
      if (self && self.role === 'admin') {
        return res.status(400).json({ message: 'You cannot delete your own admin account.' });
      }
    }

    // Check if the user to delete is an admin
    const userToDelete = await User.findOne({ _id: req.params.id, companyId: req.companyId });
    if (!userToDelete) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (userToDelete.role === 'admin') {
      const adminCount = await User.countDocuments({ role: 'admin', companyId: req.companyId });
      if (adminCount <= 1) {
        return res.status(400).json({ message: 'At least one admin must remain in this company.' });
      }
    }

    // Cascade delete: Remove Employee and Attendance records for this user
    const Employee = require('../models/Employee');
    const Attendance = require('../models/Attendance');
    await Employee.deleteOne({ userId: userToDelete._id, companyId: req.companyId });
    await Attendance.deleteMany({ user: userToDelete._id, companyId: req.companyId });

    await User.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'User, employee, and attendance records deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.uploadDocument = async (req, res) => {
  try {
    console.log('Document upload request received');
    console.log('Request body:', req.body);
    console.log('Request file:', req.file);
    
    let { documentType } = req.body;
    documentType = (documentType || '').toLowerCase().trim();
    const userId = req.user.userId;

    console.log('Document type:', documentType);
    console.log('User ID:', userId);

    if (!req.file) {
      console.log('No file uploaded');
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const user = await User.findById(userId);
    if (!user) {
      console.log('User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    if (req.user.role !== 'admin' && req.user.userId !== userId) {
      console.log('Unauthorized upload attempt');
      return res.status(403).json({ message: 'Unauthorized to upload document' });
    }

    console.log('File object:', req.file);
    console.log('File object keys:', Object.keys(req.file));
    console.log('File path:', req.file.path);
    console.log('File filename:', req.file.filename);
    console.log('File originalname:', req.file.originalname);
    console.log('File mimetype:', req.file.mimetype);
    console.log('File size:', req.file.size);
    
    // For GCS uploads, construct the public URL like the working avatar upload
    const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
    const filename = req.file.filename || (req.file.path ? req.file.path.split('/').pop() : '');
    const filePath = `https://storage.googleapis.com/${bucketName}/${filename}`;
    console.log('Final file path:', filePath);

    // Remove all previous documents of the same type (no need to delete local files)
    user.documents = user.documents || [];
    user.documents = user.documents.filter(doc => doc.type !== documentType);
    // Add the new document
    user.documents.push({ type: documentType, path: filePath });

    console.log('Saving user with documents:', user.documents);
    await user.save();

    // Notify admins about new document upload (for verification)
    try {
      if (req.user.role !== 'admin') {
        const Notification = require('../models/Notification');
        const fullName = `${user.firstName} ${user.lastName}`.trim();
        const existing = await Notification.findOne({
          role: 'admin',
          title: 'Document Uploaded',
          message: { $regex: new RegExp(`^${fullName} uploaded`, 'i') }
        });
        if (!existing) {
          await Notification.create({
            role: 'admin',
            title: 'Document Uploaded',
            message: `${fullName} uploaded ${documentType} for verification.`,
            type: 'action',
            link: `/admin/employees/${user._id}`,
          });
        }
      }
    } catch (nErr) {
      console.error('Failed to create admin notification for document upload:', nErr);
    }

    res.status(200).json({
      message: 'Document uploaded successfully',
      documentInfo: {
        fileName: req.file.originalname,
        filePath,
      },
    });
  } catch (error) {
    console.error('Document upload error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.debugCreateUser = async (req, res) => {
  try {
    const { email, password, firstName, lastName, role, department, position, companyId } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    if (!firstName || !lastName) {
      return res.status(400).json({ message: 'First name and last name are required' });
    }

    // Validate companyId is provided for non-super_admin users
    if (role !== 'super_admin' && !companyId) {
      return res.status(400).json({ message: 'Company ID is required for non-super-admin users' });
    }

    const user = new User({
      email,
      password,
      firstName,
      lastName,
      role: role || 'employee',
      department,
      position,
      companyId: role === 'super_admin' ? undefined : companyId, // Only set companyId for non-super_admin users
      isActive: true,
      isProfileComplete: false,
    });

    await user.save();

    res.status(201).json({
      message: 'User created successfully',
      user: user.getPublicProfile(),
    });
  } catch (error) {
    console.error('Debug create user error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.toggleUserActive = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can update user status' });
    }
    const user = await User.findOne({ _id: req.params.id, companyId: req.companyId });
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (typeof req.body.isActive !== 'boolean') {
      return res.status(400).json({ message: 'isActive must be a boolean' });
    }
    user.isActive = req.body.isActive;
    await user.save();
    // Sync Employee record if exists
    const employee = await Employee.findOne({ userId: user._id, companyId: req.companyId });
    if (employee) {
      employee.isActive = req.body.isActive;
      await employee.save();
    }
    res.json({ message: 'User status updated', user: user.getPublicProfile() });
  } catch (err) {
    console.error('toggleUserActive error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email address is required' 
      });
    }

    const user = await User.findOne({ email });
    
    // For security reasons, don't reveal if the email exists or not
    if (!user) {
      return res.json({ 
        success: true, 
        message: "If your email is registered, you will receive a reset link." 
      });
    }

    // Check if user is super admin (for admin portal)
    if (user.role === 'super_admin') {
      // Generate a 6-digit numeric code (same as regular users)
      const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
      user.resetPasswordToken = resetCode;
      user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
      await user.save();

      // Send password reset code to super admin
      try {
        await emailService.sendPasswordResetCode(user, resetCode);
        console.log(`Password reset code sent to super admin: ${email}`);
      } catch (emailError) {
        console.error('Failed to send super admin password reset code:', emailError);
        return res.status(500).json({ 
          success: false, 
          message: 'Failed to send reset code. Please try again later.' 
        });
      }

      return res.json({ 
        success: true, 
        message: "If your email is registered, you will receive a reset code." 
      });
    } else {
      // For regular users, use the existing code-based reset
      const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
      user.resetPasswordToken = resetCode;
      user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
      await user.save();

      try {
        await emailService.sendPasswordResetCode(user, resetCode);
      } catch (emailError) {
        console.error('Failed to send password reset code:', emailError);
        return res.status(500).json({ 
          success: false, 
          message: 'Failed to send reset code. Please try again later.' 
        });
      }

      return res.json({ 
        success: true, 
        message: "If your email is registered, you will receive a reset code." 
      });
    }
  } catch (error) {
    console.error('Forgot password error:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'An error occurred. Please try again later.' 
    });
  }
};

exports.validateToken = async (req, res) => {
  try {
    // If we reach here, the token is valid (authenticateToken middleware passed)
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(401).json({ valid: false, message: 'User not found' });
    }

    if (!user.isActive) {
      return res.status(401).json({ valid: false, message: 'User account is deactivated' });
    }

    res.json({
      valid: true,
      user: user.getPublicProfile()
    });
  } catch (error) {
    console.error('Token validation error:', error);
    res.status(500).json({ valid: false, message: 'Server error' });
  }
};

exports.validateResetToken = async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({ valid: false, message: 'Reset token is required' });
    }

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.json({ valid: false, message: 'Reset token is invalid or has expired' });
    }

    res.json({ valid: true, message: 'Reset token is valid' });
  } catch (error) {
    console.error('Reset token validation error:', error);
    res.status(500).json({ valid: false, message: 'Server error' });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword, confirmPassword } = req.body;
    const userId = req.user.userId;

    // DEBUG LOGGING
    console.log('=== CHANGE PASSWORD DEBUG ===');
    console.log('Request body:', { currentPassword: !!currentPassword, newPassword: !!newPassword, confirmPassword: !!confirmPassword });
    console.log('New password length:', newPassword?.length);
    console.log('New password:', newPassword);
    console.log('Confirm password:', confirmPassword);
    console.log('Passwords match:', newPassword === confirmPassword);

    // Validate input
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Current password and new password are required' 
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ 
        success: false, 
        message: 'New password must be at least 8 characters long' 
      });
    }

    // Find user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({ 
        success: false, 
        message: 'Current password is incorrect' 
      });
    }

    // Check if new password is same as current
    const isNewPasswordSame = await bcrypt.compare(newPassword, user.password);
    if (isNewPasswordSame) {
      return res.status(400).json({ 
        success: false, 
        message: 'New password must be different from current password' 
      });
    }

    // Hash new password (use 10 salt rounds to match existing)
    const saltRounds = 10;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    user.password = hashedNewPassword;
    user.passwordChangedAt = new Date();
    await user.save();

    // DEBUG: Test the saved password
    console.log('Password saved successfully');
    console.log('New hash:', hashedNewPassword);
    const testResult = await bcrypt.compare(newPassword, hashedNewPassword);
    console.log('Test saved password:', testResult);

    // Log password change for security
    console.log(`Password changed for user: ${user.email} (${user.role}) at ${new Date().toISOString()}`);

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Internal server error' 
    });
  }
};