// Try loading .env from both possible locations
const dotenvResult1 = require('dotenv').config({ path: '../.env' });
console.log('Attempt 1 (../.env):', process.env.MONGODB_URI);
if (!process.env.MONGODB_URI) {
  const dotenvResult2 = require('dotenv').config({ path: './.env' });
  console.log('Attempt 2 (./.env):', process.env.MONGODB_URI);
}
const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Employee = require('../models/Employee');
const User = require('../models/User');

async function testPayrollNotification() {
  try {
    // Use the same connection string as your backend
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find an employee to test with
    let employee = await Employee.findOne();
    let userId = null;

    if (!employee) {
      console.log('No employees found in database, checking for users...');
      const user = await User.findOne({ role: 'employee' });
      if (user) {
        console.log('Found user:', user.email);
        userId = user._id;
      } else {
        console.log('No users found either');
        return;
      }
    } else {
      console.log('Testing with employee:', employee.firstName, employee.lastName);
      console.log('Employee userId:', employee.userId);
      userId = employee.userId;
    }

    if (!userId) {
      console.log('No userId available for testing');
      return;
    }

    // Test creating a payroll notification
    const notification = new Notification({
      user: userId,
      title: 'Payroll Processed',
      message: 'Your payroll for January 2024 has been processed.',
      type: 'payroll',
      link: '/payroll',
      isRead: false,
    });

    await notification.save();
    console.log('✅ Payroll notification created successfully:', notification._id);

    // Test creating other notification types
    const leaveNotification = new Notification({
      user: userId,
      title: 'Leave Request Approved',
      message: 'Your leave request has been approved.',
      type: 'leave',
      link: '/leave_request',
      isRead: false,
    });

    await leaveNotification.save();
    console.log('✅ Leave notification created successfully:', leaveNotification._id);

    const timesheetNotification = new Notification({
      user: userId,
      title: 'Timesheet Submitted',
      message: 'Your timesheet has been submitted successfully.',
      type: 'timesheet',
      link: '/timesheet',
      isRead: false,
    });

    await timesheetNotification.save();
    console.log('✅ Timesheet notification created successfully:', timesheetNotification._id);

    // Test admin notification
    const adminNotification = new Notification({
      role: 'admin',
      title: 'Test Admin Notification',
      message: 'This is a test admin notification.',
      type: 'action',
      link: '/admin/dashboard',
      isRead: false,
    });

    await adminNotification.save();
    console.log('✅ Admin notification created successfully:', adminNotification._id);

    console.log('✅ All notification types tested successfully!');

    // List all notifications for this user
    const userNotifications = await Notification.find({ user: userId });
    console.log(`\n📋 Found ${userNotifications.length} notifications for user:`);
    userNotifications.forEach(n => {
      console.log(`  - ${n.title}: ${n.message} (${n.type})`);
    });

    // List all admin notifications
    const adminNotifications = await Notification.find({ role: 'admin' });
    console.log(`\n📋 Found ${adminNotifications.length} admin notifications:`);
    adminNotifications.forEach(n => {
      console.log(`  - ${n.title}: ${n.message} (${n.type})`);
    });

  } catch (error) {
    console.error('❌ Error testing notifications:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

testPayrollNotification(); 