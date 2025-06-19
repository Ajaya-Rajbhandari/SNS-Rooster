const mongoose = require('mongoose');
const User = require('../models/User');
const bcrypt = require('bcrypt');

// Connect to MongoDB
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
mongoose.connect(MONGODB_URI)
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

async function debugLogin() {
  try {
    const email = 'admin@snsrooster.com';
    const password = 'Admin@123';
    
    console.log('\n=== DEBUG LOGIN FLOW ===');
    console.log('Email:', email);
    console.log('Password:', password);
    
    // Step 1: Find user
    console.log('\n1. Finding user...');
    const user = await User.findOne({ email });
    if (!user) {
      console.log('❌ User not found');
      return;
    }
    console.log('✅ User found:', user.email);
    console.log('   User ID:', user._id);
    console.log('   User role:', user.role);
    console.log('   User active:', user.isActive);
    console.log('   Stored hash:', user.password);
    
    // Step 2: Check if active
    console.log('\n2. Checking if user is active...');
    if (!user.isActive) {
      console.log('❌ User is not active');
      return;
    }
    console.log('✅ User is active');
    
    // Step 3: Compare password
    console.log('\n3. Comparing password...');
    console.log('   Input password:', password);
    console.log('   Stored hash:', user.password);
    
    // Test with bcrypt directly
    const directMatch = await bcrypt.compare(password, user.password);
    console.log('   Direct bcrypt.compare result:', directMatch);
    
    // Test with user method
    const userMethodMatch = await user.comparePassword(password);
    console.log('   user.comparePassword result:', userMethodMatch);
    
    if (directMatch && userMethodMatch) {
      console.log('\n✅ PASSWORD MATCHES');
    } else {
      console.log('\n❌ PASSWORD DOES NOT MATCH');
    }
    
    // Step 4: Test JWT generation
    console.log('\n4. Testing JWT generation...');
    const jwt = require('jsonwebtoken');
    const token = jwt.sign(
      { 
        userId: user._id,
        email: user.email,
        role: user.role, 
        isProfileComplete: user.isProfileComplete
      },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '24h' }
    );
    console.log('✅ JWT generated successfully');
    console.log('   Token length:', token.length);
    
    console.log('\n✅ LOGIN SHOULD SUCCEED');
    
  } catch (error) {
    console.error('❌ Error during debug:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

debugLogin();