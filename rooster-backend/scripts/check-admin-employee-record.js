const mongoose = require('mongoose');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');

async function checkAdminEmployeeRecords() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns_rooster');
    console.log('Connected to database');

    // Find all admin users
    const adminUsers = await User.find({ role: 'admin' });
    console.log(`Found ${adminUsers.length} admin users:`);
    
    for (const admin of adminUsers) {
      console.log(`\nAdmin: ${admin.firstName} ${admin.lastName} (${admin.email})`);
      
      // Check if admin has an Employee record
      const employeeRecord = await Employee.findOne({ userId: admin._id });
      if (employeeRecord) {
        console.log(`  ❌ HAS Employee record: ${employeeRecord.firstName} ${employeeRecord.lastName}`);
        console.log(`     Employee ID: ${employeeRecord._id}`);
        console.log(`     This is why admin gets "Incomplete Profile" notifications!`);
      } else {
        console.log(`  ✅ No Employee record found`);
      }
      
      // Check for "Incomplete Profile" notifications for this admin
      const incompleteProfileNotifs = await Notification.find({
        user: admin._id,
        title: 'Incomplete Profile'
      });
      
      if (incompleteProfileNotifs.length > 0) {
        console.log(`  ⚠️  Found ${incompleteProfileNotifs.length} "Incomplete Profile" notifications for this admin`);
        for (const notif of incompleteProfileNotifs) {
          console.log(`     - ${notif.message} (${notif.createdAt})`);
        }
      } else {
        console.log(`  ✅ No "Incomplete Profile" notifications found`);
      }
    }
    
    // Count total "Incomplete Profile" notifications for admin users
    const adminIncompleteNotifs = await Notification.find({
      user: { $in: adminUsers.map(u => u._id) },
      title: 'Incomplete Profile'
    });
    
    console.log(`\n📊 Summary:`);
    console.log(`Total "Incomplete Profile" notifications for admin users: ${adminIncompleteNotifs.length}`);
    
    if (adminIncompleteNotifs.length > 0) {
      console.log(`\n🧹 Cleaning up "Incomplete Profile" notifications for admin users...`);
      const result = await Notification.deleteMany({
        user: { $in: adminUsers.map(u => u._id) },
        title: 'Incomplete Profile'
      });
      console.log(`Deleted ${result.deletedCount} notifications`);
    }
    
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
    
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
}

checkAdminEmployeeRecords(); 