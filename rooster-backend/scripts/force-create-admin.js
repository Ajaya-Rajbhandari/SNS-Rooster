require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company'); // Add this line

async function createAdminUser() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Find the company (adjust the domain as needed)
    const company = await Company.findOne({ domain: 'snsrooster.com' });
    if (!company) {
      console.error('Company not found!');
      process.exit(1);
    }

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@snsrooster.com', companyId: company._id });
    if (existingAdmin) {
      console.log('Admin user already exists');
      process.exit(0);
    }

    // Create admin user
    const admin = new User({
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@snsrooster.com',
      password: 'Admin@123',
      role: 'admin',
      isActive: true,
      companyId: company._id // <-- Set companyId here
    });

    await admin.save();
    console.log('Admin user created successfully');
    console.log('Email:', admin.email);
    console.log('Password: Admin@123');
    console.log('Role:', admin.role);

  } catch (error) {
    console.error('Error creating admin user:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

createAdminUser();