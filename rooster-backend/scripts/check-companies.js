const mongoose = require('mongoose');
const Company = require('../models/Company');

async function checkCompanies() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    const companies = await Company.find({}).populate('subscriptionPlan');
    
    console.log('📊 All Companies and Their Plans:');
    console.log('==================================');
    
    companies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name}`);
      console.log(`   Plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
      console.log(`   Status: ${company.status}`);
      console.log(`   Features: ${company.features ? 'Loaded' : 'Not Loaded'}`);
      console.log('');
    });

    // Check for Enterprise plans
    const enterpriseCompanies = companies.filter(c => c.subscriptionPlan?.name === 'Enterprise');
    if (enterpriseCompanies.length > 0) {
      console.log('🏢 Companies with Enterprise Plan:');
      console.log('==================================');
      enterpriseCompanies.forEach(company => {
        console.log(`- ${company.name}`);
      });
      console.log('');
    } else {
      console.log('ℹ️  No companies found with Enterprise plan');
      console.log('');
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkCompanies(); 