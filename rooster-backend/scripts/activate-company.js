const mongoose = require('mongoose');
const Company = require('../models/Company');
require('dotenv').config();

async function activateCompany() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const company = await Company.findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    });

    if (!company) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found company:', {
      id: company._id,
      name: company.name,
      domain: company.domain,
      status: company.status
    });

    // Update company status to active
    const updatedCompany = await Company.findByIdAndUpdate(
      company._id,
      {
        status: 'active',
        trialEndDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year from now
      },
      { new: true }
    );

    console.log('✅ Company activated successfully:', {
      id: updatedCompany._id,
      name: updatedCompany.name,
      status: updatedCompany.status,
      trialEndDate: updatedCompany.trialEndDate
    });

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

activateCompany(); 