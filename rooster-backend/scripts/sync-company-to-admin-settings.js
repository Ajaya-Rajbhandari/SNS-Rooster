const mongoose = require('mongoose');
const Company = require('../models/Company');
const AdminSettings = require('../models/AdminSettings');
require('dotenv').config();

async function syncCompanyToAdminSettings() {
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

    console.log('✅ Found Cit Express company:', citExpressCompany.name);

    // Prepare company info for admin settings
    const companyInfo = {
      name: citExpressCompany.name,
      legalName: citExpressCompany.name,
      address: citExpressCompany.address?.street || '',
      city: citExpressCompany.address?.city || '',
      state: citExpressCompany.address?.state || '',
      postalCode: citExpressCompany.address?.postalCode || '',
      country: citExpressCompany.address?.country || 'Australia',
      phone: citExpressCompany.phone || '',
      email: citExpressCompany.email || '',
      website: citExpressCompany.website || '',
      description: citExpressCompany.description || '',
      industry: citExpressCompany.industry || '',
      employeeCount: '51-200' // Use valid enum value: '1-10', '11-50', '51-200', '201-500', '500+'
    };

    console.log('📋 Company info to sync:', companyInfo);

    // Update admin settings with company info
    const adminSettings = await AdminSettings.updateSettings(
      { companyInfo },
      citExpressCompany._id
    );

    console.log('✅ Successfully synced company info to admin settings!');
    console.log('\n📋 Updated Admin Settings:');
    console.log('=====================================');
    console.log(`- Company Name: ${adminSettings.companyInfo.name}`);
    console.log(`- Legal Name: ${adminSettings.companyInfo.legalName}`);
    console.log(`- Address: ${adminSettings.companyInfo.address}`);
    console.log(`- City: ${adminSettings.companyInfo.city}`);
    console.log(`- State: ${adminSettings.companyInfo.state}`);
    console.log(`- Postal Code: ${adminSettings.companyInfo.postalCode}`);
    console.log(`- Country: ${adminSettings.companyInfo.country}`);
    console.log(`- Phone: ${adminSettings.companyInfo.phone}`);
    console.log(`- Email: ${adminSettings.companyInfo.email}`);
    console.log(`- Website: ${adminSettings.companyInfo.website}`);
    console.log(`- Description: ${adminSettings.companyInfo.description}`);
    console.log(`- Industry: ${adminSettings.companyInfo.industry}`);
    console.log(`- Employee Count: ${adminSettings.companyInfo.employeeCount}`);

    // Test the API endpoint
    console.log('\n🔍 Testing API endpoint...');
    const testSettings = await AdminSettings.getSettings(citExpressCompany._id);
    console.log('✅ Admin settings retrieved successfully');
    console.log(`- Company name from API: ${testSettings.companyInfo.name}`);
    console.log(`- Company email from API: ${testSettings.companyInfo.email}`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

syncCompanyToAdminSettings(); 