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
    const email = 'testuser@example.com';
    const password = 'Test@123';
    
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
    const methodMatch = await user.comparePassword(password);
    console.log('   user.comparePassword result:', methodMatch);
    
    if (!methodMatch) {
      console.log('❌ Password does not match');
      
      // Test with different variations
      console.log('\n   Testing password variations...');
      const variations = [
        'test@123',
        'TEST@123',
        'Test@123 ',
        ' Test@123',
        'Test@123\n',
        'Test@123\r'
      ];
      
      for (const variation of variations) {
        const varMatch = await bcrypt.compare(variation, user.password);
        console.log(`   "${variation}" (${variation.length} chars):`, varMatch);
      }
      return;
    }
    console.log('✅ Password matches');
    
    console.log('\n✅ LOGIN SHOULD SUCCEED');
    
  } catch (error) {
    console.error('❌ Error during debug:', error);
  } finally {
    mongoose.connection.close();
  }
}

debugLogin();