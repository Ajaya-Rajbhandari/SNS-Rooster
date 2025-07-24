const mongoose = require('mongoose');
require('dotenv').config();

async function assignLocationToEmployee() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const employeesCollection = db.collection('employees');
    const locationsCollection = db.collection('locations');

    // Get the employee and location IDs
    const employeeId = '687df991cc09e7230a7d98ce';
    const locationId = '687df027d6d8fdc4f2ac80a1';
    
    console.log(`\nAssigning location ${locationId} to employee ${employeeId}...`);
    
    // First, let's fix the location coordinates
    const location = await locationsCollection.findOne({ _id: new mongoose.Types.ObjectId(locationId) });
    if (location) {
      console.log(`\nCurrent location data:`);
      console.log(`   Name: ${location.name}`);
      console.log(`   Address: ${JSON.stringify(location.address)}`);
      console.log(`   Coordinates: ${JSON.stringify(location.coordinates)}`);
      
      // Update location with proper coordinates (example coordinates for Baneshwor, Kathmandu)
      const updatedLocation = await locationsCollection.updateOne(
        { _id: new mongoose.Types.ObjectId(locationId) },
        {
          $set: {
            coordinates: {
              lat: 27.7172,
              lng: 85.3240
            },
            settings: {
              geofenceRadius: 100 // 100 meters radius
            }
          }
        }
      );
      
      console.log(`\n✅ Updated location coordinates and geofence radius`);
    }
    
    // Now assign the location to the employee
    const updatedEmployee = await employeesCollection.updateOne(
      { _id: new mongoose.Types.ObjectId(employeeId) },
      {
        $set: {
          locationId: new mongoose.Types.ObjectId(locationId)
        }
      }
    );
    
    console.log(`\n✅ Assigned location to employee`);
    
    // Verify the changes
    const updatedLocationData = await locationsCollection.findOne({ _id: new mongoose.Types.ObjectId(locationId) });
    const updatedEmployeeData = await employeesCollection.findOne({ _id: new mongoose.Types.ObjectId(employeeId) });
    
    console.log(`\n📍 Updated Location Details:`);
    console.log(`   Name: ${updatedLocationData.name}`);
    console.log(`   Coordinates: Lat: ${updatedLocationData.coordinates.lat}, Lng: ${updatedLocationData.coordinates.lng}`);
    console.log(`   Geofence Radius: ${updatedLocationData.settings.geofenceRadius} meters`);
    
    console.log(`\n👤 Updated Employee Details:`);
    console.log(`   Name: ${updatedEmployeeData.firstName} ${updatedEmployeeData.lastName}`);
    console.log(`   Email: ${updatedEmployeeData.email}`);
    console.log(`   Location ID: ${updatedEmployeeData.locationId}`);
    
    // Calculate test coordinates
    const radiusInDegrees = updatedLocationData.settings.geofenceRadius / 111000; // Rough conversion
    const insideLat = updatedLocationData.coordinates.lat + (radiusInDegrees * 0.5);
    const insideLng = updatedLocationData.coordinates.lng + (radiusInDegrees * 0.5);
    const outsideLat = updatedLocationData.coordinates.lat + (radiusInDegrees * 1.5);
    const outsideLng = updatedLocationData.coordinates.lng + (radiusInDegrees * 1.5);
    
    console.log(`\n🧪 Test Coordinates for Attendance:`);
    console.log(`   Location Center: Lat: ${updatedLocationData.coordinates.lat}, Lng: ${updatedLocationData.coordinates.lng}`);
    console.log(`   Inside Geofence: Lat: ${insideLat}, Lng: ${insideLng}`);
    console.log(`   Outside Geofence: Lat: ${outsideLat}, Lng: ${outsideLng}`);
    
    console.log(`\n✅ Location assignment completed!`);
    console.log(`   Employee can now test attendance within the 100-meter radius`);

  } catch (error) {
    console.error('Error assigning location to employee:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

assignLocationToEmployee(); 