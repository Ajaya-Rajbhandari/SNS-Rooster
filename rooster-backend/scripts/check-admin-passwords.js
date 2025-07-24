const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');
const bcrypt = require('bcrypt');

async function checkAdminPasswords() {
  try {
    console.log('🔍 Checking admin user passwords...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get all admin users
    const adminUsers = await User.find({ role: 'admin' }).populate('companyId');
    console.log(`📋 Found ${adminUsers.length} admin users\n`);

    for (const admin of adminUsers) {
      console.log(`👤 **${admin.email}**`);
      console.log(`   Company: ${admin.companyId?.name || 'Unknown'}`);
      console.log(`   Name: ${admin.firstName} ${admin.lastName}`);
      console.log(`   Status: ${admin.isActive ? '✅ Active' : '❌ Inactive'}`);
      console.log(`   Email Verified: ${admin.isEmailVerified ? '✅ Yes' : '❌ No'}`);
      console.log(`   Last Login: ${admin.lastLogin ? admin.lastLogin.toLocaleDateString() : 'Never'}`);
      
      // Check if password is hashed (should be)
      if (admin.password && admin.password.length > 20) {
        console.log(`   Password: 🔒 Hashed (secure)`);
      } else if (admin.password) {
        console.log(`   Password: ⚠️  Plain text: ${admin.password}`);
      } else {
        console.log(`   Password: ❌ No password set`);
      }
      
      console.log('');
    }

    // Test common passwords for Test Company 1
    console.log('🔑 **Testing common passwords for Test Company 1:**\n');
    
    const testCompany1Admin = await User.findOne({ 
      email: 'admin1@testcompany1.com' 
    });

    if (testCompany1Admin) {
      const commonPasswords = [
        'Admin@123',
        'admin123',
        'password',
        '123456',
        'admin1@testcompany1.com',
        'testcompany1',
        'admin1',
        'password123'
      ];

      console.log(`Testing passwords for: ${testCompany1Admin.email}\n`);

      for (const password of commonPasswords) {
        try {
          const isMatch = await bcrypt.compare(password, testCompany1Admin.password);
          if (isMatch) {
            console.log(`✅ **FOUND MATCHING PASSWORD:** ${password}`);
            break;
          } else {
            console.log(`❌ ${password}`);
          }
        } catch (error) {
          console.log(`❌ ${password} (error: ${error.message})`);
        }
      }
    } else {
      console.log('❌ Test Company 1 admin not found');
    }

    console.log('\n💡 **Recommendations:**');
    console.log('1. If no password matches, the user may need to reset their password');
    console.log('2. Consider creating a password reset script');
    console.log('3. Check if the user was created with a default password');

  } catch (error) {
    console.error('❌ Error checking admin passwords:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run the script
checkAdminPasswords(); 