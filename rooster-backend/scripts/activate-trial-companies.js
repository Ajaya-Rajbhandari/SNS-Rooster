const mongoose = require('mongoose');
const Company = require('../models/Company');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function activateTrialCompanies() {
  try {
    console.log('🔧 ACTIVATING TRIAL COMPANIES');
    console.log('============================');
    
    // Find all companies with trial status
    const trialCompanies = await Company.find({ status: 'trial' });
    console.log(`📊 Found ${trialCompanies.length} companies with trial status`);
    
    if (trialCompanies.length === 0) {
      console.log('✅ No trial companies found. All companies are already active!');
      return;
    }
    
    // Activate each trial company
    for (const company of trialCompanies) {
      console.log(`\n🏢 Activating: ${company.name} (${company._id})`);
      
      company.status = 'active';
      await company.save();
      
      console.log(`   ✅ Status changed from 'trial' to 'active'`);
    }
    
    console.log(`\n🎉 Successfully activated ${trialCompanies.length} companies!`);
    console.log('============================');
    
  } catch (error) {
    console.error('❌ Error activating trial companies:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the activation
activateTrialCompanies(); 