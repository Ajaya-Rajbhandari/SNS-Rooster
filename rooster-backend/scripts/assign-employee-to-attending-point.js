const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Employee = require('../models/Employee');
const Location = require('../models/Location');

async function assignEmployeeToAttendingPoint() {
  try {
    // Connect to database
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the employee (Ice Rush)
    const employee = await Employee.findOne({ 
      firstName: 'Ice', 
      lastName: 'Rush' 
    });
    
    if (!employee) {
      console.log('Employee "Ice Rush" not found');
      return;
    }
    
    console.log(`Found employee: ${employee.firstName} ${employee.lastName} (ID: ${employee._id})`);

    // Find the "Attending Point" location
    const attendingPoint = await Location.findOne({ name: 'Attending Point' });
    
    if (!attendingPoint) {
      console.log('"Attending Point" location not found');
      return;
    }
    
    console.log(`Found location: ${attendingPoint.name} (ID: ${attendingPoint._id})`);
    console.log(`Coordinates: ${attendingPoint.coordinates?.latitude}, ${attendingPoint.coordinates?.longitude}`);

    // Update employee to assign to the Attending Point location
    const updatedEmployee = await Employee.findByIdAndUpdate(
      employee._id,
      { locationId: attendingPoint._id },
      { new: true }
    );

    console.log(`✅ Employee assigned to location: ${attendingPoint.name}`);
    console.log(`New location ID: ${updatedEmployee.locationId}`);

  } catch (error) {
    console.error('Error assigning employee to location:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
assignEmployeeToAttendingPoint(); 