const mongoose = require('mongoose');
const Company = require('./models/Company');
const User = require('./models/User');
require('dotenv').config();

// Use environment variable for MongoDB URI
const MONGODB_URI = process.env.MONGODB_URI;

async function checkCompanies() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all companies
    const companies = await Company.find({});
    console.log('\n🏢 All Companies:');
    companies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name} (ID: ${company._id})`);
    });

    // Find all users
    const users = await User.find({}).populate('companyId');
    console.log('\n👥 All Users:');
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (Role: ${user.role}) - Company: ${user.companyId?.name || 'None'}`);
    });

    // Find admin users specifically
    const adminUsers = await User.find({ role: 'admin' }).populate('companyId');
    console.log('\n👑 Admin Users:');
    adminUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} - Company: ${user.companyId?.name || 'None'}`);
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

checkCompanies(); 