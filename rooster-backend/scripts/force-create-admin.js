const mongoose = require('mongoose');
const User = require('../models/User');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Use environment variable for MongoDB URI
const MONGODB_URI = process.env.MONGODB_URI;

async function forceCreateAdmin() {
  try {
    // Connect to MongoDB Atlas
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Delete existing admin if any
    await User.deleteMany({ email: 'admin@snsrooster.com' });
    console.log('Deleted any existing admin users');

    // Create admin user
    const admin = new User({
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@snsrooster.com',
      password: 'Admin@123',
      role: 'admin',
      department: 'Administration',
      position: 'Administrator',
      isActive: true
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

forceCreateAdmin();