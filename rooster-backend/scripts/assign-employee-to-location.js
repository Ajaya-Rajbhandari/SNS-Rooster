const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Employee = require('../models/Employee');
const Location = require('../models/Location');

async function assignEmployeeToLocation() {
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
    console.log(`Current location ID: ${employee.locationId || 'None'}`);

    // Find the newly created location (with coordinates 27.700207, 85.335659)
    const newLocation = await Location.findOne({
      'coordinates.latitude': 27.700207,
      'coordinates.longitude': 85.335659
    });
    
    if (!newLocation) {
      console.log('Location with coordinates (27.700207, 85.335659) not found');
      console.log('Available locations:');
      const allLocations = await Location.find({});
      allLocations.forEach(loc => {
        console.log(`- ${loc.name}: ${loc.coordinates?.latitude}, ${loc.coordinates?.longitude}`);
      });
      return;
    }
    
    console.log(`Found location: ${newLocation.name} (ID: ${newLocation._id})`);
    console.log(`Coordinates: ${newLocation.coordinates?.latitude}, ${newLocation.coordinates?.longitude}`);

    // Update employee to assign to the new location
    const updatedEmployee = await Employee.findByIdAndUpdate(
      employee._id,
      { locationId: newLocation._id },
      { new: true }
    );

    console.log(`✅ Employee assigned to location: ${newLocation.name}`);
    console.log(`New location ID: ${updatedEmployee.locationId}`);

  } catch (error) {
    console.error('Error assigning employee to location:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
assignEmployeeToLocation(); 