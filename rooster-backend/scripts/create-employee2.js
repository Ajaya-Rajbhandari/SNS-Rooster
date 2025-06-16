const mongoose = require('mongoose');
const User = require('../models/User');

async function createEmployee2() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Check if employee2 already exists
    const existingUser = await User.findOne({ email: 'employee2@snsrooster.com' });
    if (existingUser) {
      console.log('Employee2 already exists');
      console.log('Email:', existingUser.email);
      console.log('Password: Employee@456');
      console.log('Role:', existingUser.role);
      process.exit(0);
    }

    // Create employee2 user
    const employee2 = new User({
      firstName: 'Employee',
      lastName: 'Two',
      email: 'employee2@snsrooster.com',
      password: 'Employee@456',
      role: 'employee',
      department: 'HR',
      position: 'HR Assistant',
      isActive: true,
      isProfileComplete: true
    });

    await employee2.save();
    console.log('Employee2 created successfully');
    console.log('Email:', employee2.email);
    console.log('Password: Employee@456');
    console.log('Role:', employee2.role);
    console.log('Department:', employee2.department);
    console.log('Position:', employee2.position);

  } catch (error) {
    console.error('Error creating employee2:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

createEmployee2();