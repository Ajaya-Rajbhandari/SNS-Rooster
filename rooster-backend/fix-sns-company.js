const mongoose = require('mongoose');
const Company = require('./models/Company');
const AdminSettings = require('./models/AdminSettings');

async function fixSnsCompany() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Find the SNS Rooster Test Company
    const snsCompany = await Company.findOne({ 
      name: { $regex: /sns rooster test company/i }
    });

    if (!snsCompany) {
      console.log('❌ SNS Rooster Test Company not found');
      return;
    }

    console.log('✅ Found SNS Rooster Test Company:', snsCompany.name);
    console.log('Company details:');
    console.log('  Name:', snsCompany.name);
    console.log('  Admin Email:', snsCompany.adminEmail);
    console.log('  Contact Phone:', snsCompany.contactPhone);
    console.log('  Address:', JSON.stringify(snsCompany.address));

    // Check current AdminSettings
    const currentSettings = await AdminSettings.findOne({ companyId: snsCompany._id });
    console.log('\nCurrent AdminSettings:');
    if (currentSettings && currentSettings.companyInfo) {
      console.log('  Name:', currentSettings.companyInfo.name);
      console.log('  Email:', currentSettings.companyInfo.email);
      console.log('  Phone:', currentSettings.companyInfo.phone);
      console.log('  Address:', currentSettings.companyInfo.address);
    } else {
      console.log('  No AdminSettings found');
    }

    // Update AdminSettings with correct company info
    const companyInfo = {
      name: 'SNS Tech Services', // Set the name that should appear
      legalName: 'SNS Tech Services',
      address: snsCompany.address?.street || '123 Tech Street',
      city: snsCompany.address?.city || 'Tech City',
      state: snsCompany.address?.state || 'Tech State',
      postalCode: snsCompany.address?.postalCode || '12345',
      country: snsCompany.address?.country || 'United States',
      phone: snsCompany.contactPhone || '+1-555-0123',
      email: snsCompany.adminEmail || 'admin@snstech.com',
      website: 'https://snstech.com',
      description: 'Leading technology services company',
      industry: 'Technology',
      employeeCount: '11-50'
    };

    console.log('\n📝 Updating AdminSettings with:');
    console.log('  Name:', companyInfo.name);
    console.log('  Email:', companyInfo.email);
    console.log('  Phone:', companyInfo.phone);
    console.log('  Address:', companyInfo.address);

    // Update AdminSettings
    await AdminSettings.updateSettings({ companyInfo }, snsCompany._id);
    console.log('✅ AdminSettings updated successfully');

    // Verify the update
    const updatedSettings = await AdminSettings.findOne({ companyId: snsCompany._id });
    console.log('\n✅ Updated AdminSettings:');
    console.log('  Name:', updatedSettings.companyInfo.name);
    console.log('  Email:', updatedSettings.companyInfo.email);
    console.log('  Phone:', updatedSettings.companyInfo.phone);
    console.log('  Address:', updatedSettings.companyInfo.address);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixSnsCompany(); 