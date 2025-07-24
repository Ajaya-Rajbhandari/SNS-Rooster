const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
require('dotenv').config();

async function checkExistingEmails() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get all users
    const users = await User.find({}).select('email role companyId');
    console.log('\n👥 All users in the system:');
    users.forEach(user => {
      console.log(`- ${user.email} (${user.role}) - Company: ${user.companyId || 'N/A'}`);
    });

    // Get all companies
    const companies = await Company.find({}).select('name adminEmail domain subdomain');
    console.log('\n🏢 All companies in the system:');
    companies.forEach(company => {
      console.log(`- ${company.name} (${company.domain}) - Admin: ${company.adminEmail}`);
    });

    // Get admin emails specifically
    const adminEmails = users.filter(user => user.role === 'admin').map(user => user.email);
    console.log('\n🚫 Admin emails that are already taken:');
    adminEmails.forEach(email => {
      console.log(`- ${email}`);
    });

    console.log('\n💡 Available email patterns you can use:');
    console.log('- admin@newcompany1.com');
    console.log('- admin@newcompany2.com');
    console.log('- admin@newcompany3.com');
    console.log('- admin@testcompany4.com');
    console.log('- admin@testcompany5.com');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkExistingEmails(); 