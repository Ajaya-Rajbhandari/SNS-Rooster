const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function listCompanyAdminUsers() {
  try {
    console.log('🔍 Listing all company admin users...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({});
    console.log(`📋 Found ${companies.length} companies\n`);

    for (const company of companies) {
      console.log(`🏢 **${company.name}**`);
      console.log(`   Domain: ${company.domain}`);
      console.log(`   Status: ${company.status}`);
      console.log(`   Plan ID: ${company.subscriptionPlan || 'No Plan'}`);
      
      // Find admin users for this company
      const adminUsers = await User.find({ 
        companyId: company._id, 
        role: 'admin' 
      });

      if (adminUsers.length === 0) {
        console.log(`   ❌ No admin users found`);
      } else {
        console.log(`   👥 Admin Users (${adminUsers.length}):`);
        adminUsers.forEach((admin, index) => {
          console.log(`      ${index + 1}. ${admin.email}`);
          console.log(`         Name: ${admin.firstName} ${admin.lastName}`);
          console.log(`         Active: ${admin.isActive ? '✅' : '❌'}`);
          console.log(`         Email Verified: ${admin.isEmailVerified ? '✅' : '❌'}`);
          console.log(`         Profile Complete: ${admin.isProfileComplete ? '✅' : '❌'}`);
          console.log(`         Last Login: ${admin.lastLogin ? admin.lastLogin.toLocaleDateString() : 'Never'}`);
        });
      }
      
      console.log(''); // Empty line for readability
    }

    // Summary
    console.log('📊 **Summary:**');
    const totalAdmins = await User.countDocuments({ role: 'admin' });
    const activeAdmins = await User.countDocuments({ role: 'admin', isActive: true });
    const verifiedAdmins = await User.countDocuments({ role: 'admin', isEmailVerified: true });
    
    console.log(`   Total Admin Users: ${totalAdmins}`);
    console.log(`   Active Admin Users: ${activeAdmins}`);
    console.log(`   Email Verified: ${verifiedAdmins}`);

    // Count companies with admins
    let companiesWithAdmins = 0;
    for (const company of companies) {
      const adminCount = await User.countDocuments({ 
        companyId: company._id, 
        role: 'admin' 
      });
      if (adminCount > 0) companiesWithAdmins++;
    }
    console.log(`   Companies with Admins: ${companiesWithAdmins}/${companies.length}`);

  } catch (error) {
    console.error('❌ Error listing admin users:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the script
listCompanyAdminUsers(); 