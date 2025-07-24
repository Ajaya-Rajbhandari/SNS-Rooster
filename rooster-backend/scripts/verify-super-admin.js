const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('../models/User');
const SuperAdmin = require('../models/SuperAdmin');
const bcrypt = require('bcrypt');

async function verifySuperAdmin() {
  try {
    console.log('🔍 Verifying super admin setup...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Check super admin user
    const superAdminUser = await User.findOne({ 
      email: 'superadmin@snstechservices.com.au' 
    });

    if (!superAdminUser) {
      console.log('❌ Super admin user not found!');
      console.log('💡 Run: node scripts/setup-super-admin.js');
      return;
    }

    console.log('✅ Super admin user found:');
    console.log(`   Email: ${superAdminUser.email}`);
    console.log(`   Name: ${superAdminUser.firstName} ${superAdminUser.lastName}`);
    console.log(`   Role: ${superAdminUser.role}`);
    console.log(`   Active: ${superAdminUser.isActive ? '✅' : '❌'}`);
    console.log(`   Email Verified: ${superAdminUser.isEmailVerified ? '✅' : '❌'}`);

    // Check super admin record
    const superAdminRecord = await SuperAdmin.findOne({ 
      userId: superAdminUser._id 
    });

    if (!superAdminRecord) {
      console.log('❌ Super admin record not found!');
      console.log('💡 Run: node scripts/setup-super-admin.js');
      return;
    }

    console.log('✅ Super admin record found:');
    console.log(`   Active: ${superAdminRecord.isActive ? '✅' : '❌'}`);
    console.log(`   Permissions: ${Object.keys(superAdminRecord.permissions).join(', ')}`);

    // Test password
    const testPassword = 'SuperAdmin@123';
    const isPasswordValid = await bcrypt.compare(testPassword, superAdminUser.password);
    
    console.log(`\n🔑 Password test: ${isPasswordValid ? '✅ Valid' : '❌ Invalid'}`);
    
    if (!isPasswordValid) {
      console.log('💡 Password is incorrect. Expected: SuperAdmin@123');
    }

    // Test login
    console.log('\n🧪 Testing login...');
    try {
      const axios = require('axios');
      
      const loginResponse = await axios.post('http://localhost:5000/api/auth/login', {
        email: 'superadmin@snstechservices.com.au',
        password: 'SuperAdmin@123'
      });

      console.log('✅ Login successful!');
      console.log(`   Token: ${loginResponse.data.token ? 'Present' : 'Missing'}`);
      console.log(`   User: ${loginResponse.data.user ? 'Present' : 'Missing'}`);

      // Test subscription plans endpoint
      const plansResponse = await axios.get('http://localhost:5000/api/super-admin/subscription-plans', {
        headers: {
          'Authorization': `Bearer ${loginResponse.data.token}`
        }
      });

      console.log('✅ Subscription plans endpoint working!');
      console.log(`   Plans count: ${plansResponse.data.plans?.length || 0}`);

    } catch (error) {
      console.log('❌ Login test failed:');
      console.log(`   Error: ${error.response?.data?.message || error.message}`);
    }

  } catch (error) {
    console.error('❌ Error verifying super admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run the script
verifySuperAdmin(); 