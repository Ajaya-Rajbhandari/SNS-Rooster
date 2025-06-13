const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    checkEmployees();
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

async function checkEmployees() {
  try {
    // Check employees collection
    const employeesCollection = mongoose.connection.db.collection('employees');
    const employees = await employeesCollection.find({}).toArray();
    
    console.log('\nEmployees in database:');
    employees.forEach((employee, index) => {
      console.log(`${index + 1}. ID: ${employee._id}`);
      console.log(`   Name: ${employee.name || 'N/A'}`);
      console.log(`   Email: ${employee.email || 'N/A'}`);
      console.log(`   Department: ${employee.department || 'N/A'}`);
      console.log(`   Position: ${employee.position || 'N/A'}`);
      console.log(`   Active: ${employee.active !== undefined ? employee.active : 'N/A'}`);
      console.log('---');
    });
    
    console.log(`\nTotal employees: ${employees.length}`);
    
    // Also check users collection for comparison
    const usersCollection = mongoose.connection.db.collection('users');
    const users = await usersCollection.find({}).toArray();
    console.log(`Total users: ${users.length}`);
    
    // List all collections in the database
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('\nAll collections in database:');
    collections.forEach(collection => {
      console.log(`- ${collection.name}`);
    });
    
  } catch (error) {
    console.error('Error checking employees:', error);
  } finally {
    mongoose.connection.close();
    process.exit(0);
  }
}