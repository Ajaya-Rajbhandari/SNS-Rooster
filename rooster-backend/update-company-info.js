const mongoose = require('mongoose');
const AdminSettings = require('./models/AdminSettings');
const User = require('./models/User');
const Company = require('./models/Company');

// MongoDB connection
const MONGODB_URI = 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';

async function updateCompanyInfo() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find the SNS Tech company
    const company = await User.findOne({ 
      email: 'admin@snsrooster.com',
      role: 'admin'
    }).populate('companyId');

    if (!company) {
      console.log('❌ SNS Tech company admin not found');
      return;
    }

    console.log('🏢 Found company:', company.companyId.name);
    console.log('👤 Admin user:', company.email);

    // Get current settings
    const currentSettings = await AdminSettings.getSettings(company.companyId._id);
    console.log('\n📋 Current company info:');
    console.log(JSON.stringify(currentSettings.companyInfo, null, 2));

    // Update with some contact details
    const updatedCompanyInfo = {
      ...currentSettings.companyInfo,
      address: '123 Tech Street, Sydney NSW 2000',
      city: 'Sydney',
      state: 'NSW',
      postalCode: '2000',
      phone: '+61 2 1234 5678',
      email: 'info@snstechservices.com.au',
      website: 'https://www.snstechservices.com.au',
      taxId: 'ABN 12 345 678 901',
      registrationNumber: 'ACN 123 456 789'
    };

    console.log('\n📝 Updating company info with contact details...');
    
    // Update the settings
    const updatedSettings = await AdminSettings.updateSettings({
      companyInfo: updatedCompanyInfo
    }, company.companyId._id);

    console.log('\n✅ Updated company info:');
    console.log(JSON.stringify(updatedSettings.companyInfo, null, 2));

    console.log('\n🎯 Now test the Flutter app - it should show:');
    console.log('  ✅ Company Name: SNS Tech Services');
    console.log('  ✅ Description: Leading technology services company');
    console.log('  ✅ Industry: Technology');
    console.log('  ✅ Country: Nepal');
    console.log('  ✅ Address: 123 Tech Street, Sydney NSW 2000');
    console.log('  ✅ Phone: +61 2 1234 5678');
    console.log('  ✅ Email: info@snstechservices.com.au');
    console.log('  ✅ Website: https://www.snstechservices.com.au');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

updateCompanyInfo(); 