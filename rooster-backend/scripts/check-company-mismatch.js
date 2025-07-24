const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const User = require('../models/User');
const Company = require('../models/Company');

async function checkCompanyMismatch() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const email = 'admin@cityexpress.com.au';

    // Find the user
    const user = await User.findOne({ email });
    
    if (!user) {
      console.log('❌ User not found');
      return;
    }

    console.log('=== USER INFO ===');
    console.log(`Email: ${user.email}`);
    console.log(`User's Company ID: ${user.companyId}`);

    // Find all companies
    const companies = await Company.find({}, 'name _id status');
    console.log('\n=== ALL COMPANIES ===');
    companies.forEach(company => {
      console.log(`- ${company.name} (${company._id}) - Status: ${company.status}`);
    });

    // Find the specific company the user belongs to
    const userCompany = await Company.findById(user.companyId);
    console.log(`\nUser's Company: ${userCompany?.name || 'Not found'} (${user.companyId})`);

    // Find the company that's being selected in the login (from the debug log)
    const loginCompanyId = '687c6cf9fce054783b9af432';
    const loginCompany = await Company.findById(loginCompanyId);
    console.log(`Login Company: ${loginCompany?.name || 'Not found'} (${loginCompanyId})`);

    // Check if we need to update the user's company
    if (user.companyId.toString() !== loginCompanyId) {
      console.log('\n⚠️ Company ID mismatch detected!');
      console.log('The login is trying to use a different company than the user belongs to.');
      
      if (loginCompany) {
        console.log(`\nUpdating user to belong to: ${loginCompany.name}`);
        user.companyId = loginCompany._id;
        await user.save();
        console.log('✅ User company updated!');
      } else {
        console.log('\nThe login company ID does not exist. Creating it...');
        const newCompany = new Company({
          name: 'Cit Express',
          domain: 'cityexpress.com.au',
          subdomain: 'cityexpress',
          adminEmail: 'admin@cityexpress.com.au',
          status: 'active',
          features: {
            attendance: true,
            payroll: true,
            leaveManagement: true,
            analytics: true,
            documentManagement: true,
            notifications: true,
            customBranding: true,
            apiAccess: true,
            multiLocation: true,
            advancedReporting: true,
            timeTracking: true,
            expenseManagement: true,
            performanceReviews: true,
            trainingManagement: true
          },
          limits: {
            maxEmployees: 1000,
            maxStorageGB: 100,
            retentionDays: 365,
            maxApiCallsPerDay: 10000,
            maxLocations: 10
          },
          createdBy: user._id
        });
        await newCompany.save();
        console.log(`✅ Created new company: ${newCompany.name} (${newCompany._id})`);
        
        user.companyId = newCompany._id;
        await user.save();
        console.log('✅ User assigned to new company!');
      }
    } else {
      console.log('\n✅ Company IDs match!');
    }

  } catch (error) {
    console.error('Error checking company mismatch:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
checkCompanyMismatch(); 