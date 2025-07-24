const mongoose = require('mongoose');
const Company = require('../models/Company');
require('dotenv').config();

async function updateCompanyDetails() {
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

    console.log('✅ Found Cit Express company, updating details...');

    // Update company details
    const updatedCompany = await Company.findByIdAndUpdate(
      citExpressCompany._id,
      {
        name: 'Cit Express',
        domain: 'cityexpress.com.au',
        subdomain: 'cityexpress',
        status: 'active',
        address: {
          street: '123 Business Street',
          city: 'Sydney',
          state: 'NSW',
          postalCode: '2000',
          country: 'Australia'
        },
        phone: '+61 2 1234 5678',
        email: 'info@cityexpress.com.au',
        website: 'https://cityexpress.com.au',
        industry: 'Transportation & Logistics',
        size: '50-100 employees',
        description: 'Leading transportation and logistics company in Australia',
        contactPerson: 'John Smith',
        contactPhone: '+61 2 1234 5678',
        contactEmail: 'john.smith@cityexpress.com.au'
      },
      { new: true }
    );

    console.log('✅ Company details updated successfully!');
    console.log('\n📋 Updated Company Details:');
    console.log('=====================================');
    console.log(`- Name: ${updatedCompany.name}`);
    console.log(`- Domain: ${updatedCompany.domain}`);
    console.log(`- Subdomain: ${updatedCompany.subdomain}`);
    console.log(`- Status: ${updatedCompany.status}`);
    console.log(`- Phone: ${updatedCompany.phone}`);
    console.log(`- Email: ${updatedCompany.email}`);
    console.log(`- Website: ${updatedCompany.website}`);
    console.log(`- Industry: ${updatedCompany.industry}`);
    console.log(`- Size: ${updatedCompany.size}`);
    console.log(`- Description: ${updatedCompany.description}`);
    console.log(`- Contact Person: ${updatedCompany.contactPerson}`);
    console.log(`- Contact Phone: ${updatedCompany.contactPhone}`);
    console.log(`- Contact Email: ${updatedCompany.contactEmail}`);
    console.log(`- Address: ${updatedCompany.address.street}, ${updatedCompany.address.city}, ${updatedCompany.address.state} ${updatedCompany.address.postalCode}, ${updatedCompany.address.country}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

updateCompanyDetails(); 