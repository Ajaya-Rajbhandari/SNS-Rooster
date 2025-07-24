const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Location = require('../models/Location');
const Employee = require('../models/Employee');

async function checkAllLocations() {
  try {
    // Connect to database
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('\n=== All Locations in Database ===');
    const allLocations = await Location.find({});
    
    if (allLocations.length === 0) {
      console.log('No locations found in database');
      return;
    }

    allLocations.forEach((location, index) => {
      console.log(`\n${index + 1}. ${location.name}`);
      console.log(`   ID: ${location._id}`);
      console.log(`   Coordinates: ${location.coordinates?.latitude}, ${location.coordinates?.longitude}`);
      console.log(`   Status: ${location.status}`);
      console.log(`   Created: ${location.createdAt}`);
      console.log(`   Updated: ${location.updatedAt}`);
    });

    console.log('\n=== Employee Assignments ===');
    const allEmployees = await Employee.find({});
    
    allEmployees.forEach(employee => {
      console.log(`\n${employee.firstName} ${employee.lastName}`);
      console.log(`   User ID: ${employee.userId}`);
      console.log(`   Location ID: ${employee.locationId || 'None'}`);
      
      if (employee.locationId) {
        const assignedLocation = allLocations.find(loc => loc._id.toString() === employee.locationId.toString());
        if (assignedLocation) {
          console.log(`   Assigned to: ${assignedLocation.name}`);
        } else {
          console.log(`   Assigned to: Unknown location (ID: ${employee.locationId})`);
        }
      }
    });

  } catch (error) {
    console.error('Error checking locations:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
checkAllLocations(); 