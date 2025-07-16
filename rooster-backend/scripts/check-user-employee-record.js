#!/usr/bin/env node

/**
 * Script to check if a user has an employee record and create one if missing
 * Usage: node scripts/check-user-employee-record.js <userId>
 */

const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');
const Employee = require('../models/Employee');

async function checkAndCreateEmployeeRecord(userId) {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      console.log(`❌ User with ID ${userId} not found`);
      return;
    }

    console.log(`✅ User found: ${user.firstName} ${user.lastName} (${user.email})`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Department: ${user.department || 'Not set'}`);
    console.log(`   Position: ${user.position || 'Not set'}`);

    // Check if employee record exists
    const employee = await Employee.findOne({ userId });
    if (employee) {
      console.log(`✅ Employee record exists: ${employee.firstName} ${employee.lastName}`);
      console.log(`   Employee ID: ${employee.employeeId}`);
      console.log(`   Department: ${employee.department || 'Not set'}`);
      console.log(`   Position: ${employee.position || 'Not set'}`);
      return;
    }

    console.log(`❌ No employee record found for user ${userId}`);

    // Ask for confirmation to create employee record
    const readline = require('readline');
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question('Do you want to create an employee record for this user? (y/n): ', async (answer) => {
      if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
        try {
          // Generate employee ID
          const employeeCount = await Employee.countDocuments();
          const employeeId = `EMP${String(employeeCount + 1).padStart(5, '0')}`;

          // Create employee record
          const newEmployee = new Employee({
            firstName: user.firstName || user.name?.split(' ')[0] || 'Unknown',
            lastName: user.lastName || user.name?.split(' ').slice(1).join(' ') || 'User',
            email: user.email,
            employeeId: employeeId,
            hireDate: new Date(),
            position: user.position || 'Employee',
            department: user.department || 'General',
            hourlyRate: 0,
            monthlySalary: 0,
            userId: user._id,
            isActive: true,
            employeeType: 'Permanent',
            employeeSubType: 'Full-time'
          });

          await newEmployee.save();
          console.log(`✅ Employee record created successfully!`);
          console.log(`   Employee ID: ${employeeId}`);
          console.log(`   Name: ${newEmployee.firstName} ${newEmployee.lastName}`);
          console.log(`   Department: ${newEmployee.department}`);
          console.log(`   Position: ${newEmployee.position}`);
        } catch (error) {
          console.error(`❌ Error creating employee record: ${error.message}`);
        }
      } else {
        console.log('Employee record creation cancelled.');
      }
      rl.close();
      mongoose.connection.close();
    });

  } catch (error) {
    console.error('Error:', error.message);
    mongoose.connection.close();
  }
}

// Get userId from command line arguments
const userId = process.argv[2];
if (!userId) {
  console.log('Usage: node scripts/check-user-employee-record.js <userId>');
  console.log('Example: node scripts/check-user-employee-record.js 68733bf696ba8bfdf8464137');
  process.exit(1);
}

checkAndCreateEmployeeRecord(userId); 