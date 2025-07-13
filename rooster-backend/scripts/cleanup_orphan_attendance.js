// cleanup_orphan_attendance.js
// Find and optionally delete attendance records with missing/invalid user references.

const mongoose = require('mongoose');
const readline = require('readline');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  // Find all attendance records
  const allAttendance = await Attendance.find({});
  const orphanRecords = [];

  for (const att of allAttendance) {
    if (!att.user) {
      orphanRecords.push(att);
      continue;
    }
    // If att.user is an ObjectId, check if the user exists
    const userId = att.user._id || att.user; // handle populated or unpopulated
    const user = await User.findById(userId);
    if (!user) {
      orphanRecords.push(att);
    }
  }

  if (orphanRecords.length === 0) {
    console.log('No orphan attendance records found.');
    process.exit(0);
  }

  console.log(`Found ${orphanRecords.length} orphan attendance records:`);
  orphanRecords.forEach((att, i) => {
    console.log(`${i + 1}. ID: ${att._id}, Date: ${att.date}, User: ${att.user}`);
  });

  // Prompt for deletion
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.question('Do you want to delete these records? (y/N): ', async (answer) => {
    if (answer.trim().toLowerCase() === 'y') {
      const ids = orphanRecords.map(att => att._id);
      await Attendance.deleteMany({ _id: { $in: ids } });
      console.log('Deleted all orphan attendance records.');
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