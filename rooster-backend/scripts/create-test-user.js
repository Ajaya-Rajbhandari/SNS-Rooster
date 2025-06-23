const mongoose = require('mongoose');
const User = require('../models/User');

async function createTestUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Check if test user already exists
    const existingUser = await User.findOne({ email: 'testuser@example.com' });
    if (existingUser) {
      console.log('Test user already exists');
      console.log('Email:', existingUser.email);
      console.log('Password: Test@123');
      console.log('Role:', existingUser.role);
      process.exit(0);
    }

    // Create test user
    const testUser = new User({
      firstName: 'Test',
      lastName: 'User',
      email: 'testuser@example.com',
      password: 'Test@123',
      role: 'employee',
      department: 'IT',
      position: 'Developer',
      isActive: true,
      isProfileComplete: true
    });

    await testUser.save();
    console.log('Test user created successfully');
    console.log('Email:', testUser.email);
    console.log('Password: Test@123');
    console.log('Role:', testUser.role);
    console.log('Department:', testUser.department);
    console.log('Position:', testUser.position);

  } catch (error) {
    console.error('Error creating test user:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

createTestUser();