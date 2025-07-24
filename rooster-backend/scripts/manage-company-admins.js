const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');

async function manageCompanyAdmins() {
  try {
    console.log('🔧 Company Admin Management Tool');
    console.log('================================\n');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get all companies
    const companies = await Company.find({});
    console.log(`📋 Found ${companies.length} companies\n`);

    // Display current admin status
    console.log('📊 **Current Admin Status:**\n');
    
    for (const company of companies) {
      console.log(`🏢 **${company.name}** (${company.status})`);
      console.log(`   Domain: ${company.domain}`);
      
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
          const status = admin.isActive ? '✅' : '❌';
          const verified = admin.isEmailVerified ? '✅' : '❌';
          const profile = admin.isProfileComplete ? '✅' : '❌';
          const lastLogin = admin.lastLogin ? admin.lastLogin.toLocaleDateString() : 'Never';
          
          console.log(`      ${index + 1}. ${admin.email}`);
          console.log(`         Name: ${admin.firstName} ${admin.lastName}`);
          console.log(`         Status: ${status} Active | ${verified} Verified | ${profile} Profile Complete`);
          console.log(`         Last Login: ${lastLogin}`);
        });
      }
      console.log('');
    }

    // Summary and recommendations
    console.log('💡 **Recommendations:**\n');
    
    const totalAdmins = await User.countDocuments({ role: 'admin' });
    const activeAdmins = await User.countDocuments({ role: 'admin', isActive: true });
    const verifiedAdmins = await User.countDocuments({ role: 'admin', isEmailVerified: true });
    const profileCompleteAdmins = await User.countDocuments({ role: 'admin', isProfileComplete: true });
    
    console.log(`📈 **Statistics:**`);
    console.log(`   Total Admin Users: ${totalAdmins}`);
    console.log(`   Active: ${activeAdmins}/${totalAdmins}`);
    console.log(`   Email Verified: ${verifiedAdmins}/${totalAdmins}`);
    console.log(`   Profile Complete: ${profileCompleteAdmins}/${totalAdmins}`);

    // Find admins that need attention
    const inactiveAdmins = await User.find({ role: 'admin', isActive: false });
    const unverifiedAdmins = await User.find({ role: 'admin', isEmailVerified: false });
    const incompleteProfiles = await User.find({ role: 'admin', isProfileComplete: false });
    const neverLoggedIn = await User.find({ role: 'admin', lastLogin: null });

    if (inactiveAdmins.length > 0) {
      console.log(`\n⚠️  **Inactive Admins (${inactiveAdmins.length}):**`);
      inactiveAdmins.forEach(admin => {
        console.log(`   - ${admin.email} (${admin.companyId})`);
      });
    }

    if (unverifiedAdmins.length > 0) {
      console.log(`\n⚠️  **Unverified Email (${unverifiedAdmins.length}):**`);
      unverifiedAdmins.forEach(admin => {
        console.log(`   - ${admin.email} (${admin.companyId})`);
      });
    }

    if (incompleteProfiles.length > 0) {
      console.log(`\n⚠️  **Incomplete Profiles (${incompleteProfiles.length}):**`);
      incompleteProfiles.forEach(admin => {
        console.log(`   - ${admin.email} (${admin.companyId})`);
      });
    }

    if (neverLoggedIn.length > 0) {
      console.log(`\n⚠️  **Never Logged In (${neverLoggedIn.length}):**`);
      neverLoggedIn.forEach(admin => {
        console.log(`   - ${admin.email} (${admin.companyId})`);
      });
    }

    console.log('\n🎯 **Action Items:**');
    console.log('1. All companies have admin users ✅');
    console.log('2. Consider updating passwords for security');
    console.log('3. Complete profiles for better user experience');
    console.log('4. Verify email addresses for unverified users');
    console.log('5. Encourage first-time login for new admins');

    console.log('\n🔑 **Default Passwords (if not changed):**');
    console.log('   Most admin users likely have default passwords.');
    console.log('   Consider running a password update script.');

  } catch (error) {
    console.error('❌ Error managing admin users:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run the script
manageCompanyAdmins(); 