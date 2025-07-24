const mongoose = require('mongoose');
const Company = require('../models/Company');

async function checkCompanyById() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    const companyId = '687c6cf9fce054783b9af432';
    const company = await Company.findById(companyId).populate('subscriptionPlan');
    
    if (!company) {
      console.log(`❌ Company with ID ${companyId} not found`);
      return;
    }

    console.log('📊 Company Details:');
    console.log('==================');
    console.log(`ID: ${company._id}`);
    console.log(`Name: ${company.name}`);
    console.log(`Status: ${company.status}`);
    console.log(`Subscription Plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
    console.log(`Features loaded: ${company.features ? 'Yes' : 'No'}`);
    console.log(`Limits loaded: ${company.limits ? 'Yes' : 'No'}\n`);

    if (company.subscriptionPlan) {
      console.log('📋 Subscription Plan Features:');
      console.log('==============================');
      const features = company.subscriptionPlan.features || {};
      Object.entries(features).forEach(([key, value]) => {
        console.log(`${key}: ${value}`);
      });
      console.log();

      console.log('🔧 Company Features:');
      console.log('===================');
      const companyFeatures = company.features || {};
      Object.entries(companyFeatures).forEach(([key, value]) => {
        console.log(`${key}: ${value}`);
      });
      console.log();

      // Check if features are properly synced
      const mismatchedFeatures = [];
      Object.entries(features).forEach(([key, value]) => {
        if (companyFeatures[key] !== value) {
          mismatchedFeatures.push({ key, planValue: value, companyValue: companyFeatures[key] });
        }
      });

      if (mismatchedFeatures.length > 0) {
        console.log('⚠️  Mismatched Features:');
        console.log('=======================');
        mismatchedFeatures.forEach(({ key, planValue, companyValue }) => {
          console.log(`${key}: Plan=${planValue}, Company=${companyValue}`);
        });
        console.log();
      } else {
        console.log('✅ All features are properly synced!\n');
      }
    }

    // Simulate the API response
    console.log('🎯 Simulated Frontend API Response:');
    console.log('===================================');
    
    const simulatedResponse = {
      features: {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: company.subscriptionPlan?.features?.analytics || false,
        documentManagement: true,
        notifications: true,
        customBranding: company.subscriptionPlan?.features?.customBranding || false,
        apiAccess: company.subscriptionPlan?.features?.apiAccess || false,
        multiLocation: company.subscriptionPlan?.features?.multiLocationSupport || false,
        advancedReporting: company.subscriptionPlan?.features?.advancedReporting || false,
        timeTracking: true,
        expenseManagement: company.subscriptionPlan?.features?.expenseManagement || false,
        performanceReviews: company.subscriptionPlan?.features?.performanceReviews || false,
        trainingManagement: company.subscriptionPlan?.features?.trainingManagement || false,
        locationBasedAttendance: company.subscriptionPlan?.features?.locationBasedAttendance || false,
      },
      limits: company.limits || {},
      usage: company.usage || {},
      subscriptionPlan: company.subscriptionPlan || {},
      company: {
        name: company.name,
        status: company.status,
      }
    };

    console.log('Features being returned:');
    Object.entries(simulatedResponse.features).forEach(([key, value]) => {
      console.log(`  ${key}: ${value ? '✅' : '❌'}`);
    });
    console.log();

    console.log('📱 Expected Frontend Behavior:');
    console.log('==============================');
    console.log(`Plan Name: ${simulatedResponse.subscriptionPlan.name || 'No Plan'}`);
    console.log(`Location Management: ${simulatedResponse.features.multiLocation ? '✅ Visible' : '❌ Hidden'}`);
    console.log(`Expense Management: ${simulatedResponse.features.expenseManagement ? '✅ Visible' : '❌ Hidden'}`);
    console.log(`Analytics: ${simulatedResponse.features.analytics ? '✅ Visible' : '❌ Hidden'}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkCompanyById(); 