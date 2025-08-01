const mongoose = require('mongoose');
const Company = require('./models/Company');
const SubscriptionPlan = require('./models/SubscriptionPlan');
require('dotenv').config();

async function syncCompanyFeatures() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    
    console.log('🔄 SYNCING COMPANY FEATURES WITH SUBSCRIPTION PLAN');
    console.log('==================================================');
    
    // Find the company
    const company = await Company.findOne({ name: /SNS/i }).populate('subscriptionPlan');
    
    if (!company || !company.subscriptionPlan) {
      console.log('❌ Company or subscription plan not found');
      return;
    }
    
    console.log(`🏢 Company: ${company.name}`);
    console.log(`📋 Plan: ${company.subscriptionPlan.name}`);
    
    // Get plan features
    const planFeatures = company.subscriptionPlan.features;
    
    console.log('\n📊 BEFORE:');
    console.log(`   Company Performance Reviews: ${company.features?.performanceReviews}`);
    console.log(`   Plan Performance Reviews: ${planFeatures?.performanceReviews}`);
    
    // Update company features to match plan features
    const updateResult = await Company.findByIdAndUpdate(
      company._id,
      {
        $set: {
          'features.performanceReviews': planFeatures.performanceReviews,
          // Sync other important features too
          'features.analytics': planFeatures.analytics,
          'features.advancedReporting': planFeatures.advancedReporting,
          'features.documentManagement': planFeatures.documentManagement,
          'features.customBranding': planFeatures.customBranding,
          'features.apiAccess': planFeatures.apiAccess,
          'features.expenseManagement': planFeatures.expenseManagement,
          'features.trainingManagement': planFeatures.trainingManagement,
        }
      },
      { new: true }
    );
    
    console.log('\n📊 AFTER:');
    console.log(`   ✅ Company Performance Reviews: ${updateResult.features.performanceReviews}`);
    console.log(`   ✅ Plan Performance Reviews: ${planFeatures.performanceReviews}`);
    
    console.log('\n🎉 Company features synced with subscription plan!');
    console.log('💡 The Performance Reviews feature should now work properly.');
    
    mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    mongoose.connection.close();
  }
}

syncCompanyFeatures(); 