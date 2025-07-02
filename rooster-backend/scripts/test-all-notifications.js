const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Leave = require('../models/Leave');
const Payroll = require('../models/Payroll');

async function testAllNotifications() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('✅ Connected to database: sns-rooster');

    // Get test users
    const adminUser = await User.findOne({ role: 'admin' });
    const employeeUser = await User.findOne({ role: 'employee' });
    
    if (!adminUser) {
      console.log('❌ No admin user found. Please create an admin user first.');
      return;
    }
    
    if (!employeeUser) {
      console.log('❌ No employee user found. Please create an employee user first.');
      return;
    }

    const employee = await Employee.findOne({ userId: employeeUser._id });
    if (!employee) {
      console.log('❌ No employee record found for employee user.');
      return;
    }

    console.log(`\n🧪 Testing notifications with:`);
    console.log(`   Admin: ${adminUser.firstName} ${adminUser.lastName} (${adminUser.email})`);
    console.log(`   Employee: ${employeeUser.firstName} ${employeeUser.lastName} (${employeeUser.email})`);

    // Clear existing test notifications
    console.log('\n🧹 Clearing existing test notifications...');
    await Notification.deleteMany({
      title: { $regex: /^\[TEST\]/ }
    });
    console.log('✅ Cleared existing test notifications');

    // Test 1: System/Manual Notifications
    console.log('\n📋 Test 1: System/Manual Notifications');
    await testSystemNotifications(adminUser, employeeUser);

    // Test 2: Leave Notifications
    console.log('\n📋 Test 2: Leave Notifications');
    await testLeaveNotifications(adminUser, employeeUser, employee);

    // Test 3: Payroll Notifications
    console.log('\n📋 Test 3: Payroll Notifications');
    await testPayrollNotifications(adminUser, employeeUser, employee);

    // Test 4: Profile Notifications
    console.log('\n📋 Test 4: Profile Notifications');
    await testProfileNotifications(adminUser, employeeUser, employee);

    // Test 5: Notification Management
    console.log('\n📋 Test 5: Notification Management');
    await testNotificationManagement(adminUser, employeeUser);

    // Final Summary
    console.log('\n📊 Final Summary');
    await showNotificationSummary();

    console.log('\n✅ All notification tests completed!');
    
  } catch (error) {
    console.error('❌ Error during testing:', error);
  } finally {
    mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

async function testSystemNotifications(adminUser, employeeUser) {
  try {
    // Test 1.1: Admin notification
    const adminNotif = new Notification({
      role: 'admin',
      title: '[TEST] System Maintenance',
      message: 'Scheduled maintenance will occur tonight at 2 AM.',
      type: 'info',
      link: '/admin/settings',
      isRead: false,
    });
    await adminNotif.save();
    console.log('  ✅ Created admin system notification');

    // Test 1.2: Employee notification
    const empNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Welcome Message',
      message: 'Welcome to the SNS Rooster system!',
      type: 'info',
      link: '/dashboard',
      isRead: false,
    });
    await empNotif.save();
    console.log('  ✅ Created employee system notification');

    // Test 1.3: Broadcast notification
    const broadcastNotif = new Notification({
      role: 'all',
      title: '[TEST] Company Announcement',
      message: 'Company meeting scheduled for Friday at 3 PM.',
      type: 'system',
      link: '/announcements',
      isRead: false,
    });
    await broadcastNotif.save();
    console.log('  ✅ Created broadcast notification');

  } catch (error) {
    console.error('  ❌ Error in system notifications test:', error);
  }
}

async function testLeaveNotifications(adminUser, employeeUser, employee) {
  try {
    // Test 2.1: Create a test leave request
    const testLeave = new Leave({
      employee: employee._id,
      leaveType: 'Annual',
      startDate: new Date('2024-02-01'),
      endDate: new Date('2024-02-03'),
      reason: 'Test leave request for notification testing',
      status: 'Pending'
    });
    await testLeave.save();
    console.log('  ✅ Created test leave request');

    // Test 2.2: Simulate leave application notification (admin notification)
    const leaveAppNotif = new Notification({
      role: 'admin',
      title: '[TEST] New Leave Request Submitted',
      message: `${employee.firstName} ${employee.lastName} has submitted a leave request from ${testLeave.startDate.toDateString()} to ${testLeave.endDate.toDateString()}.`,
      type: 'action',
      link: '/admin/leave_management',
      isRead: false,
    });
    await leaveAppNotif.save();
    console.log('  ✅ Created leave application notification for admin');

    // Test 2.3: Simulate leave approval notification (employee notification)
    const leaveApprovalNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Leave Request Approved',
      message: `Your leave request from ${testLeave.startDate.toDateString()} to ${testLeave.endDate.toDateString()} has been approved.`,
      type: 'info',
      link: '/leave_request',
      isRead: false,
    });
    await leaveApprovalNotif.save();
    console.log('  ✅ Created leave approval notification for employee');

    // Test 2.4: Simulate leave rejection notification (employee notification)
    const leaveRejectionNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Leave Request Rejected',
      message: `Your leave request from ${testLeave.startDate.toDateString()} to ${testLeave.endDate.toDateString()} has been rejected.`,
      type: 'alert',
      link: '/leave_request',
      isRead: false,
    });
    await leaveRejectionNotif.save();
    console.log('  ✅ Created leave rejection notification for employee');

    // Clean up test leave
    await Leave.findByIdAndDelete(testLeave._id);

  } catch (error) {
    console.error('  ❌ Error in leave notifications test:', error);
  }
}

