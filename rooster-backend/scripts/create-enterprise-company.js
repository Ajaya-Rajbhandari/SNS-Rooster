const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function createEnterpriseCompany() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    // Find Enterprise plan
    const enterprisePlan = await SubscriptionPlan.findOne({ name: 'Enterprise' });
    if (!enterprisePlan) {
      console.log('❌ Enterprise plan not found');
      return;
    }

    console.log('✅ Found Enterprise plan:', enterprisePlan.name);

    // Check if test company already exists
    let testCompany = await Company.findOne({ name: 'Test Enterprise Company' });
    
    if (testCompany) {
      console.log('📝 Updating existing test company to Enterprise plan...');
      testCompany.subscriptionPlan = enterprisePlan._id;
      await testCompany.save();
    } else {
      console.log('🏢 Creating new test company with Enterprise plan...');
      testCompany = new Company({
        name: 'Test Enterprise Company',
        status: 'active',
        subscriptionPlan: enterprisePlan._id,
        features: {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: true,
          documentManagement: true,
          notifications: true,
          customBranding: true,
          apiAccess: true,
          multiLocation: true,
          advancedReporting: true,
          timeTracking: true,
          expenseManagement: true,
          performanceReviews: true,
          trainingManagement: true,
          locationBasedAttendance: true,
        },
        limits: {
          maxEmployees: 1000,
          maxStorageGB: 1000,
          maxApiCallsPerDay: 100000,
        },
        usage: {
          maxEmployees: 0,
          maxStorageGB: 0,
          maxApiCallsPerDay: 0,
        },
      });
      await testCompany.save();
    }

    console.log('✅ Test company created/updated successfully!');
    console.log(`Company: ${testCompany.name}`);
    console.log(`Plan: ${enterprisePlan.name}`);
    console.log(`Status: ${testCompany.status}`);

    // Verify the features
    console.log('\n📋 Enterprise Features:');
    console.log('======================');
    Object.entries(enterprisePlan.features).forEach(([key, value]) => {
      console.log(`${key}: ${value}`);
    });

    console.log('\n🎯 Expected Frontend Behavior:');
    console.log('==============================');
    console.log('Plan Name: Enterprise');
    console.log('Location Management: ✅ Visible');
    console.log('Expense Management: ✅ Visible');
    console.log('Analytics: ✅ Visible');
    console.log('Advanced Reporting: ✅ Visible');
    console.log('Custom Branding: ✅ Visible');
    console.log('API Access: ✅ Visible');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

createEnterpriseCompany(); 