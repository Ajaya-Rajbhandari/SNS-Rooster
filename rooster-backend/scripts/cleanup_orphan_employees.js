// cleanup_orphan_employees.js
// Deletes Employee records whose userId does not exist in the User collection.

const mongoose = require('mongoose');
const Employee = require('../models/Employee');
const User = require('../models/User');
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function main() {
  await mongoose.connect(MONGODB_URI);
  console.log('Connected to MongoDB');

  const allEmployees = await Employee.find({});
  const orphanEmployees = [];

  for (const emp of allEmployees) {
    const user = await User.findById(emp.userId);
    if (!user) {
      orphanEmployees.push(emp);
    }
  }

  if (orphanEmployees.length === 0) {
    console.log('No orphan Employee records found.');
    process.exit(0);
  }

  console.log(`Found ${orphanEmployees.length} orphan Employee records:`);
  orphanEmployees.forEach((emp, i) => {
    console.log(`${i + 1}. ID: ${emp._id}, Name: ${emp.firstName} ${emp.lastName}, userId: ${emp.userId}`);
  });

  // Prompt for deletion
  const readline = require('readline');
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.question('Do you want to delete these Employee records? (y/N): ', async (answer) => {
    if (answer.trim().toLowerCase() === 'y') {
      const ids = orphanEmployees.map(emp => emp._id);
      await Employee.deleteMany({ _id: { $in: ids } });
      console.log('Deleted all orphan Employee records.');
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