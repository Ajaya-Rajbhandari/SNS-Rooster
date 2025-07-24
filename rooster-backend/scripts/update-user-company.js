const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');

async function updateUserCompany() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('Connected to MongoDB\n');

    // List all companies
    const companies = await Company.find({}).populate('subscriptionPlan');
    console.log('📊 Available Companies:');
    console.log('=======================');
    companies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name} (${company._id})`);
      console.log(`   Plan: ${company.subscriptionPlan?.name || 'No Plan'}`);
      console.log(`   Status: ${company.status}`);
      console.log('');
    });

    // Find users with the invalid company ID
    const invalidCompanyId = '687c6cf9fce054783b9af432';
    const usersWithInvalidCompany = await User.find({ companyId: invalidCompanyId });
    
    console.log(`🔍 Users with invalid company ID (${invalidCompanyId}):`);
    console.log('==================================================');
    if (usersWithInvalidCompany.length > 0) {
      usersWithInvalidCompany.forEach((user, index) => {
        console.log(`${index + 1}. ${user.email} (${user._id})`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Company ID: ${user.companyId}`);
        console.log('');
      });
    } else {
      console.log('No users found with invalid company ID');
    }

    // Find all users
    const allUsers = await User.find({}).populate('companyId');
    console.log('👥 All Users:');
    console.log('=============');
    allUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (${user._id})`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Company: ${user.companyId?.name || 'No Company'} (${user.companyId?._id || 'No ID'})`);
      console.log('');
    });

    // Update users with invalid company ID to use the first available company
    if (usersWithInvalidCompany.length > 0 && companies.length > 0) {
      const targetCompany = companies[0]; // Use the first company
      console.log(`🔄 Updating users to use company: ${targetCompany.name} (${targetCompany._id})`);
      
      for (const user of usersWithInvalidCompany) {
        user.companyId = targetCompany._id;
        await user.save();
        console.log(`✅ Updated user ${user.email} to company ${targetCompany.name}`);
      }
      
      console.log('\n🎯 After update, users should now see:');
      console.log(`Plan: ${targetCompany.subscriptionPlan?.name || 'No Plan'}`);
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

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

updateUserCompany(); 