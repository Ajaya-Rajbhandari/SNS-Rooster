const mongoose = require('mongoose');
require('dotenv').config();

async function updateSubscriptionPlans() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const subscriptionPlansCollection = db.collection('subscriptionplans');

    console.log('\n🔧 Updating subscription plans with location-based attendance feature...');

    // Update Basic Plan - No location features
    const basicResult = await subscriptionPlansCollection.updateOne(
      { name: 'Basic' },
      {
        $set: {
          'features.locationBasedAttendance': false,
          'features.multiLocationSupport': false,
          'features.expenseManagement': false,
          'features.performanceReviews': false,
          'features.trainingManagement': false
        }
      }
    );
    console.log(`✅ Basic plan updated: ${basicResult.modifiedCount} changes`);

    // Update Pro Plan - Basic location features
    const proResult = await subscriptionPlansCollection.updateOne(
      { name: 'Pro' },
      {
        $set: {
          'features.locationBasedAttendance': true,
          'features.multiLocationSupport': true,
          'features.expenseManagement': false,
          'features.performanceReviews': false,
          'features.trainingManagement': false
        }
      }
    );
    console.log(`✅ Pro plan updated: ${proResult.modifiedCount} changes`);

    // Update Enterprise Plan - All location features
    const enterpriseResult = await subscriptionPlansCollection.updateOne(
      { name: 'Enterprise' },
      {
        $set: {
          'features.locationBasedAttendance': true,
          'features.multiLocationSupport': true,
          'features.expenseManagement': true,
          'features.performanceReviews': true,
          'features.trainingManagement': true
        }
      }
    );
    console.log(`✅ Enterprise plan updated: ${enterpriseResult.modifiedCount} changes`);

    // Show updated plans
    console.log('\n📋 Updated Subscription Plans:');
    const plans = await subscriptionPlansCollection.find({}).toArray();
    
    plans.forEach(plan => {
      console.log(`\n${plan.name} Plan:`);
      console.log(`  - Location-based Attendance: ${plan.features?.locationBasedAttendance ? '✅' : '❌'}`);
      console.log(`  - Multi-Location Support: ${plan.features?.multiLocationSupport ? '✅' : '❌'}`);
      console.log(`  - Expense Management: ${plan.features?.expenseManagement ? '✅' : '❌'}`);
      console.log(`  - Performance Reviews: ${plan.features?.performanceReviews ? '✅' : '❌'}`);
      console.log(`  - Training Management: ${plan.features?.trainingManagement ? '✅' : '❌'}`);
    });

    // Check current company's subscription
    const companiesCollection = db.collection('companies');
    const currentCompany = await companiesCollection.findOne({ 
      _id: new mongoose.Types.ObjectId('687c6cf9fce054783b9af432') 
    }).populate('subscriptionPlan');

    if (currentCompany) {
      console.log(`\n🏢 Current Company (${currentCompany.name}):`);
      console.log(`  - Subscription Plan: ${currentCompany.subscriptionPlan?.name || 'No Plan'}`);
      console.log(`  - Location-based Attendance: ${currentCompany.subscriptionPlan?.features?.locationBasedAttendance ? '✅ Enabled' : '❌ Disabled'}`);
    }

    console.log('\n🎉 Subscription plans updated successfully!');
    console.log('\n📝 Feature Summary:');
    console.log('  - Basic Plan: No location features');
    console.log('  - Pro Plan: Location-based attendance + Multi-location support');
    console.log('  - Enterprise Plan: All location features + Enterprise features');

  } catch (error) {
    console.error('Error updating subscription plans:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

updateSubscriptionPlans(); 