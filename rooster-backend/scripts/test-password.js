const mongoose = require('mongoose');
const User = require('../models/User');

async function testPassword() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');
    
    const user = await User.findOne({ email: 'testuser@example.com' });
    if (!user) {
      console.log('User not found');
      return;
    }
    
    console.log('User found:', user.email);
    console.log('User active:', user.isActive);
    console.log('Stored password hash:', user.password);
    
    // Test the password
    const testPassword = 'Test@123';
    console.log('Testing password:', testPassword);
    
    const isMatch = await user.comparePassword(testPassword);
    console.log('Password match:', isMatch);
    
    // Also test with the old password
    const oldPassword = 'password123';
    console.log('Testing old password:', oldPassword);
    const isOldMatch = await user.comparePassword(oldPassword);
    console.log('Old password match:', isOldMatch);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

testPassword();