const mongoose = require('mongoose');
const User = require('../models/User');

async function testAdminPassword() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');
    
    const user = await User.findOne({ email: 'admin@snsrooster.com' });
    if (!user) {
      console.log('Admin user not found');
      return;
    }
    
    console.log('Admin user found:', user.email);
    console.log('Admin active:', user.isActive);
    console.log('Admin role:', user.role);
    
    // Test the admin password
    const testPassword = 'Admin@123';
    console.log('Testing admin password:', testPassword);
    
    const isMatch = await user.comparePassword(testPassword);
    console.log('Admin password match:', isMatch);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

testAdminPassword();