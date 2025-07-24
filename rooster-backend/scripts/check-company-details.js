const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function checkCompanyDetails() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const citExpressCompany = await Company.findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    }).populate('subscriptionPlan');

    if (!citExpressCompany) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found Cit Express company:');
    console.log('=====================================');
    console.log('Company Details:');
    console.log(`- Name: ${citExpressCompany.name}`);
    console.log(`- Domain: ${citExpressCompany.domain}`);
    console.log(`- Status: ${citExpressCompany.status}`);
    console.log(`- Address: ${citExpressCompany.address || 'NOT SET'}`);
    console.log(`- Phone: ${citExpressCompany.phone || 'NOT SET'}`);
    console.log(`- Email: ${citExpressCompany.email || 'NOT SET'}`);
    console.log(`- Website: ${citExpressCompany.website || 'NOT SET'}`);
    console.log(`- Industry: ${citExpressCompany.industry || 'NOT SET'}`);
    console.log(`- Size: ${citExpressCompany.size || 'NOT SET'}`);
    console.log(`- Created At: ${citExpressCompany.createdAt}`);
    console.log(`- Updated At: ${citExpressCompany.updatedAt}`);

    console.log('\n📋 Subscription Plan Details:');
    if (citExpressCompany.subscriptionPlan) {
      console.log(`- Plan Name: ${citExpressCompany.subscriptionPlan.name}`);
      console.log(`- Plan Type: ${citExpressCompany.subscriptionPlan.type}`);
      console.log(`- Price: $${citExpressCompany.subscriptionPlan.price}`);
      console.log(`- Employee Limit: ${citExpressCompany.subscriptionPlan.employeeLimit}`);
      console.log(`- Storage Limit: ${citExpressCompany.subscriptionPlan.storageLimit}GB`);
      console.log(`- API Call Limit: ${citExpressCompany.subscriptionPlan.apiCallLimit}`);
      
      console.log('\n🔧 Plan Features:');
      citExpressCompany.subscriptionPlan.features.forEach(feature => {
        console.log(`  - ${feature.name}: ${feature.enabled ? '✅ Enabled' : '❌ Disabled'}`);
      });
    } else {
      console.log('❌ No subscription plan assigned!');
    }

    // Check all available subscription plans
    console.log('\n📊 All Available Subscription Plans:');
    const allPlans = await SubscriptionPlan.find({}).sort({ price: 1 });
    allPlans.forEach(plan => {
      console.log(`\n${plan.name} ($${plan.price}/month):`);
      console.log(`  - Employee Limit: ${plan.employeeLimit}`);
      console.log(`  - Storage Limit: ${plan.storageLimit}GB`);
      console.log(`  - API Call Limit: ${plan.apiCallLimit}`);
      console.log('  - Features:');
      plan.features.forEach(feature => {
        console.log(`    - ${feature.name}: ${feature.enabled ? '✅' : '❌'}`);
      });
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkCompanyDetails(); 