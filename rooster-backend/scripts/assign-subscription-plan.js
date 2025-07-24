const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function assignSubscriptionPlan() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const citExpressCompany = await Company.findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    });

    if (!citExpressCompany) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found Cit Express company:', citExpressCompany.name);

    // Find the Basic subscription plan
    const basicPlan = await SubscriptionPlan.findOne({ name: 'Basic' });

    if (!basicPlan) {
      console.log('❌ Basic subscription plan not found');
      return;
    }

    console.log('✅ Found Basic subscription plan:', basicPlan.name);

    // Check if company already has a subscription plan
    if (citExpressCompany.subscriptionPlan) {
      console.log('⚠️  Company already has a subscription plan:', citExpressCompany.subscriptionPlan);
    }

    // Assign the Basic plan to the company
    const updatedCompany = await Company.findByIdAndUpdate(
      citExpressCompany._id,
      {
        subscriptionPlan: basicPlan._id,
        status: 'active'
      },
      { new: true }
    ).populate('subscriptionPlan');

    console.log('✅ Successfully assigned Basic plan to Cit Express!');
    console.log('\n📋 Updated Company Details:');
    console.log('=====================================');
    console.log(`- Company: ${updatedCompany.name}`);
    console.log(`- Status: ${updatedCompany.status}`);
    console.log(`- Subscription Plan: ${updatedCompany.subscriptionPlan.name}`);
    console.log(`- Plan Price: $${updatedCompany.subscriptionPlan.price.monthly}/month`);
    console.log(`- Employee Limit: ${updatedCompany.subscriptionPlan.employeeLimit}`);
    console.log(`- Storage Limit: ${updatedCompany.subscriptionPlan.storageLimit}GB`);
    console.log(`- API Call Limit: ${updatedCompany.subscriptionPlan.apiCallLimit}`);

    // Verify the assignment
    const verifyCompany = await Company.findById(citExpressCompany._id).populate('subscriptionPlan');
    console.log('\n🔍 Verification:');
    console.log(`- Has subscription plan: ${!!verifyCompany.subscriptionPlan}`);
    console.log(`- Plan name: ${verifyCompany.subscriptionPlan?.name || 'None'}`);
    console.log(`- Plan ID: ${verifyCompany.subscriptionPlan?._id || 'None'}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

assignSubscriptionPlan(); 