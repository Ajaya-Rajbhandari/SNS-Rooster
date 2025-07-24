const mongoose = require('mongoose');
require('dotenv').config();

const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function refreshCompanyFeatures() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('\n🔄 Refreshing company features based on subscription plans...');

    // Get all companies
    const companies = await Company.find({}).populate('subscriptionPlan');
    
    console.log(`Found ${companies.length} companies to process`);

    for (const company of companies) {
      console.log(`\n📝 Processing: ${company.name}`);
      console.log(`   Current plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
      
      if (!company.subscriptionPlan) {
        console.log(`   ⚠️  No subscription plan assigned - skipping`);
        continue;
      }

      const plan = company.subscriptionPlan;
      console.log(`   Plan features:`, {
        analytics: plan.features?.analytics,
        advancedReporting: plan.features?.advancedReporting,
        customBranding: plan.features?.customBranding,
        apiAccess: plan.features?.apiAccess,
        multiLocation: plan.features?.multiLocationSupport,
        expenseManagement: plan.features?.expenseManagement,
        performanceReviews: plan.features?.performanceReviews,
        trainingManagement: plan.features?.trainingManagement,
        locationBasedAttendance: plan.features?.locationBasedAttendance
      });

      // Update company features based on subscription plan
      const updatedFeatures = {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: plan.features?.analytics || false,
        documentManagement: true,
        notifications: true,
        customBranding: plan.features?.customBranding || false,
        apiAccess: plan.features?.apiAccess || false,
        multiLocation: plan.features?.multiLocationSupport || false,
        advancedReporting: plan.features?.advancedReporting || false,
        timeTracking: true,
        expenseManagement: plan.features?.expenseManagement || false,
        performanceReviews: plan.features?.performanceReviews || false,
        trainingManagement: plan.features?.trainingManagement || false,
        locationBasedAttendance: plan.features?.locationBasedAttendance || false,
      };

      // Update company limits based on subscription plan
      const updatedLimits = {
        maxEmployees: plan.features?.maxEmployees || 10,
        maxStorageGB: plan.storageLimit || 5,
        maxApiCallsPerDay: plan.apiCallLimit || 1000,
        maxDepartments: plan.features?.maxDepartments || 3,
        dataRetention: plan.features?.dataRetention || 365,
      };

      // Update the company
      company.features = updatedFeatures;
      company.limits = updatedLimits;
      
      await company.save();
      
      console.log(`   ✅ Updated features:`, Object.keys(updatedFeatures).filter(key => updatedFeatures[key]));
      console.log(`   ✅ Updated limits:`, updatedLimits);
    }

    console.log('\n🎉 All company features have been refreshed!');
    console.log('💡 Companies should now see the correct features in their Company Settings.');

  } catch (error) {
    console.error('Error refreshing company features:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
refreshCompanyFeatures(); 