const mongoose = require('mongoose');
require('dotenv').config();

async function checkCompanyUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('users');

    // Get the current company ID from the logs (687c6cf9fce054783b9af432)
    const currentCompanyId = '687c6cf9fce054783b9af432';
    
    console.log(`\nChecking users in company: ${currentCompanyId}`);
    
    const companyUsers = await collection.find({ companyId: currentCompanyId }).toArray();
    
    console.log(`\nFound ${companyUsers.length} users in current company:`);
    companyUsers.forEach(user => {
      console.log(`- Email: ${user.email}, Name: ${user.firstName} ${user.lastName}, Role: ${user.role}, Active: ${user.isActive}`);
    });

    // Check for the specific email
    const specificEmail = 'icerushhh@gmail.com';
    const usersWithEmail = await collection.find({ email: specificEmail }).toArray();
    
    console.log(`\nUsers with email ${specificEmail}:`);
    usersWithEmail.forEach(user => {
      console.log(`- User ID: ${user._id}, Company ID: ${user.companyId}, Name: ${user.firstName} ${user.lastName}, Role: ${user.role}`);
    });

    // Check if the email exists in current company
    const emailInCurrentCompany = companyUsers.find(user => user.email === specificEmail);
    if (emailInCurrentCompany) {
      console.log(`\n⚠️  Email ${specificEmail} already exists in current company!`);
      console.log(`   User: ${emailInCurrentCompany.firstName} ${emailInCurrentCompany.lastName} (${emailInCurrentCompany.role})`);
    } else {
      console.log(`\n✅ Email ${specificEmail} is available in current company`);
    }

  } catch (error) {
    console.error('Error checking company users:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkCompanyUsers(); 