const mongoose = require('mongoose');

// MongoDB connection
const MONGODB_URI = 'mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0';

async function updateCompanyUsage() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Import models
    const User = require('../models/User');
    const Company = require('../models/Company');

    console.log('\n🎯 ===== UPDATING COMPANY USAGE =====\n');

    // Get all companies
    const companies = await Company.find();
    console.log(`Found ${companies.length} companies to update`);

    let updatedCount = 0;

    for (const company of companies) {
      console.log(`\n🏢 Processing: ${company.name}`);
      
      // Count employees for this company
      const employeeCount = await User.countDocuments({ 
        companyId: company._id,
        role: { $ne: 'super_admin' }
      });

      console.log(`   Employee count: ${employeeCount}`);

      // Initialize usage object if it doesn't exist
      if (!company.usage) {
        company.usage = {};
      }

      // Update usage data
      const oldEmployeeCount = company.usage.currentEmployeeCount || 0;
      company.usage.currentEmployeeCount = employeeCount;
      company.usage.lastUsageUpdate = new Date();

      // Only save if there's a change
      if (oldEmployeeCount !== employeeCount) {
        await company.save();
        console.log(`   ✅ Updated employee count: ${oldEmployeeCount} → ${employeeCount}`);
        updatedCount++;
      } else {
        console.log(`   ⏭️  No change needed (${employeeCount} employees)`);
      }
    }

    console.log('\n ===== UPDATE COMPLETE =====');
    console.log(`📊 Updated ${updatedCount} companies with current usage data`);
    console.log('💡 Company Settings should now show correct employee counts');

  } catch (error) {
    console.error('❌ Error updating company usage:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

updateCompanyUsage(); 