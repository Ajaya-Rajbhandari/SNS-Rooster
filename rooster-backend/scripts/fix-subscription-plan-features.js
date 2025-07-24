const mongoose = require('mongoose');
require('dotenv').config();

const SubscriptionPlan = require('../models/SubscriptionPlan');

async function fixSubscriptionPlanFeatures() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('\n🔧 Fixing subscription plan features...');

    // Update Basic Plan
    const basicResult = await SubscriptionPlan.updateOne(
      { name: 'Basic' },
      {
        $set: {
          'features.maxEmployees': 10,
          'features.maxDepartments': 3,
          'features.analytics': false,
          'features.advancedReporting': false,
          'features.customBranding': false,
          'features.apiAccess': false,
          'features.prioritySupport': false,
          'features.dataRetention': 365,
          'features.backupFrequency': 'weekly',
          'features.locationBasedAttendance': false,
          'features.multiLocationSupport': false,
          'features.expenseManagement': false,
          'features.performanceReviews': false,
          'features.trainingManagement': false
        }
      }
    );
    console.log(`✅ Basic plan updated: ${basicResult.modifiedCount} changes`);

    // Update Advance Plan
    const advanceResult = await SubscriptionPlan.updateOne(
      { name: 'Advance' },
      {
        $set: {
          'features.maxEmployees': 25,
          'features.maxDepartments': 5,
          'features.analytics': true,
          'features.advancedReporting': false,
          'features.customBranding': false,
          'features.apiAccess': false,
          'features.prioritySupport': false,
          'features.dataRetention': 365,
          'features.backupFrequency': 'weekly',
          'features.locationBasedAttendance': false,
          'features.multiLocationSupport': false,
          'features.expenseManagement': false,
          'features.performanceReviews': false,
          'features.trainingManagement': false
        }
      }
    );
    console.log(`✅ Advance plan updated: ${advanceResult.modifiedCount} changes`);

    // Update Professional Plan
    const professionalResult = await SubscriptionPlan.updateOne(
      { name: 'Professional' },
      {
        $set: {
          'features.maxEmployees': 50,
          'features.maxDepartments': 10,
          'features.analytics': true,
          'features.advancedReporting': true,
          'features.customBranding': true,
          'features.apiAccess': false,
          'features.prioritySupport': false,
          'features.dataRetention': 365,
          'features.backupFrequency': 'weekly',
          'features.locationBasedAttendance': true,
          'features.multiLocationSupport': true,
          'features.expenseManagement': true,
          'features.performanceReviews': false,
          'features.trainingManagement': false
        }
      }
    );
    console.log(`✅ Professional plan updated: ${professionalResult.modifiedCount} changes`);

    // Update Enterprise Plan
    const enterpriseResult = await SubscriptionPlan.updateOne(
      { name: 'Enterprise' },
      {
        $set: {
          'features.maxEmployees': 100,
          'features.maxDepartments': 50,
          'features.analytics': true,
          'features.advancedReporting': true,
          'features.customBranding': true,
          'features.apiAccess': true,
          'features.prioritySupport': true,
          'features.dataRetention': 730,
          'features.backupFrequency': 'daily',
          'features.locationBasedAttendance': true,
          'features.multiLocationSupport': true,
          'features.expenseManagement': true,
          'features.performanceReviews': true,
          'features.trainingManagement': true
        }
      }
    );
    console.log(`✅ Enterprise plan updated: ${enterpriseResult.modifiedCount} changes`);

    // Verify the changes
    console.log('\n📊 Verification - Updated Subscription Plans:');
    console.log('==============================================');
    
    const allPlans = await SubscriptionPlan.find({}).sort({ 'price.monthly': 1 });
    
    allPlans.forEach((plan, index) => {
      console.log(`\n${index + 1}. ${plan.name} ($${plan.price?.monthly}/month):`);
      console.log(`   - Max Employees: ${plan.features?.maxEmployees || 'Not set'}`);
      console.log(`   - Analytics: ${plan.features?.analytics ? '✅' : '❌'}`);
      console.log(`   - Advanced Reporting: ${plan.features?.advancedReporting ? '✅' : '❌'}`);
      console.log(`   - Custom Branding: ${plan.features?.customBranding ? '✅' : '❌'}`);
      console.log(`   - API Access: ${plan.features?.apiAccess ? '✅' : '❌'}`);
      console.log(`   - Multi-Location: ${plan.features?.multiLocationSupport ? '✅' : '❌'}`);
      console.log(`   - Expense Management: ${plan.features?.expenseManagement ? '✅' : '❌'}`);
      console.log(`   - Performance Reviews: ${plan.features?.performanceReviews ? '✅' : '❌'}`);
      console.log(`   - Training Management: ${plan.features?.trainingManagement ? '✅' : '❌'}`);
    });

    console.log('\n🎉 Subscription plan features have been successfully updated!');
    console.log('💡 Companies with Enterprise plan should now see all features in Company Settings.');

  } catch (error) {
    console.error('Error fixing subscription plan features:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
fixSubscriptionPlanFeatures(); 