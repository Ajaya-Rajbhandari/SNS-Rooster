const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Import models
const User = require('../models/User');

async function resetAdminPassword() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the specific user
    const user = await User.findOne({ email: 'admin@cityexpress.com.au' });
    
    if (!user) {
      console.log('❌ User admin@cityexpress.com.au not found');
      return;
    }

    console.log(`Found user: ${user.email}`);
    console.log(`Current role: ${user.role}`);
    console.log(`Company ID: ${user.companyId}`);
    console.log(`Is active: ${user.isActive}`);

    // Hash the password manually (bypassing the pre-save middleware)
    const salt = await bcrypt.genSalt(10);
    const defaultPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'Admin123!';
    const hashedPassword = await bcrypt.hash(defaultPassword, salt);
    
    // Update the password directly in the database to avoid double hashing
    await User.updateOne(
      { _id: user._id },
      { 
        password: hashedPassword,
        isActive: true 
      }
    );
    
    console.log('✅ Password reset successfully!');
    console.log('New password: Admin123!');
    console.log('User is now active');

    // Test password verification using the model method
    const updatedUser = await User.findById(user._id);
    const defaultPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'Admin123!';
    const isPasswordValid = await updatedUser.comparePassword(defaultPassword);
    console.log(`Password verification test: ${isPasswordValid ? '✅ PASS' : '❌ FAIL'}`);

  } catch (error) {
    console.error('Error resetting password:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
resetAdminPassword(); 