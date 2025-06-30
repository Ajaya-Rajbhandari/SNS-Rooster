const mongoose = require('mongoose');
const Attendance = require('../models/Attendance');
const Employee = require('../models/Employee');
require('dotenv').config({ path: '../.env' });

async function insertTestAttendance(userId) {
  await mongoose.connect(process.env.MONGODB_URI);
  const employee = await Employee.findOne({ userId });
  if (!employee) {
    console.log('Employee not found for userId:', userId);
    return;
  }
  const now = new Date();
  const records = [];
  for (let i = 0; i < 7; i++) {
    const date = new Date(now);
    date.setDate(now.getDate() - i);
    const status = i % 3 === 0 ? 'Leave' : (i % 2 === 0 ? 'Absent' : 'Present');
    let checkInTime = null, checkOutTime = null;
    if (status === 'Present') {
      checkInTime = new Date(date.setHours(9, 0, 0, 0));
      checkOutTime = new Date(date.setHours(17, 0, 0, 0));
    }
    records.push({
      employee: employee._id,
      date: new Date(date),
      status,
      checkInTime,
      checkOutTime,
    });
  }
  await Attendance.insertMany(records);
  console.log('Inserted test attendance records for employee:', employee._id);
  await mongoose.disconnect();
}

// Replace with a real userId from your users collection
const testUserId = '685a8921be22e980a5ba2707';
insertTestAttendance(testUserId); 