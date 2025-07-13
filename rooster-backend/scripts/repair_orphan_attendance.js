// repair_orphan_attendance.js
// Try to repair attendance records with user: null by matching on email (if present), otherwise offer to delete them.

const mongoose = require('mongoose');
const readline = require('readline');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  // Find all attendance records with user: null
  const orphanRecords = await Attendance.find({ user: null });
  if (orphanRecords.length === 0) {
    console.log('No orphan attendance records found.');
    process.exit(0);
  }

  let repaired = 0;
  for (const att of orphanRecords) {
    // Try to match by email if present
    let matchedUser = null;
    if (att.email) {
      matchedUser = await User.findOne({ email: att.email });
    }
    // Optionally, add more matching logic here (e.g., by name, legacy fields)
    if (matchedUser) {
      att.user = matchedUser._id;
      await att.save();
      repaired++;
      console.log(`Repaired attendance ${att._id} with user ${matchedUser.email}`);
    }
  }

  // Find remaining orphans
  const stillOrphan = await Attendance.find({ user: null });
  if (stillOrphan.length === 0) {
    console.log(`All orphan attendance records repaired! (${repaired} fixed)`);
    process.exit(0);
  }

  console.log(`Could not repair ${stillOrphan.length} orphan attendance records:`);
  stillOrphan.forEach((att, i) => {
    console.log(`${i + 1}. ID: ${att._id}, Date: ${att.date}, Email: ${att.email || 'N/A'}`);
  });

  // Prompt for deletion
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.question('Do you want to delete these unrepaired records? (y/N): ', async (answer) => {
    if (answer.trim().toLowerCase() === 'y') {
      const ids = stillOrphan.map(att => att._id);
      await Attendance.deleteMany({ _id: { $in: ids } });
      console.log('Deleted all unrepaired orphan attendance records.');
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