const mongoose = require('mongoose');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');

async function debugAdminUsers() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to database: sns-rooster');

    // Check total users
    const totalUsers = await User.countDocuments();
    console.log(`Total users in database: ${totalUsers}`);

    // Find all admin users
    const adminUsers = await User.find({ role: 'admin' });
    console.log(`\nFound ${adminUsers.length} admin users:`);
    
    if (adminUsers.length === 0) {
      console.log('No admin users found!');
    } else {
      for (const admin of adminUsers) {
        console.log(`\nAdmin: ${admin.firstName} ${admin.lastName} (${admin.email})`);
        console.log(`  User ID: ${admin._id}`);
        console.log(`  Role: ${admin.role}`);
        
        // Check if admin has an Employee record
        const employeeRecord = await Employee.findOne({ userId: admin._id });
        if (employeeRecord) {
          console.log(`  ❌ HAS Employee record: ${employeeRecord.firstName} ${employeeRecord.lastName}`);
          console.log(`     Employee ID: ${employeeRecord._id}`);
        } else {
          console.log(`  ✅ No Employee record found`);
        }
        
        // Check for any notifications for this admin
        const allNotifs = await Notification.find({ user: admin._id });
        console.log(`  Total notifications for this admin: ${allNotifs.length}`);
        
        if (allNotifs.length > 0) {
          console.log(`  Notifications:`);
          for (const notif of allNotifs) {
            console.log(`    - ${notif.title}: ${notif.message} (${notif.createdAt})`);
          }
        }
      }
    }
    
    // Check for any "Incomplete Profile" notifications for any user
    const incompleteNotifs = await Notification.find({ title: 'Incomplete Profile' });
    console.log(`\n📊 Total "Incomplete Profile" notifications: ${incompleteNotifs.length}`);
    
    if (incompleteNotifs.length > 0) {
      console.log(`Details:`);
      for (const notif of incompleteNotifs) {
        const user = await User.findById(notif.user);
        const userInfo = user ? `${user.firstName} ${user.lastName} (${user.role})` : 'Unknown user';
        console.log(`  - ${userInfo}: ${notif.message} (${notif.createdAt})`);
      }
    }
    
    // Check for admin role notifications
    const adminRoleNotifs = await Notification.find({ role: 'admin' });
    console.log(`\n📊 Total notifications with role='admin': ${adminRoleNotifs.length}`);
    
    if (adminRoleNotifs.length > 0) {
      console.log(`Admin role notifications:`);
      for (const notif of adminRoleNotifs) {
        console.log(`  - ${notif.title}: ${notif.message} (${notif.createdAt})`);
      }
    }
    
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
    
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
}

debugAdminUsers(); 