const mongoose = require('mongoose');
require('dotenv').config();

async function checkUserCompanyMismatch() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');
    const companiesCollection = db.collection('companies');

    console.log('\n🔍 Checking User-Company Relationships...\n');

    // Check the specific user trying to login
    const loginEmail = 'sns@snstechservices.com.au';
    const selectedCompanyId = '6879eab877a3baf82927dabd';

    console.log(`📧 Login Attempt Details:`);
    console.log(`   Email: ${loginEmail}`);
    console.log(`   Selected Company ID: ${selectedCompanyId}`);

    // Find the user
    const user = await usersCollection.findOne({ email: loginEmail });
    if (!user) {
      console.log(`❌ User with email ${loginEmail} not found`);
      return;
    }

    console.log(`\n👤 User Found:`);
    console.log(`   User ID: ${user._id}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Name: ${user.name}`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Company ID: ${user.companyId || 'No company assigned'}`);

    // Find the selected company
    const selectedCompany = await companiesCollection.findOne({ 
      _id: new mongoose.Types.ObjectId(selectedCompanyId) 
    });

    if (!selectedCompany) {
      console.log(`❌ Selected company with ID ${selectedCompanyId} not found`);
      return;
    }

    console.log(`\n🏢 Selected Company:`);
    console.log(`   Company ID: ${selectedCompany._id}`);
    console.log(`   Name: ${selectedCompany.name}`);
    console.log(`   Domain: ${selectedCompany.domain}`);

    // Check if user belongs to selected company
    const userBelongsToCompany = user.companyId && user.companyId.toString() === selectedCompanyId;
    console.log(`\n🔗 User-Company Relationship:`);
    console.log(`   User belongs to selected company: ${userBelongsToCompany ? '✅ YES' : '❌ NO'}`);

    if (!userBelongsToCompany) {
      console.log(`\n🔧 Fix Options:`);
      console.log(`1. Update user's companyId to match selected company`);
      console.log(`2. Update selected company to match user's companyId`);
      console.log(`3. Create user in the selected company`);

      // Show all companies
      console.log(`\n📋 All Available Companies:`);
      const allCompanies = await companiesCollection.find({}).toArray();
      allCompanies.forEach(company => {
        console.log(`   - ${company.name} (${company._id})`);
      });

      // Show all users with this email
      console.log(`\n👥 All Users with Email ${loginEmail}:`);
      const allUsersWithEmail = await usersCollection.find({ email: loginEmail }).toArray();
      allUsersWithEmail.forEach(user => {
        console.log(`   - ${user.name} (${user._id}) - Company: ${user.companyId || 'None'}`);
      });
    }

    // Check if there are other users in the selected company
    console.log(`\n👥 Users in Selected Company (${selectedCompany.name}):`);
    const usersInCompany = await usersCollection.find({ 
      companyId: new mongoose.Types.ObjectId(selectedCompanyId) 
    }).toArray();
    
    if (usersInCompany.length === 0) {
      console.log(`   ❌ No users found in this company`);
    } else {
      usersInCompany.forEach(user => {
        console.log(`   - ${user.name} (${user.email}) - Role: ${user.role}`);
      });
    }

  } catch (error) {
    console.error('Error checking user-company mismatch:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkUserCompanyMismatch(); 