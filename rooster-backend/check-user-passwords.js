const mongoose = require('mongoose');
const User = require('./models/User');
const Company = require('./models/Company');

// MongoDB connection
const MONGODB_URI = 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';

async function checkUserPasswords() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all admin users
    const adminUsers = await User.find({ role: 'admin' }).populate('companyId');
    console.log('\n👑 Admin Users:');
    
    adminUsers.forEach((user, index) => {
      console.log(`${index + 1}. Email: ${user.email}`);
      console.log(`   Company: ${user.companyId?.name || 'None'}`);
      console.log(`   Password Hash: ${user.password.substring(0, 20)}...`);
      console.log(`   Is Profile Complete: ${user.isProfileComplete}`);
      console.log(`   Is Email Verified: ${user.isEmailVerified}`);
      console.log('');
    });

    // Check if there are any users with simple passwords
    const simplePasswordUsers = await User.find({
      $or: [
        { password: 'admin123' },
        { password: 'password' },
        { password: '123456' },
        { password: 'admin' }
      ]
    });

    if (simplePasswordUsers.length > 0) {
      console.log('🔍 Users with simple passwords:');
      simplePasswordUsers.forEach(user => {
        console.log(`   ${user.email}: ${user.password}`);
      });
    } else {
      console.log('🔍 No users found with simple passwords');
    }

    // Check for users with bcrypt hashed passwords
    const bcryptUsers = await User.find({
      password: { $regex: /^\$2[aby]\$/ }
    });

    console.log(`\n🔐 Users with bcrypt hashed passwords: ${bcryptUsers.length}`);
    bcryptUsers.forEach(user => {
      console.log(`   ${user.email}: ${user.password.substring(0, 20)}...`);
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

checkUserPasswords(); 