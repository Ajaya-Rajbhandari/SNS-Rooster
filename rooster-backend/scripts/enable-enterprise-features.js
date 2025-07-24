const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');

async function enableEnterpriseFeatures() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find any existing company
    const companies = await Company.find().limit(5);
    console.log(`Found ${companies.length} companies`);

    if (companies.length === 0) {
      console.log('No companies found. Please create a company first.');
      return;
    }

    // Use the first company found
    const company = companies[0];
    console.log(`Updating company: ${company.name} (${company._id})`);

    // Update the company features to enable Enterprise features
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

    // Update limits for Enterprise plan
    company.limits = {
      maxEmployees: 1000,
      maxStorageGB: 100,
      retentionDays: 365,
      maxApiCallsPerDay: 10000,
      maxLocations: 10
    };

    // Set as custom plan with Enterprise features
    company.isCustomPlan = true;
    company.customPlanData = {
      features: company.features,
      limits: company.limits
    };

    await company.save();
    console.log('✅ Company updated with Enterprise features!');

    // Find admin users and ensure they have access to this company
    const adminUsers = await User.find({ role: 'admin' });
    console.log(`Found ${adminUsers.length} admin users`);

    for (const user of adminUsers) {
      if (!user.companyId || user.companyId.toString() !== company._id.toString()) {
        user.companyId = company._id;
        await user.save();
        console.log(`Updated user ${user.email} to company ${company.name}`);
      }
    }

    console.log('✅ Enterprise features enabled successfully!');
    console.log('Features enabled:');
    console.log('- Multi-Location Management');
    console.log('- Expense Management');
    console.log('- Performance Reviews');
    console.log('- Training Management');
    console.log('');
    console.log('Now restart your Flutter app and the Enterprise features should appear in the side navigation!');

  } catch (error) {
    console.error('Error enabling Enterprise features:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
enableEnterpriseFeatures(); 