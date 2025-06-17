const mongoose = require('mongoose');
const User = require('../models/User');

async function checkUsers() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');
    
    const users = await User.find({}, 'email role firstName lastName');
    console.log('Users in database:');
    users.forEach(user => {
      const fullName = user.firstName && user.lastName ? `${user.firstName} ${user.lastName}` : 'N/A';
      console.log(`- Email: ${user.email}, Role: ${user.role}, Name: ${fullName}`);
    });
    
    console.log(`\nTotal users: ${users.length}`);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

checkUsers();