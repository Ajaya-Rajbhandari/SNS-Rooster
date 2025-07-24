const mongoose = require('mongoose');
const Company = require('../models/Company');
const AdminSettings = require('../models/AdminSettings');

async function initializeAdminSettingsForCompanies() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({});
    console.log(`Found ${companies.length} companies`);

    let initializedCount = 0;
    let skippedCount = 0;

    for (const company of companies) {
      console.log(`\n🔍 Processing company: ${company.name}`);
      
      // Check if AdminSettings already exist for this company
      const existingSettings = await AdminSettings.findOne({ companyId: company._id });
      
      if (existingSettings && existingSettings.companyInfo && existingSettings.companyInfo.name !== 'Your Company Name') {
        console.log(`✅ Company "${company.name}" already has AdminSettings with company info`);
        skippedCount++;
        continue;
      }

      // Prepare company info for AdminSettings
      const companyInfo = {
        name: company.name,
        legalName: company.name,
        address: company.address?.street || '',
        city: company.address?.city || '',
        state: company.address?.state || '',
        postalCode: company.address?.postalCode || '',
        country: company.address?.country || 'Nepal',
        phone: company.contactPhone || company.phone || '',
        email: company.adminEmail || company.email || '',
        website: company.website || '',
        description: company.description || '',
        industry: company.industry || '',
        employeeCount: '1-10' // Default for existing companies
      };

      console.log(`📝 Initializing AdminSettings for ${company.name}:`);
      console.log(`   Name: ${companyInfo.name}`);
      console.log(`   Email: ${companyInfo.email}`);
      console.log(`   Phone: ${companyInfo.phone}`);
      console.log(`   Address: ${companyInfo.address}`);

      // Update or create AdminSettings
      await AdminSettings.updateSettings({ companyInfo }, company._id);
      console.log(`✅ Initialized AdminSettings for ${company.name}`);
      initializedCount++;
    }

    console.log('\n🎉 AdminSettings initialization completed!');
    console.log(`\n📋 Summary:`);
    console.log(`- Companies processed: ${companies.length}`);
    console.log(`- Settings initialized: ${initializedCount}`);
    console.log(`- Settings skipped (already exist): ${skippedCount}`);

  } catch (error) {
    console.error('Error initializing AdminSettings:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
initializeAdminSettingsForCompanies(); 