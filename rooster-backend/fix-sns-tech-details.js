const mongoose = require('mongoose');
const Company = require('./models/Company');
const AdminSettings = require('./models/AdminSettings');

async function fixSnsTechDetails() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Find the SNS Tech Services AdminSettings
    const snsSettings = await AdminSettings.findOne({
      'companyInfo.name': { $regex: /sns tech services/i }
    });

    if (!snsSettings) {
      console.log('❌ SNS Tech Services AdminSettings not found');
      return;
    }

    console.log('✅ Found SNS Tech Services AdminSettings');
    console.log('Current details:');
    console.log('  Name:', snsSettings.companyInfo.name);
    console.log('  Email:', snsSettings.companyInfo.email);
    console.log('  Phone:', snsSettings.companyInfo.phone || 'EMPTY');
    console.log('  Address:', snsSettings.companyInfo.address || 'EMPTY');
    console.log('  City:', snsSettings.companyInfo.city || 'EMPTY');
    console.log('  State:', snsSettings.companyInfo.state || 'EMPTY');
    console.log('  Website:', snsSettings.companyInfo.website || 'EMPTY');

    // Update with complete company details
    const updatedCompanyInfo = {
      name: 'SNS Tech Services',
      legalName: 'SNS Tech Services',
      address: '123 Tech Street',
      city: 'Tech City',
      state: 'Tech State',
      postalCode: '12345',
      country: 'United States',
      phone: '+1-555-0123',
      email: 'admin@snsrooster.com',
      website: 'https://snstech.com',
      description: 'Leading technology services company',
      industry: 'Technology',
      employeeCount: '11-50'
    };

    console.log('\n📝 Updating with complete details:');
    console.log('  Name:', updatedCompanyInfo.name);
    console.log('  Email:', updatedCompanyInfo.email);
    console.log('  Phone:', updatedCompanyInfo.phone);
    console.log('  Address:', updatedCompanyInfo.address);
    console.log('  City:', updatedCompanyInfo.city);
    console.log('  State:', updatedCompanyInfo.state);
    console.log('  Website:', updatedCompanyInfo.website);

    // Update the AdminSettings
    snsSettings.companyInfo = updatedCompanyInfo;
    await snsSettings.save();

    console.log('\n✅ AdminSettings updated successfully');

    // Verify the update
    const updatedSettings = await AdminSettings.findById(snsSettings._id);
    console.log('\n✅ Updated AdminSettings:');
    console.log('  Name:', updatedSettings.companyInfo.name);
    console.log('  Email:', updatedSettings.companyInfo.email);
    console.log('  Phone:', updatedSettings.companyInfo.phone);
    console.log('  Address:', updatedSettings.companyInfo.address);
    console.log('  City:', updatedSettings.companyInfo.city);
    console.log('  State:', updatedSettings.companyInfo.state);
    console.log('  Website:', updatedSettings.companyInfo.website);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixSnsTechDetails(); 