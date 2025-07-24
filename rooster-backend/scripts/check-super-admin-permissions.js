const mongoose = require('mongoose');
const SuperAdmin = require('../models/SuperAdmin');
const User = require('../models/User');
require('dotenv').config();

async function checkSuperAdminPermissions() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the super admin user
    const superAdminUser = await User.findOne({ 
      email: 'superadmin@snstechservices.com.au',
      role: 'super_admin'
    });

    if (!superAdminUser) {
      console.log('❌ Super admin user not found');
      return;
    }

    console.log('✅ Super admin user found:', {
      id: superAdminUser._id,
      email: superAdminUser.email,
      role: superAdminUser.role
    });

    // Find the super admin record
    const superAdmin = await SuperAdmin.findOne({ 
      userId: superAdminUser._id,
      isActive: true
    });

    if (!superAdmin) {
      console.log('❌ Super admin record not found or not active');
      return;
    }

    console.log('✅ Super admin record found:', {
      id: superAdmin._id,
      userId: superAdmin.userId,
      isActive: superAdmin.isActive,
      permissions: superAdmin.permissions
    });

    // Check specific permissions
    const requiredPermissions = [
      'manageCompanies',
      'manageSubscriptions',
      'viewAnalytics'
    ];

    console.log('\n🔍 Checking permissions:');
    requiredPermissions.forEach(permission => {
      const hasPermission = superAdmin.permissions[permission];
      console.log(`${hasPermission ? '✅' : '❌'} ${permission}: ${hasPermission}`);
    });

    // Check if manageCompanies permission exists
    if (!superAdmin.permissions.manageCompanies) {
      console.log('\n⚠️  Missing manageCompanies permission!');
      console.log('Current permissions:', Object.keys(superAdmin.permissions));
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkSuperAdminPermissions(); 