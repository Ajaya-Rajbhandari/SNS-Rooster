const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function listAllCompanies() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    const companies = await Company.find({}).populate('subscriptionPlan');
    
    console.log('📊 All Companies:');
    console.log('================');
    
    companies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name}`);
      console.log(`   ID: ${company._id}`);
      console.log(`   Plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
      console.log(`   Status: ${company.status}`);
      console.log(`   Features: ${company.features ? 'Loaded' : 'Not Loaded'}`);
      console.log('');
    });

    // Check for the specific ID from frontend
    const frontendCompanyId = '687c6cf9fce054783b9af432';
    console.log(`🔍 Looking for company with ID: ${frontendCompanyId}`);
    
    const foundCompany = companies.find(c => c._id.toString() === frontendCompanyId);
    if (foundCompany) {
      console.log(`✅ Found company: ${foundCompany.name}`);
    } else {
      console.log(`❌ Company with ID ${frontendCompanyId} not found`);
      console.log('Available company IDs:');
      companies.forEach(c => {
        console.log(`   ${c._id} -> ${c.name}`);
      });
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

listAllCompanies(); 