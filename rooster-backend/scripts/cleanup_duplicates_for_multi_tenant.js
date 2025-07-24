const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');
const Employee = require('../models/Employee');
const Attendance = require('../models/Attendance');
const Payroll = require('../models/Payroll');
const Leave = require('../models/Leave');
const BreakType = require('../models/BreakType');

// Set to true to actually remove duplicates, false to only log
const REMOVE_DUPLICATES = true;

async function cleanupDuplicates() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  // Helper to find and optionally remove duplicates
  async function processDuplicates(model, groupFields, modelName) {
    console.log(`\nChecking duplicates for ${modelName}...`);
    const pipeline = [
      { $group: {
          _id: groupFields.reduce((acc, f) => { acc[f] = `$${f}`; return acc; }, {}),
          count: { $sum: 1 },
          ids: { $push: '$_id' }
        }
      },
      { $match: { count: { $gt: 1 } } }
    ];
    const dups = await model.aggregate(pipeline);
    if (dups.length === 0) {
      console.log(`✅ No duplicates found for ${modelName}`);
      return;
    }
    for (const dup of dups) {
      console.log(`Found duplicate for ${modelName}:`, dup._id, `Count: ${dup.count}`);
      // Keep the first, remove the rest
      const toRemove = dup.ids.slice(1);
      if (REMOVE_DUPLICATES) {
        const res = await model.deleteMany({ _id: { $in: toRemove } });
        console.log(`  Removed ${res.deletedCount} duplicates.`);
      } else {
        console.log(`  Would remove:`, toRemove);
      }
    }
  }

  // Users: companyId + email
  await processDuplicates(User, ['companyId', 'email'], 'User');
  // Employees: companyId + email, companyId + employeeId
  await processDuplicates(Employee, ['companyId', 'email'], 'Employee (email)');
  await processDuplicates(Employee, ['companyId', 'employeeId'], 'Employee (employeeId)');
  // Attendance: companyId + user + date
  await processDuplicates(Attendance, ['companyId', 'user', 'date'], 'Attendance');
  // Payroll: companyId + employee + periodStart + periodEnd
  await processDuplicates(Payroll, ['companyId', 'employee', 'periodStart', 'periodEnd'], 'Payroll');
  // Leave: companyId + user + startDate + endDate
  await processDuplicates(Leave, ['companyId', 'user', 'startDate', 'endDate'], 'Leave');
  // BreakType: companyId + name
  await processDuplicates(BreakType, ['companyId', 'name'], 'BreakType');

  await mongoose.disconnect();
  console.log('Disconnected from MongoDB');
}

if (require.main === module) {
  cleanupDuplicates().catch(err => {
    console.error('Error during duplicate cleanup:', err);
    process.exit(1);
  });
}

module.exports = cleanupDuplicates; 