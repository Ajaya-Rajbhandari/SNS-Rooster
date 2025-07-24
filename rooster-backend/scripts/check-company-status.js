const mongoose = require('mongoose');
const Company = require('../models/Company');
const User = require('../models/User');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function checkCompanyStatus() {
  try {
    console.log('🔍 CHECKING COMPANY STATUS');
    console.log('==========================');
    
    // Get all companies
    const companies = await Company.find({});
    console.log(`📊 Total Companies: ${companies.length}`);
    
    companies.forEach((company, index) => {
      console.log(`\n🏢 Company ${index + 1}:`);
      console.log(`   ID: ${company._id}`);
      console.log(`   Name: ${company.name}`);
      console.log(`   Domain: ${company.domain}`);
      console.log(`   Status: ${company.status}`);
      console.log(`   Created: ${company.createdAt}`);
      console.log(`   Updated: ${company.updatedAt}`);
    });
    
    // Get all users
    const users = await User.find({});
    console.log(`\n👥 Total Users: ${users.length}`);
    
    users.forEach((user, index) => {
      console.log(`\n👤 User ${index + 1}:`);
      console.log(`   ID: ${user._id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Company ID: ${user.companyId}`);
      console.log(`   Is Active: ${user.isActive}`);
      console.log(`   Email Verified: ${user.isEmailVerified}`);
    });
    
    // Check for inactive companies
    const inactiveCompanies = companies.filter(c => c.status !== 'active');
    if (inactiveCompanies.length > 0) {
      console.log(`\n⚠️  INACTIVE COMPANIES (${inactiveCompanies.length}):`);
      inactiveCompanies.forEach(company => {
        console.log(`   - ${company.name} (${company._id}): ${company.status}`);
      });
    }
    
    // Check for users without company
    const usersWithoutCompany = users.filter(u => !u.companyId);
    if (usersWithoutCompany.length > 0) {
      console.log(`\n⚠️  USERS WITHOUT COMPANY (${usersWithoutCompany.length}):`);
      usersWithoutCompany.forEach(user => {
        console.log(`   - ${user.email} (${user._id})`);
      });
    }
    
    console.log('\n==========================');
    
  } catch (error) {
    console.error('❌ Error checking company status:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the check
checkCompanyStatus(); 