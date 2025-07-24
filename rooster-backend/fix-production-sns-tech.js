const mongoose = require('mongoose');
const Company = require('./models/Company');
const AdminSettings = require('./models/AdminSettings');

async function fixProductionSnsTech() {
  try {
    // Connect to production database (MongoDB Atlas)
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to production MongoDB');

    // Find the SNS Tech Services company in production
    const snsTechCompany = await Company.findOne({ 
      name: { $regex: /sns tech services/i }
    });

    if (!snsTechCompany) {
      console.log('❌ SNS Tech Services company not found in production database');
      return;
    }

    console.log('✅ Found SNS Tech Services in production:');
    console.log('  Company ID:', snsTechCompany._id);
    console.log('  Name:', snsTechCompany.name);
    console.log('  Domain:', snsTechCompany.domain);
    console.log('  Admin Email:', snsTechCompany.adminEmail);

    // Check current AdminSettings
    const currentSettings = await AdminSettings.findOne({ companyId: snsTechCompany._id });
    console.log('\nCurrent AdminSettings:');
    if (currentSettings && currentSettings.companyInfo) {
      console.log('  Name:', currentSettings.companyInfo.name);
      console.log('  Email:', currentSettings.companyInfo.email);
      console.log('  Phone:', currentSettings.companyInfo.phone || 'EMPTY');
      console.log('  Address:', currentSettings.companyInfo.address || 'EMPTY');
      console.log('  City:', currentSettings.companyInfo.city || 'EMPTY');
      console.log('  Website:', currentSettings.companyInfo.website || 'EMPTY');
    } else {
      console.log('  No AdminSettings found - will create new ones');
    }

    // Update with complete company details
    const companyInfo = {
      name: 'SNS Tech Services',
      legalName: 'SNS Tech Services',
      address: '123 Tech Street',
      city: 'Tech City',
      state: 'Tech State',
      postalCode: '12345',
      country: 'Australia',
      phone: '+61 2 1234 5678',
      email: snsTechCompany.adminEmail || 'sns@snstechservices',
      website: 'https://snstechservices.com.au',
      description: 'Leading technology services company',
      industry: 'Technology',
      employeeCount: '11-50'
    };

    console.log('\n📝 Updating AdminSettings with:');
    console.log('  Name:', companyInfo.name);
    console.log('  Email:', companyInfo.email);
    console.log('  Phone:', companyInfo.phone);
    console.log('  Address:', companyInfo.address);
    console.log('  City:', companyInfo.city);
    console.log('  Website:', companyInfo.website);

    // Update or create AdminSettings
    await AdminSettings.updateSettings({ companyInfo }, snsTechCompany._id);
    console.log('✅ AdminSettings updated successfully in production');

    // Verify the update
    const updatedSettings = await AdminSettings.findOne({ companyId: snsTechCompany._id });
    console.log('\n✅ Updated AdminSettings in production:');
    console.log('  Name:', updatedSettings.companyInfo.name);
    console.log('  Email:', updatedSettings.companyInfo.email);
    console.log('  Phone:', updatedSettings.companyInfo.phone);
    console.log('  Address:', updatedSettings.companyInfo.address);
    console.log('  City:', updatedSettings.companyInfo.city);
    console.log('  Website:', updatedSettings.companyInfo.website);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

fixProductionSnsTech(); 