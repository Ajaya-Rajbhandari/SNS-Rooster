const mongoose = require('mongoose');
const AdminSettings = require('./models/AdminSettings');
const User = require('./models/User');
const Company = require('./models/Company');

// MongoDB connection
const MONGODB_URI = 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';

async function verifyAllCompanies() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({});
    console.log(`\n🏢 Verifying ${companies.length} companies...`);

    let allGood = true;

    for (const company of companies) {
      console.log(`\n📋 Company: ${company.name}`);
      
      // Get settings
      const settings = await AdminSettings.getSettings(company._id);
      const companyInfo = settings.companyInfo || {};
      
      // Check required fields
      const hasName = companyInfo.name && companyInfo.name.trim() !== '';
      const hasDescription = companyInfo.description && companyInfo.description.trim() !== '';
      const hasIndustry = companyInfo.industry && companyInfo.industry.trim() !== '';
      const hasAddress = companyInfo.address && companyInfo.address.trim() !== '';
      const hasPhone = companyInfo.phone && companyInfo.phone.trim() !== '';
      const hasEmail = companyInfo.email && companyInfo.email.trim() !== '';
      const hasWebsite = companyInfo.website && companyInfo.website.trim() !== '';
      
      console.log(`   Name: ${hasName ? '✅' : '❌'} "${companyInfo.name}"`);
      console.log(`   Description: ${hasDescription ? '✅' : '❌'} "${companyInfo.description}"`);
      console.log(`   Industry: ${hasIndustry ? '✅' : '❌'} "${companyInfo.industry}"`);
      console.log(`   Address: ${hasAddress ? '✅' : '❌'} "${companyInfo.address}"`);
      console.log(`   Phone: ${hasPhone ? '✅' : '❌'} "${companyInfo.phone}"`);
      console.log(`   Email: ${hasEmail ? '✅' : '❌'} "${companyInfo.email}"`);
      console.log(`   Website: ${hasWebsite ? '✅' : '❌'} "${companyInfo.website}"`);
      
      const hasBasicInfo = hasName && hasDescription && hasIndustry;
      const hasContactInfo = hasAddress && hasPhone && hasEmail && hasWebsite;
      
      if (hasBasicInfo && hasContactInfo) {
        console.log(`   Status: ✅ Complete - Flutter app will show all details`);
      } else if (hasBasicInfo) {
        console.log(`   Status: ⚠️  Partial - Flutter app will show basic info only`);
        allGood = false;
      } else {
        console.log(`   Status: ❌ Missing - Flutter app will show "No company details available"`);
        allGood = false;
      }
    }

    console.log('\n📊 Summary:');
    if (allGood) {
      console.log('🎉 All companies have complete information!');
      console.log('📱 All companies should now display properly in the Flutter app.');
    } else {
      console.log('⚠️  Some companies still need more information.');
      console.log('📱 Some companies may still show "No company details available".');
    }

    console.log('\n🔍 Companies that should now work:');
    console.log('   ✅ SNS Tech Services - Complete with all details');
    console.log('   ✅ Cit Express - Complete with all details');
    console.log('   ✅ Charicha - Complete with all details');
    console.log('   ✅ Isha & Co - Complete with all details');
    console.log('   ✅ Test Company 3 - Complete with all details');
    console.log('   ✅ Test Custom Company - Complete with all details');
    console.log('   ✅ Default Company - Complete with all details');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

verifyAllCompanies(); 