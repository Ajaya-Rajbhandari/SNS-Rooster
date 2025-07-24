const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
require('dotenv').config();

async function checkAdminUser() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const company = await Company.findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    });

    if (!company) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found company:', {
      id: company._id,
      name: company.name,
      domain: company.domain,
      status: company.status
    });

    // Find admin user for this company
    const adminUser = await User.findOne({
      companyId: company._id,
      role: 'admin'
    });

    if (!adminUser) {
      console.log('❌ Admin user not found for this company');
      return;
    }

    console.log('✅ Found admin user:', {
      id: adminUser._id,
      email: adminUser.email,
      firstName: adminUser.firstName,
      lastName: adminUser.lastName,
      role: adminUser.role,
      isActive: adminUser.isActive,
      isEmailVerified: adminUser.isEmailVerified,
      companyId: adminUser.companyId
    });

    // Check if user needs to be activated
    if (!adminUser.isActive || !adminUser.isEmailVerified) {
      console.log('⚠️  Admin user needs to be activated');
      
      const updatedUser = await User.findByIdAndUpdate(
        adminUser._id,
        {
          isActive: true,
          isEmailVerified: true
        },
        { new: true }
      );

      console.log('✅ Admin user activated:', {
        id: updatedUser._id,
        email: updatedUser.email,
        isActive: updatedUser.isActive,
        isEmailVerified: updatedUser.isEmailVerified
      });
    } else {
      console.log('✅ Admin user is already active and verified');
    }

    // Check all users in this company
    const allUsers = await User.find({ companyId: company._id });
    console.log(`\n👥 Total users in ${company.name}: ${allUsers.length}`);
    allUsers.forEach(user => {
      console.log(`- ${user.email} (${user.role}) - Active: ${user.isActive}`);
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkAdminUser(); 