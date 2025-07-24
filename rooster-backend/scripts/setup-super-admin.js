const mongoose = require('mongoose');
const User = require('../models/User');
const SuperAdmin = require('../models/SuperAdmin');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function setupSuperAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Create default subscription plans
    console.log('Creating default subscription plans...');
    
    const plans = [
      {
        name: 'Basic',
        description: 'Perfect for small businesses getting started',
        price: {
          monthly: 29,
          yearly: 290
        },
        features: {
          maxEmployees: 10,
          maxDepartments: 3,
          analytics: false,
          advancedReporting: false,
          customBranding: false,
          apiAccess: false,
          prioritySupport: false,
          dataRetention: 365,
          backupFrequency: 'weekly'
        },
        isDefault: true,
        sortOrder: 1
      },
      {
        name: 'Professional',
        description: 'Ideal for growing businesses with advanced needs',
        price: {
          monthly: 79,
          yearly: 790
        },
        features: {
          maxEmployees: 50,
          maxDepartments: 10,
          analytics: true,
          advancedReporting: true,
          customBranding: true,
          apiAccess: true,
          prioritySupport: false,
          dataRetention: 730,
          backupFrequency: 'daily'
        },
        sortOrder: 2
      },
      {
        name: 'Enterprise',
        description: 'Complete solution for large organizations',
        price: {
          monthly: 199,
          yearly: 1990
        },
        features: {
          maxEmployees: 500,
          maxDepartments: 50,
          analytics: true,
          advancedReporting: true,
          customBranding: true,
          apiAccess: true,
          prioritySupport: true,
          dataRetention: 1095,
          backupFrequency: 'daily'
        },
        sortOrder: 3
      }
    ];

    for (const planData of plans) {
      const existingPlan = await SubscriptionPlan.findOne({ name: planData.name });
      if (!existingPlan) {
        const plan = new SubscriptionPlan(planData);
        await plan.save();
        console.log(`✅ Created subscription plan: ${plan.name}`);
      } else {
        console.log(`⚠️  Subscription plan already exists: ${planData.name}`);
      }
    }

    // Create super admin user
    console.log('Creating super admin user...');
    
    const superAdminEmail = 'superadmin@snstechservices.com.au';
    const superAdminPassword = 'SuperAdmin@123';
    
    let superAdminUser = await User.findOne({ email: superAdminEmail });
    
    if (!superAdminUser) {
      superAdminUser = new User({
        email: superAdminEmail,
        password: superAdminPassword,
        firstName: 'Super',
        lastName: 'Admin',
        role: 'super_admin',
        isEmailVerified: true,
        isActive: true,
        isProfileComplete: true
      });
      
      await superAdminUser.save();
      console.log('✅ Created super admin user');
    } else {
      console.log('⚠️  Super admin user already exists');
    }

    // Create super admin record
    console.log('Creating super admin permissions...');
    
    let superAdminRecord = await SuperAdmin.findOne({ userId: superAdminUser._id });
    
    if (!superAdminRecord) {
      superAdminRecord = new SuperAdmin({
        userId: superAdminUser._id,
        permissions: {
          manageCompanies: true,
          manageSubscriptions: true,
          manageFeatures: true,
          manageUsers: true,
          viewAnalytics: true,
          manageBilling: true,
          systemSettings: true
        }
      });
      
      await superAdminRecord.save();
      console.log('✅ Created super admin permissions');
    } else {
      console.log('⚠️  Super admin permissions already exist');
    }

    console.log('\n🎉 Super Admin Setup Complete!');
    console.log('================================');
    console.log('Super Admin Credentials:');
    console.log(`Email: ${superAdminEmail}`);
    console.log(`Password: ${superAdminPassword}`);
    console.log('\nDefault Subscription Plans Created:');
    console.log('- Basic ($29/month, $290/year)');
    console.log('- Professional ($79/month, $790/year)');
    console.log('- Enterprise ($199/month, $1990/year)');
    console.log('\nYou can now log in as super admin and start managing companies!');

  } catch (error) {
    console.error('❌ Error setting up super admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the setup
setupSuperAdmin(); 