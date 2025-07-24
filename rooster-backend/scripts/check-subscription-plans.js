const mongoose = require('mongoose');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function checkSubscriptionPlans() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('📊 All Available Subscription Plans:');
    console.log('=====================================');
    
    const allPlans = await SubscriptionPlan.find({}).sort({ price: 1 });
    
    if (allPlans.length === 0) {
      console.log('❌ No subscription plans found!');
      return;
    }

    allPlans.forEach((plan, index) => {
      console.log(`\n${index + 1}. ${plan.name} ($${plan.price}/month):`);
      console.log(`   - Type: ${plan.type}`);
      console.log(`   - Employee Limit: ${plan.employeeLimit}`);
      console.log(`   - Storage Limit: ${plan.storageLimit}GB`);
      console.log(`   - API Call Limit: ${plan.apiCallLimit}`);
      console.log(`   - Description: ${plan.description}`);
      console.log('   - Features:');
      
      if (plan.features && plan.features.length > 0) {
        plan.features.forEach(feature => {
          console.log(`     - ${feature.name}: ${feature.enabled ? '✅ Enabled' : '❌ Disabled'}`);
        });
      } else {
        console.log('     - No features defined');
      }
    });

    // Check which plan should have which features
    console.log('\n🔍 Feature Analysis:');
    console.log('===================');
    
    const basicPlan = allPlans.find(p => p.name.toLowerCase() === 'basic');
    const premiumPlan = allPlans.find(p => p.name.toLowerCase() === 'premium');
    const enterprisePlan = allPlans.find(p => p.name.toLowerCase() === 'enterprise');

    if (basicPlan) {
      console.log('\n📋 Basic Plan Features:');
      basicPlan.features.forEach(feature => {
        console.log(`  - ${feature.name}: ${feature.enabled ? '✅' : '❌'}`);
      });
    }

    if (premiumPlan) {
      console.log('\n📋 Premium Plan Features:');
      premiumPlan.features.forEach(feature => {
        console.log(`  - ${feature.name}: ${feature.enabled ? '✅' : '❌'}`);
      });
    }

    if (enterprisePlan) {
      console.log('\n📋 Enterprise Plan Features:');
      enterprisePlan.features.forEach(feature => {
        console.log(`  - ${feature.name}: ${feature.enabled ? '✅' : '❌'}`);
      });
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkSubscriptionPlans(); 