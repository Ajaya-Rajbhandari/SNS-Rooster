// delete_attendance_with_deleted_users.js
// Find and delete attendance records where the user reference points to a deleted user.

const mongoose = require('mongoose');
const readline = require('readline');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  // Find all attendance records with a user reference
  const allAttendance = await Attendance.find({ user: { $ne: null } });
  const badRecords = [];

  for (const att of allAttendance) {
    const user = await User.findById(att.user);
    if (!user) {
      badRecords.push(att);
    }
  }

  if (badRecords.length === 0) {
    console.log('No attendance records referencing deleted users found.');
    process.exit(0);
  }

  console.log(`Found ${badRecords.length} attendance records referencing deleted users:`);
  badRecords.forEach((att, i) => {
    console.log(`${i + 1}. ID: ${att._id}, Date: ${att.date}, User: ${att.user}`);
  });

  // Prompt for deletion
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.question('Do you want to delete these records? (y/N): ', async (answer) => {
    if (answer.trim().toLowerCase() === 'y') {
      const ids = badRecords.map(att => att._id);
      await Attendance.deleteMany({ _id: { $in: ids } });
      console.log('Deleted all attendance records referencing deleted users.');
    } else {
      console.log('No records deleted.');
    }
    rl.close();
    mongoose.disconnect();
  });
}

main().catch(err => {
  console.error('Error:', err);
  mongoose.disconnect();
}); 