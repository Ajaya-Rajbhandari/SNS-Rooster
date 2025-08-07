// Script to sync Employee.isActive with User.isActive
const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const User = require('../models/User');
const Employee = require('../models/Employee');

const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/rooster';

async function syncEmployeeActiveStatus() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');

  const employees = await Employee.find({});
  let updated = 0;
  let missingUsers = 0;
  for (const emp of employees) {
    if (!emp.userId) {
      console.log(`Employee ${emp._id} (${emp.firstName} ${emp.lastName}) has no userId.`);
      continue;
    }
    const user = await User.findById(emp.userId);
    if (!user) {
      console.log(`No User found for Employee ${emp._id} (${emp.firstName} ${emp.lastName}) userId: ${emp.userId}`);
      missingUsers++;
      continue;
    }
    if (emp.isActive !== user.isActive) {
      console.log(`Syncing Employee ${emp._id} (${emp.firstName} ${emp.lastName}): ${emp.isActive} -> ${user.isActive}`);
      emp.isActive = user.isActive;
      await emp.save();
      updated++;
    }
  }
  console.log(`\nSync complete. Updated: ${updated}, Employees with missing users: ${missingUsers}`);
  await mongoose.disconnect();
}

syncEmployeeActiveStatus().catch(err => {
  console.error('Error during sync:', err);
  process.exit(1);
}); 