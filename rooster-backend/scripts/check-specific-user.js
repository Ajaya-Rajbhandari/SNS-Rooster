const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function checkSpecificUser() {
  try {
    console.log('🔍 CHECKING SPECIFIC USER');
    console.log('==========================');
    
    const userId = '687f28dad0e87379b9469385';
    
    // Check the specific user
    console.log(`\n📊 Checking user: ${userId}`);
    const user = await User.findById(userId).select('email firstName lastName role companyId');
    
    if (!user) {
      console.log('❌ User not found');
      return;
    }
    
    console.log(`   ✅ User found: ${user.email} (${user.firstName} ${user.lastName})`);
    console.log(`   - Role: ${user.role}`);
    console.log(`   - Company ID: ${user.companyId || 'NULL'}`);
    
    if (user.companyId) {
      // Check if the company exists
      const company = await Company.findById(user.companyId).select('name domain status');
      if (company) {
        console.log(`   - Company: ${company.name} (${company.domain})`);
        console.log(`   - Company Status: ${company.status}`);
      } else {
        console.log(`   ❌ Company not found for ID: ${user.companyId}`);
      }
    } else {
      console.log(`   ❌ User has no company ID`);
    }
    
    console.log('\n🎉 User check completed!');
    console.log('==========================');
    
  } catch (error) {
    console.error('❌ Error checking user:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the check
checkSpecificUser(); 