async function testPayrollNotifications(adminUser, employeeUser, employee) {
  try {
    // Test 3.1: Payroll processed notification (employee notification)
    const payrollProcessedNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Payroll Processed',
      message: 'Your payroll for January 2024 has been processed.',
      type: 'payroll',
      link: '/payroll',
      isRead: false,
    });
    await payrollProcessedNotif.save();
    console.log('  ✅ Created payroll processed notification for employee');

    // Test 3.2: Payslip acknowledged notification (admin notification)
    const payslipAckNotif = new Notification({
      role: 'admin',
      title: '[TEST] Payslip Acknowledged',
      message: `${employee.firstName} ${employee.lastName} has acknowledged their payslip for January 2024.`,
      type: 'payroll',
      link: '/admin/payroll_management',
      isRead: false,
    });
    await payslipAckNotif.save();
    console.log('  ✅ Created payslip acknowledged notification for admin');

    // Test 3.3: Payslip needs review notification (admin notification)
    const payslipReviewNotif = new Notification({
      role: 'admin',
      title: '[TEST] Payslip Needs Review',
      message: `${employee.firstName} ${employee.lastName} has requested a review for their payslip for January 2024.`,
      type: 'review',
      link: '/admin/payroll_management',
      isRead: false,
    });
    await payslipReviewNotif.save();
    console.log('  ✅ Created payslip review notification for admin');

    // Test 3.4: Payslip status update notification (employee notification)
    const payslipStatusNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Payslip Status Updated',
      message: 'Your payslip for January 2024 status changed to approved.',
      type: 'payroll',
      link: '/payroll',
      isRead: false,
    });
    await payslipStatusNotif.save();
    console.log('  ✅ Created payslip status notification for employee');

  } catch (error) {
    console.error('  ❌ Error in payroll notifications test:', error);
  }
}

async function testProfileNotifications(adminUser, employeeUser, employee) {
  try {
    // Test 4.1: Incomplete profile notification for employee
    const incompleteProfileNotif = new Notification({
      user: employeeUser._id,
      title: '[TEST] Incomplete Profile',
      message: 'Your profile is incomplete. Please update your information.',
      type: 'alert',
      link: '/profile',
      isRead: false,
    });
    await incompleteProfileNotif.save();
    console.log('  ✅ Created incomplete profile notification for employee');

    // Test 4.2: Incomplete employee profile notification for admin
    const incompleteEmpProfileNotif = new Notification({
      role: 'admin',
      title: '[TEST] Incomplete Employee Profile',
      message: `${employee.firstName} ${employee.lastName} has not completed their profile.`,
      type: 'alert',
      link: '/admin/employee_management',
      isRead: false,
    });
    await incompleteEmpProfileNotif.save();
    console.log('  ✅ Created incomplete employee profile notification for admin');

  } catch (error) {
    console.error('  ❌ Error in profile notifications test:', error);
  }
}

async function testNotificationManagement(adminUser, employeeUser) {
  try {
    // Test 5.1: Mark notification as read
    const testNotif = await Notification.findOne({ title: { $regex: /^\[TEST\]/ } });
    if (testNotif) {
      testNotif.isRead = true;
      await testNotif.save();
      console.log('  ✅ Marked test notification as read');
    }

    // Test 5.2: Count notifications by type
    const notificationCounts = await Notification.aggregate([
      { $match: { title: { $regex: /^\[TEST\]/ } } },
      { $group: { _id: '$type', count: { $sum: 1 } } }
    ]);
    console.log('  📊 Test notification counts by type:');
    notificationCounts.forEach(count => {
      console.log(`     ${count._id}: ${count.count}`);
    });

  } catch (error) {
    console.error('  ❌ Error in notification management test:', error);
  }
}

async function showNotificationSummary() {
  try {
    const totalNotifications = await Notification.countDocuments({ title: { $regex: /^\[TEST\]/ } });
    const unreadNotifications = await Notification.countDocuments({ 
      title: { $regex: /^\[TEST\]/ }, 
      isRead: false 
    });

    console.log(`  📈 Total test notifications created: ${totalNotifications}`);
    console.log(`  📈 Unread test notifications: ${unreadNotifications}`);

    // Show notifications by recipient type
    const adminNotifs = await Notification.countDocuments({ 
      title: { $regex: /^\[TEST\]/ }, 
      role: 'admin' 
    });
    const employeeNotifs = await Notification.countDocuments({ 
      title: { $regex: /^\[TEST\]/ }, 
      user: { $exists: true, $ne: null } 
    });
    const broadcastNotifs = await Notification.countDocuments({ 
      title: { $regex: /^\[TEST\]/ }, 
      role: 'all' 
    });

    console.log(`  📈 Admin notifications: ${adminNotifs}`);
    console.log(`  📈 Employee notifications: ${employeeNotifs}`);
    console.log(`  📈 Broadcast notifications: ${broadcastNotifs}`);

  } catch (error) {
    console.error('  ❌ Error in notification summary:', error);
  }
}

// Run the test
testAllNotifications(); 