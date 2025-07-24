const mongoose = require('mongoose');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function fixSubscriptionPlans() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('🔧 Fixing subscription plans...');

    // Delete existing plans
    await SubscriptionPlan.deleteMany({});
    console.log('✅ Deleted existing subscription plans');

    // Create new plans with correct structure for both admin portal and Flutter app
    const plans = [
      {
        name: 'Basic',
        description: 'Perfect for small businesses getting started',
        price: {
          monthly: 29,
          yearly: 290
        },
        // Flutter app fields
        employeeLimit: 10,
        storageLimit: 5,
        apiCallLimit: 1000,
        // Admin portal fields
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
        isActive: true,
        isDefault: true,
        sortOrder: 1
      },
      {
        name: 'Advance',
        description: 'Included more features than Basic and less than Professional',
        price: {
          monthly: 50,
          yearly: 500
        },
        // Flutter app fields
        employeeLimit: 25,
        storageLimit: 10,
        apiCallLimit: 2500,
        // Admin portal fields
        features: {
          maxEmployees: 25,
          maxDepartments: 5,
          analytics: true,
          advancedReporting: false,
          customBranding: false,
          apiAccess: false,
          prioritySupport: false,
          dataRetention: 365,
          backupFrequency: 'weekly'
        },
        isActive: true,
        isDefault: false,
        sortOrder: 2
      },
      {
        name: 'Professional',
        description: 'Ideal for growing businesses with advanced needs',
        price: {
          monthly: 79,
          yearly: 790
        },
        // Flutter app fields
        employeeLimit: 50,
        storageLimit: 20,
        apiCallLimit: 5000,
        // Admin portal fields
        features: {
          maxEmployees: 50,
          maxDepartments: 10,
          analytics: true,
          advancedReporting: true,
          customBranding: true,
          apiAccess: false,
          prioritySupport: false,
          dataRetention: 730,
          backupFrequency: 'daily'
        },
        isActive: true,
        isDefault: false,
        sortOrder: 3
      },
      {
        name: 'Enterprise',
        description: 'Complete solution for large organizations',
        price: {
          monthly: 199,
          yearly: 1990
        },
        // Flutter app fields
        employeeLimit: 100,
        storageLimit: 50,
        apiCallLimit: 10000,
        // Admin portal fields
        features: {
          maxEmployees: 100,
          maxDepartments: 20,
          analytics: true,
          advancedReporting: true,
          customBranding: true,
          apiAccess: true,
          prioritySupport: true,
          dataRetention: 1095,
          backupFrequency: 'daily'
        },
        isActive: true,
        isDefault: false,
        sortOrder: 4
      }
    ];

    // Create the plans
    const createdPlans = await SubscriptionPlan.insertMany(plans);
    console.log(`✅ Created ${createdPlans.length} subscription plans`);

    // Verify the plans
    console.log('\n📋 Created Plans:');
    createdPlans.forEach(plan => {
      console.log(`\n${plan.name} ($${plan.price.monthly}/month):`);
      console.log(`  - Employee Limit: ${plan.employeeLimit || plan.features.maxEmployees}`);
      console.log(`  - Storage Limit: ${plan.storageLimit}GB`);
      console.log(`  - API Call Limit: ${plan.apiCallLimit}`);
      console.log('  - Admin Portal Features:');
      console.log(`    - Analytics: ${plan.features.analytics ? '✅' : '❌'}`);
      console.log(`    - Advanced Reporting: ${plan.features.advancedReporting ? '✅' : '❌'}`);
      console.log(`    - Custom Branding: ${plan.features.customBranding ? '✅' : '❌'}`);
      console.log(`    - API Access: ${plan.features.apiAccess ? '✅' : '❌'}`);
      console.log(`    - Priority Support: ${plan.features.prioritySupport ? '✅' : '❌'}`);
    });

    console.log('\n🎉 Subscription plans have been fixed!');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

fixSubscriptionPlans(); 