const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');

async function forceRefreshFeatures() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const company = await Company.findById('687c6cf9fce054783b9af432');
    
    if (!company) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log(`Current company: ${company.name}`);
    console.log(`Current status: ${company.status}`);
    console.log(`Current features:`, company.features);

    // Force enable all Enterprise features
    company.features = {
      attendance: true,
      payroll: true,
      leaveManagement: true,
      analytics: true,
      documentManagement: true,
      notifications: true,
      customBranding: true,
      apiAccess: true,
      multiLocation: true,        // Enterprise feature
      advancedReporting: true,
      timeTracking: true,
      expenseManagement: true,    // Enterprise feature
      performanceReviews: true,   // Enterprise feature
      trainingManagement: true    // Enterprise feature
    };

    // Set as Enterprise plan
    company.isCustomPlan = true;
    company.customPlanData = {
      features: company.features,
      limits: {
        maxEmployees: 1000,
        maxStorageGB: 100,
        retentionDays: 365,
        maxApiCallsPerDay: 10000,
        maxLocations: 10
      }
    };

    // Ensure company is active
    company.status = 'active';

    await company.save();
    
    console.log('✅ Enterprise features force-enabled!');
    console.log('Updated features:', company.features);

    // Also update the user to ensure they have the right permissions
    const user = await User.findOne({ email: 'admin@cityexpress.com.au' });
    if (user) {
      user.role = 'admin';
      user.isActive = true;
      await user.save();
      console.log('✅ User permissions updated!');
    }

    console.log('\n🔄 Now you need to:');
    console.log('1. Restart your Flutter app');
    console.log('2. Log out and log back in');
    console.log('3. The Enterprise features should appear in the side navigation');

  } catch (error) {
    console.error('Error force refreshing features:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
forceRefreshFeatures(); 