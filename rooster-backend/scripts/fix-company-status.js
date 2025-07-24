const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');

async function fixCompanyStatus() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the company
    const company = await Company.findById('6878868f48b4e1e8f9fd9d16');
    
    if (!company) {
      console.log('❌ Company not found');
      return;
    }

    console.log(`Current company: ${company.name}`);
    console.log(`Current status: ${company.status}`);

    // Update company status to active
    company.status = 'active';
    await company.save();

    console.log('✅ Company status updated to "active"');
    console.log('Now you should be able to log in!');

  } catch (error) {
    console.error('Error fixing company status:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
fixCompanyStatus(); 