const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function createAdminUsersForCompanies() {
  try {
    console.log('🚀 Starting admin user creation for companies...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({}).populate('subscriptionPlan');
    console.log(`📋 Found ${companies.length} companies`);

    // Get default subscription plan (Basic)
    const defaultPlan = await SubscriptionPlan.findOne({ name: 'Basic' });
    if (!defaultPlan) {
      console.log('❌ Default subscription plan not found');
      return;
    }

    for (const company of companies) {
      console.log(`\n🔍 Processing company: ${company.name}`);
      
      // Check if company already has admin users
      const existingAdmin = await User.findOne({ 
        companyId: company._id, 
        role: 'admin' 
      });

      if (existingAdmin) {
        console.log(`✅ Company "${company.name}" already has admin user: ${existingAdmin.email}`);
        continue;
      }

      // Create admin user for this company
      const adminEmail = `admin@${company.domain}.com`;
      const adminPassword = 'Admin@123'; // Default password
      
      console.log(`📝 Creating admin user for ${company.name}:`);
      console.log(`   Email: ${adminEmail}`);
      console.log(`   Password: ${adminPassword}`);

      // Check if user with this email already exists
      const existingUser = await User.findOne({ email: adminEmail });
      if (existingUser) {
        console.log(`⚠️  User with email ${adminEmail} already exists, skipping...`);
        continue;
      }

      // Create admin user
      const adminUser = new User({
        companyId: company._id,
        email: adminEmail,
        password: adminPassword,
        firstName: 'Admin',
        lastName: company.name,
        role: 'admin',
        isEmailVerified: true,
        isActive: true,
        isProfileComplete: true,
        department: 'Administration',
        position: 'Company Administrator'
      });

      await adminUser.save();
      console.log(`✅ Created admin user for ${company.name}`);

      // Update company if it doesn't have a subscription plan
      if (!company.subscriptionPlan) {
        company.subscriptionPlan = defaultPlan._id;
        await company.save();
        console.log(`✅ Updated ${company.name} with default subscription plan`);
      }
    }

    console.log('\n🎉 Admin user creation completed!');
    console.log('\n📋 Summary of admin credentials:');
    
    // Display all admin users
    const allAdmins = await User.find({ role: 'admin' }).populate('companyId');
    for (const admin of allAdmins) {
      console.log(`\n🏢 ${admin.companyId?.name || 'Unknown Company'}:`);
      console.log(`   Email: ${admin.email}`);
      console.log(`   Password: Admin@123`);
      console.log(`   Role: ${admin.role}`);
    }

  } catch (error) {
    console.error('❌ Error creating admin users:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the script
createAdminUsersForCompanies(); 