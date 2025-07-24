const mongoose = require('mongoose');
require('dotenv').config();

async function checkEmployeeLocation() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const employeesCollection = db.collection('employees');
    const locationsCollection = db.collection('locations');

    // Get the current company ID
    const currentCompanyId = '687c6cf9fce054783b9af432';
    
    console.log(`\nChecking employees and locations in company: ${currentCompanyId}`);
    
    // Find all employees in the current company
    const companyEmployees = await employeesCollection.find({ companyId: currentCompanyId }).toArray();
    
    console.log(`\nFound ${companyEmployees.length} employees in current company:`);
    companyEmployees.forEach(employee => {
      console.log(`- Employee ID: ${employee._id}`);
      console.log(`  Name: ${employee.firstName} ${employee.lastName}`);
      console.log(`  Email: ${employee.email}`);
      console.log(`  Position: ${employee.position}`);
      console.log(`  Department: ${employee.department}`);
      console.log(`  Location ID: ${employee.locationId || 'No location assigned'}`);
      console.log('  ---');
    });

    // Find all locations in the current company
    const companyLocations = await locationsCollection.find({ companyId: currentCompanyId }).toArray();
    
    console.log(`\nFound ${companyLocations.length} locations in current company:`);
    companyLocations.forEach(location => {
      console.log(`- Location ID: ${location._id}`);
      console.log(`  Name: ${location.name}`);
      console.log(`  Address: ${location.address}`);
      console.log(`  Coordinates: ${location.coordinates ? `Lat: ${location.coordinates.lat}, Lng: ${location.coordinates.lng}` : 'No coordinates'}`);
      console.log(`  Geofence Radius: ${location.settings?.geofenceRadius || 'No geofence set'} meters`);
      console.log('  ---');
    });

    // Check specific employee location
    const specificEmployee = companyEmployees.find(e => e.email === 'icerushhh@gmail.com');
    if (specificEmployee && specificEmployee.locationId) {
      const assignedLocation = companyLocations.find(l => l._id.toString() === specificEmployee.locationId.toString());
      if (assignedLocation) {
        console.log(`\n✅ Employee ${specificEmployee.firstName} ${specificEmployee.lastName} is assigned to:`);
        console.log(`   Location: ${assignedLocation.name}`);
        console.log(`   Address: ${assignedLocation.address}`);
        console.log(`   Coordinates: Lat: ${assignedLocation.coordinates?.lat}, Lng: ${assignedLocation.coordinates?.lng}`);
        console.log(`   Geofence Radius: ${assignedLocation.settings?.geofenceRadius || 'No geofence'} meters`);
        
        // Calculate test coordinates (slightly outside the geofence)
        if (assignedLocation.coordinates && assignedLocation.settings?.geofenceRadius) {
          const radiusInDegrees = assignedLocation.settings.geofenceRadius / 111000; // Rough conversion
          const outsideLat = assignedLocation.coordinates.lat + (radiusInDegrees * 1.5);
          const outsideLng = assignedLocation.coordinates.lng + (radiusInDegrees * 1.5);
          
          console.log(`\n📍 Test Coordinates:`);
          console.log(`   Inside geofence: Lat: ${assignedLocation.coordinates.lat}, Lng: ${assignedLocation.coordinates.lng}`);
          console.log(`   Outside geofence: Lat: ${outsideLat}, Lng: ${outsideLng}`);
        }
      } else {
        console.log(`\n⚠️  Employee has location ID ${specificEmployee.locationId} but location not found`);
      }
    } else {
      console.log(`\n⚠️  Employee ${specificEmployee?.firstName || 'Unknown'} has no location assigned`);
    }

  } catch (error) {
    console.error('Error checking employee location:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkEmployeeLocation(); 