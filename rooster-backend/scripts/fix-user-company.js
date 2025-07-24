const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function fixUserCompany() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    // Find all companies
    const companies = await Company.find({}).populate('subscriptionPlan');
    console.log('📊 Available Companies:');
    companies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name} (${company._id})`);
      console.log(`   Plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
      console.log(`   Status: ${company.status}`);
      console.log('');
    });

    // Find users with invalid company ID
    const invalidCompanyId = '687c6cf9fce054783b9af432';
    const usersWithInvalidCompany = await User.find({ companyId: invalidCompanyId });
    
    console.log(`🔍 Found ${usersWithInvalidCompany.length} users with invalid company ID: ${invalidCompanyId}`);
    
    if (usersWithInvalidCompany.length > 0) {
      usersWithInvalidCompany.forEach((user, index) => {
        console.log(`${index + 1}. ${user.email} (${user._id})`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Company ID: ${user.companyId}`);
        console.log('');
      });

      // Update to the first available company (SNS Tech Services with Professional plan)
      if (companies.length > 0) {
        const targetCompany = companies[0]; // SNS Tech Services
        console.log(`🔄 Updating users to use company: ${targetCompany.name} (${targetCompany._id})`);
        
        for (const user of usersWithInvalidCompany) {
          user.companyId = targetCompany._id;
          await user.save();
          console.log(`✅ Updated user ${user.email} to company ${targetCompany.name}`);
        }
        
        console.log('\n🎯 After update, users should now see:');
        console.log(`Plan: ${targetCompany.subscriptionPlan?.name || 'No Plan'}`);
        console.log(`Company: ${targetCompany.name}`);
        
        if (targetCompany.subscriptionPlan?.features?.multiLocationSupport) {
          console.log('Location Management: ✅ Visible');
        } else {
          console.log('Location Management: ❌ Hidden');
        }
        
        if (targetCompany.subscriptionPlan?.features?.expenseManagement) {
          console.log('Expense Management: ✅ Visible');
        } else {
          console.log('Expense Management: ❌ Hidden');
        }
      }
    } else {
      console.log('✅ No users found with invalid company ID');
    }

    // Also check for users with no company ID
    const usersWithNoCompany = await User.find({ companyId: { $exists: false } });
    console.log(`\n🔍 Found ${usersWithNoCompany.length} users with no company ID`);
    
    if (usersWithNoCompany.length > 0 && companies.length > 0) {
      const targetCompany = companies[0];
      console.log(`🔄 Assigning users without company to: ${targetCompany.name}`);
      
      for (const user of usersWithNoCompany) {
        user.companyId = targetCompany._id;
        await user.save();
        console.log(`✅ Assigned user ${user.email} to company ${targetCompany.name}`);
      }
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

fixUserCompany(); 