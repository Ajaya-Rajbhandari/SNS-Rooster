const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Event = require('../models/Event');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
require('dotenv').config();

async function auditDataIsolation() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const citExpressCompany = await require('../models/Company').findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    });

    if (!citExpressCompany) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found Cit Express company:', {
      id: citExpressCompany._id,
      name: citExpressCompany.name,
      domain: citExpressCompany.domain
    });

    // Check notifications
    console.log('\n🔔 Checking notifications...');
    const allNotifications = await Notification.find({});
    const notificationsWithoutCompany = await Notification.find({ companyId: { $exists: false } });
    const citExpressNotifications = await Notification.find({ companyId: citExpressCompany._id });
    
    console.log(`- Total notifications: ${allNotifications.length}`);
    console.log(`- Notifications without companyId: ${notificationsWithoutCompany.length}`);
    console.log(`- Cit Express notifications: ${citExpressNotifications.length}`);

    if (notificationsWithoutCompany.length > 0) {
      console.log('⚠️  Notifications without companyId (causing data leaks):');
      notificationsWithoutCompany.slice(0, 5).forEach(notification => {
        console.log(`  - ${notification.title} (${notification.message})`);
      });
    }

    // Check events
    console.log('\n📅 Checking events...');
    const allEvents = await Event.find({});
    const eventsWithoutCompany = await Event.find({ companyId: { $exists: false } });
    const citExpressEvents = await Event.find({ companyId: citExpressCompany._id });
    
    console.log(`- Total events: ${allEvents.length}`);
    console.log(`- Events without companyId: ${eventsWithoutCompany.length}`);
    console.log(`- Cit Express events: ${citExpressEvents.length}`);

    if (eventsWithoutCompany.length > 0) {
      console.log('⚠️  Events without companyId (causing data leaks):');
      eventsWithoutCompany.slice(0, 5).forEach(event => {
        console.log(`  - ${event.title} (${event.description})`);
      });
    }

    // Check attendance records
    console.log('\n⏰ Checking attendance records...');
    const allAttendance = await Attendance.find({});
    const attendanceWithoutCompany = await Attendance.find({ companyId: { $exists: false } });
    const citExpressAttendance = await Attendance.find({ companyId: citExpressCompany._id });
    
    console.log(`- Total attendance records: ${allAttendance.length}`);
    console.log(`- Attendance without companyId: ${attendanceWithoutCompany.length}`);
    console.log(`- Cit Express attendance: ${citExpressAttendance.length}`);

    // Check users
    console.log('\n👥 Checking users...');
    const allUsers = await User.find({});
    const usersWithoutCompany = await User.find({ 
      companyId: { $exists: false },
      role: { $ne: 'super_admin' }
    });
    const citExpressUsers = await User.find({ companyId: citExpressCompany._id });
    
    console.log(`- Total users: ${allUsers.length}`);
    console.log(`- Users without companyId: ${usersWithoutCompany.length}`);
    console.log(`- Cit Express users: ${citExpressUsers.length}`);

    // Summary
    console.log('\n📊 DATA ISOLATION AUDIT SUMMARY:');
    console.log('=====================================');
    
    const totalOrphanedRecords = notificationsWithoutCompany.length + 
                                eventsWithoutCompany.length + 
                                attendanceWithoutCompany.length + 
                                usersWithoutCompany.length;
    
    console.log(`Total orphaned records: ${totalOrphanedRecords}`);
    
    if (totalOrphanedRecords > 0) {
      console.log('❌ CRITICAL: Data isolation issues found!');
      console.log('🔧 These records are causing cross-company data leaks.');
    } else {
      console.log('✅ All records have proper company isolation.');
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

auditDataIsolation(); 