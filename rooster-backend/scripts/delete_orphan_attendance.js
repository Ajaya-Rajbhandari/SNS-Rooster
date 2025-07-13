// delete_orphan_attendance.js
// Deletes attendance records where user is null or the referenced user does not exist.

const mongoose = require('mongoose');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  // Find attendance records with user=null or user not found
  const allAttendance = await Attendance.find({});
  let orphanIds = [];
  for (const att of allAttendance) {
    if (!att.user) {
      orphanIds.push(att._id);
      continue;
    }
    const user = await User.findById(att.user);
    if (!user) {
      orphanIds.push(att._id);
    }
  }
  if (orphanIds.length === 0) {
    console.log('No orphan attendance records found.');
  } else {
    await Attendance.deleteMany({ _id: { $in: orphanIds } });
    console.log(`Deleted ${orphanIds.length} orphan attendance records.`);
  }
  await mongoose.disconnect();
}
main(); 