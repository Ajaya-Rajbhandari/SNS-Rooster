const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function checkEnterpriseCompanies() {
  try {
    // Get MongoDB URI from environment or use default
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    console.log('Connecting to MongoDB...');
    
    await mongoose.connect(MONGODB_URI, {
      tlsAllowInvalidCertificates: true,
    });
    console.log('Connected to MongoDB');

    console.log('\n🔍 CHECKING ENTERPRISE COMPANIES');
    console.log('=================================');

    // Get all companies with their subscription plans
    const companies = await Company.find({}).populate('subscriptionPlan');
    
    console.log(`\n📊 Found ${companies.length} total companies`);

    // Check each company's plan
    companies.forEach(company => {
      const planName = company.subscriptionPlan?.name || 'No Plan';
      console.log(`${company.name}: ${planName}`);
    });

    // Find companies with Enterprise plans
    const enterpriseCompanies = companies.filter(company => 
      company.subscriptionPlan?.name === 'Enterprise'
    );

    console.log(`\n🏢 ENTERPRISE COMPANIES: ${enterpriseCompanies.length}`);
    console.log('===============================');
    
    enterpriseCompanies.forEach(company => {
      console.log(`✅ ${company.name} - ${company.subscriptionPlan.name}`);
    });

    // Also check by plan ID
    const enterprisePlan = await SubscriptionPlan.findOne({ name: 'Enterprise' });
    if (enterprisePlan) {
      console.log(`\n🔍 Enterprise Plan ID: ${enterprisePlan._id}`);
      
      const companiesByPlanId = await Company.find({ 
        subscriptionPlan: enterprisePlan._id 
      }).populate('subscriptionPlan');
      
      console.log(`\n📊 Companies with Enterprise Plan ID: ${companiesByPlanId.length}`);
      companiesByPlanId.forEach(company => {
        console.log(`✅ ${company.name} - ${company.subscriptionPlan?.name}`);
      });
    }

  } catch (error) {
    console.error('Error checking Enterprise companies:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run the check
checkEnterpriseCompanies(); 