const mongoose = require('mongoose');
const Company = require('./models/Company');
const AdminSettings = require('./models/AdminSettings');

async function checkCitExpressVsSns() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Find Cit Express company
    const citExpress = await Company.findOne({ 
      name: { $regex: /cit express/i }
    });

    // Find SNS Tech Services company
    const snsTech = await Company.findOne({ 
      name: { $regex: /sns tech services/i }
    });

    console.log('\n=== CIT EXPRESS ===');
    if (citExpress) {
      console.log('Company:', citExpress.name);
      console.log('Domain:', citExpress.domain);
      console.log('Admin Email:', citExpress.adminEmail);
      
      const citSettings = await AdminSettings.findOne({ companyId: citExpress._id });
      if (citSettings && citSettings.companyInfo) {
        console.log('AdminSettings Name:', citSettings.companyInfo.name);
        console.log('AdminSettings Email:', citSettings.companyInfo.email);
        console.log('AdminSettings Phone:', citSettings.companyInfo.phone || 'EMPTY');
        console.log('AdminSettings Address:', citSettings.companyInfo.address || 'EMPTY');
        console.log('AdminSettings City:', citSettings.companyInfo.city || 'EMPTY');
        console.log('AdminSettings Website:', citSettings.companyInfo.website || 'EMPTY');
      } else {
        console.log('AdminSettings: Missing');
      }
    } else {
      console.log('Cit Express not found');
    }

    console.log('\n=== SNS TECH SERVICES ===');
    if (snsTech) {
      console.log('Company:', snsTech.name);
      console.log('Domain:', snsTech.domain);
      console.log('Admin Email:', snsTech.adminEmail);
      
      const snsSettings = await AdminSettings.findOne({ companyId: snsTech._id });
      if (snsSettings && snsSettings.companyInfo) {
        console.log('AdminSettings Name:', snsSettings.companyInfo.name);
        console.log('AdminSettings Email:', snsSettings.companyInfo.email);
        console.log('AdminSettings Phone:', snsSettings.companyInfo.phone || 'EMPTY');
        console.log('AdminSettings Address:', snsSettings.companyInfo.address || 'EMPTY');
        console.log('AdminSettings City:', snsSettings.companyInfo.city || 'EMPTY');
        console.log('AdminSettings Website:', snsSettings.companyInfo.website || 'EMPTY');
      } else {
        console.log('AdminSettings: Missing');
      }
    } else {
      console.log('SNS Tech Services not found');
    }

    // Check if there's a company with "SNS Tech Services" name in AdminSettings
    console.log('\n=== SEARCHING FOR SNS TECH SERVICES IN ADMINSETTINGS ===');
    const allSettings = await AdminSettings.find({});
    for (const setting of allSettings) {
      if (setting.companyInfo && setting.companyInfo.name && 
          setting.companyInfo.name.toLowerCase().includes('sns tech')) {
        console.log('Found AdminSettings with SNS Tech name:');
        console.log('  Company ID:', setting.companyId);
        console.log('  Name:', setting.companyInfo.name);
        console.log('  Email:', setting.companyInfo.email);
        console.log('  Phone:', setting.companyInfo.phone || 'EMPTY');
        console.log('  Address:', setting.companyInfo.address || 'EMPTY');
        
        // Find the company for this AdminSettings
        const company = await Company.findById(setting.companyId);
        if (company) {
          console.log('  Company Name:', company.name);
          console.log('  Company Domain:', company.domain);
        }
      }
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

checkCitExpressVsSns(); 