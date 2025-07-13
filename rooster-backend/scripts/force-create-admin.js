const mongoose = require('mongoose');
const User = require('../models/User');

async function forceCreateAdmin() {
  try {
    // Connect to MongoDB Atlas
    await mongoose.connect('mongodb+srv://ajaya:ysjevCMEPSwMcCDl@cluster0.1ufkdju.mongodb.net/sns-rooster?retryWrites=true&w=majority&appName=Cluster0');
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