const mongoose = require('mongoose');
require('dotenv').config();

async function checkRecentUser() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');
    const employeesCollection = db.collection('employees');

    // Get the current company ID
    const currentCompanyId = '687c6cf9fce054783b9af432';
    
    console.log(`\nChecking users in company: ${currentCompanyId}`);
    
    // Find all users in the current company
    const companyUsers = await usersCollection.find({ companyId: currentCompanyId }).toArray();
    
    console.log(`\nFound ${companyUsers.length} users in current company:`);
    companyUsers.forEach(user => {
      console.log(`- ID: ${user._id}`);
      console.log(`  Email: ${user.email}`);
      console.log(`  Name: ${user.firstName} ${user.lastName}`);
      console.log(`  Role: ${user.role}`);
      console.log(`  Active: ${user.isActive}`);
      console.log(`  Company ID: ${user.companyId}`);
      console.log('  ---');
    });

    // Check for the specific email
    const specificEmail = 'icerushhh@gmail.com';
    const usersWithEmail = await usersCollection.find({ email: specificEmail }).toArray();
    
    console.log(`\nUsers with email ${specificEmail}:`);
    usersWithEmail.forEach(user => {
      console.log(`- User ID: ${user._id}`);
      console.log(`  Company ID: ${user.companyId}`);
      console.log(`  Name: ${user.firstName} ${user.lastName}`);
      console.log(`  Role: ${user.role}`);
      console.log(`  Active: ${user.isActive}`);
      console.log('  ---');
    });

    // Check if there are any employees for the current company
    const companyEmployees = await employeesCollection.find({ companyId: currentCompanyId }).toArray();
    
    console.log(`\nFound ${companyEmployees.length} employees in current company:`);
    companyEmployees.forEach(employee => {
      console.log(`- Employee ID: ${employee._id}`);
      console.log(`  User ID: ${employee.userId}`);
      console.log(`  Name: ${employee.firstName} ${employee.lastName}`);
      console.log(`  Email: ${employee.email}`);
      console.log(`  Position: ${employee.position}`);
      console.log(`  Department: ${employee.department}`);
      console.log('  ---');
    });

    // Check if the specific user has an employee record
    const userWithEmail = usersWithEmail.find(u => u.companyId === currentCompanyId);
    if (userWithEmail) {
      const employeeRecord = await employeesCollection.findOne({ userId: userWithEmail._id });
      if (employeeRecord) {
        console.log(`\n✅ User ${specificEmail} has an employee record:`);
        console.log(`   Employee ID: ${employeeRecord._id}`);
        console.log(`   Position: ${employeeRecord.position}`);
        console.log(`   Department: ${employeeRecord.department}`);
      } else {
        console.log(`\n⚠️  User ${specificEmail} does NOT have an employee record`);
        console.log(`   This user needs to be converted to an employee via the Add Employee dialog`);
      }
    }

  } catch (error) {
    console.error('Error checking recent user:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkRecentUser(); 