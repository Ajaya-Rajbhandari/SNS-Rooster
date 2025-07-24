const mongoose = require('mongoose');
require('dotenv').config();

async function checkAllEmployees() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const employeesCollection = db.collection('employees');
    const usersCollection = db.collection('users');
    const locationsCollection = db.collection('locations');

    // Find all employees
    const allEmployees = await employeesCollection.find({}).toArray();
    
    console.log(`\nFound ${allEmployees.length} employees total:`);
    allEmployees.forEach(employee => {
      console.log(`- Employee ID: ${employee._id}`);
      console.log(`  Name: ${employee.firstName} ${employee.lastName}`);
      console.log(`  Email: ${employee.email}`);
      console.log(`  Company ID: ${employee.companyId}`);
      console.log(`  Location ID: ${employee.locationId || 'No location assigned'}`);
      console.log('  ---');
    });

    // Find all users with email icerushhh@gmail.com
    const usersWithEmail = await usersCollection.find({ email: 'icerushhh@gmail.com' }).toArray();
    
    console.log(`\nUsers with email icerushhh@gmail.com:`);
    usersWithEmail.forEach(user => {
      console.log(`- User ID: ${user._id}`);
      console.log(`  Name: ${user.firstName} ${user.lastName}`);
      console.log(`  Role: ${user.role}`);
      console.log(`  Company ID: ${user.companyId}`);
      console.log(`  Active: ${user.isActive}`);
      console.log('  ---');
    });

    // Find all locations
    const allLocations = await locationsCollection.find({}).toArray();
    
    console.log(`\nFound ${allLocations.length} locations total:`);
    allLocations.forEach(location => {
      console.log(`- Location ID: ${location._id}`);
      console.log(`  Name: ${location.name}`);
      console.log(`  Company ID: ${location.companyId}`);
      console.log(`  Address: ${location.address}`);
      console.log(`  Coordinates: ${location.coordinates ? `Lat: ${location.coordinates.lat}, Lng: ${location.coordinates.lng}` : 'No coordinates'}`);
      console.log('  ---');
    });

    // Check if there's an employee for the user with email icerushhh@gmail.com
    const userWithEmail = usersWithEmail.find(u => u.role === 'employee');
    if (userWithEmail) {
      const employeeForUser = allEmployees.find(e => e.userId?.toString() === userWithEmail._id.toString());
      if (employeeForUser) {
        console.log(`\n✅ Found employee record for user ${userWithEmail.email}:`);
        console.log(`   Employee ID: ${employeeForUser._id}`);
        console.log(`   Company ID: ${employeeForUser.companyId}`);
        console.log(`   Location ID: ${employeeForUser.locationId || 'No location assigned'}`);
        
        if (employeeForUser.locationId) {
          const assignedLocation = allLocations.find(l => l._id.toString() === employeeForUser.locationId.toString());
          if (assignedLocation) {
            console.log(`\n📍 Assigned Location Details:`);
            console.log(`   Name: ${assignedLocation.name}`);
            console.log(`   Address: ${assignedLocation.address}`);
            console.log(`   Coordinates: Lat: ${assignedLocation.coordinates?.lat}, Lng: ${assignedLocation.coordinates?.lng}`);
            console.log(`   Geofence Radius: ${assignedLocation.settings?.geofenceRadius || 'No geofence'} meters`);
          }
        }
      } else {
        console.log(`\n⚠️  No employee record found for user ${userWithEmail.email}`);
      }
    }

  } catch (error) {
    console.error('Error checking all employees:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkAllEmployees(); 