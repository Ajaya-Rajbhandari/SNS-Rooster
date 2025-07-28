const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Connect to MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Import User model
const User = require('../models/User');

async function setNewPassword() {
  try {
    // Find super admin user
    const superAdmin = await User.findOne({ 
      email: 'superadmin@snstechservices.com.au',
      role: 'super_admin'
    });

    if (!superAdmin) {
      console.log('❌ Super admin user not found');
      return;
    }

    console.log('✅ Found super admin user:', superAdmin.email);

    // Set a completely new password
    const newPassword = 'Admin@123';
    
    // Hash the new password with 10 salt rounds
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update the password
    superAdmin.password = hashedPassword;
    superAdmin.passwordChangedAt = new Date();
    await superAdmin.save();

    console.log('✅ Password set successfully!');
    console.log('📧 Email:', superAdmin.email);
    console.log('🔑 New Password:', newPassword);
    console.log('⏰ Password changed at:', superAdmin.passwordChangedAt);

    // Test the password immediately
    const isPasswordValid = await superAdmin.comparePassword(newPassword);
    console.log('🔍 Password test result:', isPasswordValid ? '✅ Valid' : '❌ Invalid');

    // Test with bcrypt directly
    const directTest = await bcrypt.compare(newPassword, hashedPassword);
    console.log('🔍 Direct bcrypt test:', directTest ? '✅ Valid' : '❌ Invalid');

  } catch (error) {
    console.error('❌ Error setting password:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the script
setNewPassword(); 