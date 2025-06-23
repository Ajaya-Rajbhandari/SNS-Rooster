const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (!user.isActive) {
      return res.status(401).json({ message: 'Account is deactivated' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    user.lastLogin = new Date();
    await user.save();

    console.log('DEBUG: Starting token generation');
    console.log('DEBUG: User data for token:', {
      userId: user._id,
      email: user.email,
      role: user.role,
      isProfileComplete: user.isProfileComplete
    });
    console.log('DEBUG: JWT_SECRET during token generation:', process.env.JWT_SECRET);
    console.log('DEBUG: User data passed to jwt.sign:', {
      userId: user._id,
      email: user.email,
      role: user.role,
      isProfileComplete: user.isProfileComplete
    });

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
          isProfileComplete: user.isProfileComplete
        },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      console.log('DEBUG: Token generated successfully:', token);
      res.json({
        token,
        user: user.getPublicProfile()
      });
    } catch (error) {
      console.error('DEBUG: Error during token generation:', error);
      res.status(500).json({ message: 'Server error during token generation' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.register = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can register new users' });
    }

    const { email, password, firstName, lastName, role, department, position } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const user = new User({
      email,
      password,
      firstName,
      lastName,
      role: role || 'employee',
      department,
      position,
      isProfileComplete: false
    });

    await user.save();

    res.status(201).json({
      message: 'User registered successfully',
      user: user.getPublicProfile()
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.requestPasswordReset = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });

    if (!user) {
      return res.json({ message: 'If your email is registered, you will receive password reset instructions' });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = Date.now() + 3600000;
    await user.save();

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
    const { token } = req.params;
    const { password } = req.body;

    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({ message: 'Password has been reset successfully' });
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getCurrentUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ user: user.getPublicProfile() });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateCurrentUserProfile = async (req, res) => {
  try {
    console.log('PATCH /me request body:', req.body);
    const updates = Object.keys(req.body);
    const allowedUpdates = ['firstName', 'lastName', 'email', 'department', 'position', 'phoneNumber', 'address', 'dateOfBirth', 'gender', 'profilePicture', 'password'];
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
      user.password = req.body.password; // Mongoose pre-save hook will hash this
      delete req.body.password; // Remove from body to avoid direct assignment
    }

    // Handle profile picture upload
    if (req.file) {
      const oldProfilePicture = user.profilePicture;
      user.profilePicture = `/uploads/avatars/${req.file.filename}`;
      // Delete old profile picture if it exists and is not the default
      if (oldProfilePicture && oldProfilePicture !== '/uploads/avatars/default-avatar.png') {
        const oldPath = path.join(__dirname, '..', oldProfilePicture);
        fs.unlink(oldPath, (err) => {
          if (err) console.error('Error deleting old profile picture:', err);
        });
      }
    }

    updates.forEach((update) => {
      if (update !== 'password' && update !== 'profilePicture') {
        user[update] = req.body[update];
      }
    });

    // Recalculate profile completeness after updates
    user.isProfileComplete = user.checkProfileCompleteness();

    await user.save();

    res.json({ message: 'Profile updated successfully', user: user.getPublicProfile() });
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
    const allowedUpdates = ['firstName', 'lastName', 'email', 'role', 'department', 'position', 'isActive', 'phoneNumber', 'address', 'dateOfBirth', 'gender', 'profilePicture', 'password'];
    const isValidOperation = updates.every((update) => allowedUpdates.includes(update));

    if (!isValidOperation) {
      return res.status(400).json({ message: 'Invalid updates!' });
    }

    const user = await User.findById(id);
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
      const oldProfilePicture = user.profilePicture;
      user.profilePicture = `/uploads/avatars/${req.file.filename}`;
      // Delete old profile picture if it exists and is not the default
      if (oldProfilePicture && oldProfilePicture !== '/uploads/avatars/default-avatar.png') {
        const oldPath = path.join(__dirname, '..', oldProfilePicture);
        fs.unlink(oldPath, (err) => {
          if (err) console.error('Error deleting old profile picture:', err);
        });
      }
    }

    updates.forEach((update) => {
      if (update !== 'password' && update !== 'profilePicture') {
        user[update] = req.body[update];
      }
    });

    // Recalculate profile completeness after updates
    user.isProfileComplete = user.checkProfileCompleteness();

    await user.save();

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
    const users = await User.find({}).select('-password'); // Exclude passwords
    res.json(users.map(user => user.getPublicProfile()));
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUserById = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can view user by ID' });
    }
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user.getPublicProfile());
  } catch (error) {
    console.error('Get user by ID error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can delete users' });
    }
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.uploadDocument = async (req, res) => {
  try {
    const { documentType } = req.body;
    const userId = req.user.userId;

    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (req.user.role !== 'admin' && req.user.userId !== userId) {
      return res.status(403).json({ message: 'Unauthorized to upload document' });
    }

    const filePath = `/uploads/documents/${req.file.filename}`;
    user.documents = user.documents || [];
    user.documents.push({ type: documentType, path: filePath });
    await user.save();

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
    const { email, password, firstName, lastName, role, department, position } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    if (!firstName || !lastName) {
      return res.status(400).json({ message: 'First name and last name are required' });
    }

    const user = new User({
      email,
      password,
      firstName,
      lastName,
      role: role || 'employee',
      department,
      position,
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