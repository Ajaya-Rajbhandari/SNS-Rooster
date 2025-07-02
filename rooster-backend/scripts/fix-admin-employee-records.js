const mongoose = require('mongoose');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');

async function fixAdminEmployeeRecords() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to database: sns-rooster');

    // Find all admin users
    const adminUsers = await User.find({ role: 'admin' });
    console.log(`Found ${adminUsers.length} admin users`);
    
    for (const admin of adminUsers) {
      console.log(`\nProcessing admin: ${admin.firstName} ${admin.lastName} (${admin.email})`);
      
      // Check if admin has an Employee record
      const employeeRecord = await Employee.findOne({ userId: admin._id });
      if (employeeRecord) {
        console.log(`  ❌ Found Employee record: ${employeeRecord.firstName} ${employeeRecord.lastName}`);
        console.log(`     Employee ID: ${employeeRecord._id}`);
        
        // Delete the Employee record
        await Employee.findByIdAndDelete(employeeRecord._id);
        console.log(`  ✅ Deleted Employee record`);
        
        // Clean up any "Incomplete Profile" notifications for this admin
        const incompleteNotifs = await Notification.find({
          user: admin._id,
          title: 'Incomplete Profile'
        });
        
        if (incompleteNotifs.length > 0) {
          console.log(`  🧹 Found ${incompleteNotifs.length} "Incomplete Profile" notifications for this admin`);
          await Notification.deleteMany({
            user: admin._id,
            title: 'Incomplete Profile'
          });
          console.log(`  ✅ Deleted ${incompleteNotifs.length} notifications`);
        }
        
        // Clean up any "Incomplete Employee Profile" notifications for admins about this user
        const fullName = `${admin.firstName} ${admin.lastName}`.trim();
        const adminNotifs = await Notification.find({
          role: 'admin',
          title: 'Incomplete Employee Profile',
          message: { $regex: new RegExp(`^${fullName} has not completed their profile\.?$`, 'i') }
        });
        
        if (adminNotifs.length > 0) {
          console.log(`  🧹 Found ${adminNotifs.length} admin notifications about this user's incomplete profile`);
          await Notification.deleteMany({
            role: 'admin',
            title: 'Incomplete Employee Profile',
            message: { $regex: new RegExp(`^${fullName} has not completed their profile\.?$`, 'i') }
          });
          console.log(`  ✅ Deleted ${adminNotifs.length} admin notifications`);
        }
        
      } else {
        console.log(`  ✅ No Employee record found (this is correct)`);
      }
    }
    
    // Final verification
    console.log(`\n📊 Final verification:`);
    const remainingAdminEmployees = await Employee.find({
      userId: { $in: adminUsers.map(u => u._id) }
    });
    console.log(`Admin users with Employee records: ${remainingAdminEmployees.length}`);
    
    const remainingIncompleteNotifs = await Notification.find({
      user: { $in: adminUsers.map(u => u._id) },
      title: 'Incomplete Profile'
    });
    console.log(`"Incomplete Profile" notifications for admin users: ${remainingIncompleteNotifs.length}`);
    
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
    console.log('\n✅ Fix completed! Admin users should no longer receive "Incomplete Profile" notifications.');
    
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
}

fixAdminEmployeeRecords(); 