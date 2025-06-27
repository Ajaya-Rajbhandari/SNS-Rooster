// This script ensures every user has a corresponding Employee document.
// If missing, it creates one with default values and the correct userId.

const mongoose = require('mongoose');
const User = require('../models/User');
const Employee = require('../models/Employee');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/sns-rooster';

async function syncUsersToEmployees() {
  await mongoose.connect(MONGO_URI);
  const users = await User.find();
  let created = 0;
  for (const user of users) {
    const existing = await Employee.findOne({ userId: user._id });
    if (!existing) {
      const emp = new Employee({
        firstName: user.firstName || user.name?.split(' ')[0] || 'First',
        lastName: user.lastName || user.name?.split(' ')[1] || 'Last',
        email: user.email,
        employeeId: user.employeeId || `EMP${user._id.toString().slice(-5)}`,
        userId: user._id,
        position: user.position || '',
        department: user.department || '',
      });
      await emp.save();
      console.log(`Created Employee for user ${user.email}`);
      created++;
    }
  }
  console.log(`Sync complete. Created ${created} new Employee records.`);
  await mongoose.disconnect();
}

syncUsersToEmployees().catch(err => {
  console.error('Error syncing users to employees:', err);
  process.exit(1);
});