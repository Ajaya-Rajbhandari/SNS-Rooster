const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const Event = require('../models/Event');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
require('dotenv').config();

async function fixDataIsolation() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('🔧 Fixing data isolation issues...');

    // 1. Clean up orphaned notifications
    console.log('\n🗑️  Cleaning up orphaned notifications...');
    const orphanedNotifications = await Notification.find({ companyId: { $exists: false } });
    console.log(`Found ${orphanedNotifications.length} orphaned notifications`);
    
    if (orphanedNotifications.length > 0) {
      const deleteResult = await Notification.deleteMany({ companyId: { $exists: false } });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned notifications`);
    }

    // 2. Clean up orphaned events
    console.log('\n🗑️  Cleaning up orphaned events...');
    const orphanedEvents = await Event.find({ companyId: { $exists: false } });
    console.log(`Found ${orphanedEvents.length} orphaned events`);
    
    if (orphanedEvents.length > 0) {
      const deleteResult = await Event.deleteMany({ companyId: { $exists: false } });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned events`);
    }

    // 3. Clean up orphaned attendance records
    console.log('\n🗑️  Cleaning up orphaned attendance records...');
    const orphanedAttendance = await Attendance.find({ companyId: { $exists: false } });
    console.log(`Found ${orphanedAttendance.length} orphaned attendance records`);
    
    if (orphanedAttendance.length > 0) {
      const deleteResult = await Attendance.deleteMany({ companyId: { $exists: false } });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned attendance records`);
    }

    // 4. Clean up orphaned users (except super_admin)
    console.log('\n🗑️  Cleaning up orphaned users...');
    const orphanedUsers = await User.find({ 
      companyId: { $exists: false },
      role: { $ne: 'super_admin' }
    });
    console.log(`Found ${orphanedUsers.length} orphaned users`);
    
    if (orphanedUsers.length > 0) {
      const deleteResult = await User.deleteMany({ 
        companyId: { $exists: false },
        role: { $ne: 'super_admin' }
      });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned users`);
    }

    // 5. Verify cleanup
    console.log('\n✅ Verification after cleanup:');
    const remainingOrphanedNotifications = await Notification.find({ companyId: { $exists: false } });
    const remainingOrphanedEvents = await Event.find({ companyId: { $exists: false } });
    const remainingOrphanedAttendance = await Attendance.find({ companyId: { $exists: false } });
    const remainingOrphanedUsers = await User.find({ 
      companyId: { $exists: false },
      role: { $ne: 'super_admin' }
    });

    console.log(`- Remaining orphaned notifications: ${remainingOrphanedNotifications.length}`);
    console.log(`- Remaining orphaned events: ${remainingOrphanedEvents.length}`);
    console.log(`- Remaining orphaned attendance: ${remainingOrphanedAttendance.length}`);
    console.log(`- Remaining orphaned users: ${remainingOrphanedUsers.length}`);

    const totalRemaining = remainingOrphanedNotifications.length + 
                          remainingOrphanedEvents.length + 
                          remainingOrphanedAttendance.length + 
                          remainingOrphanedUsers.length;

    if (totalRemaining === 0) {
      console.log('\n🎉 SUCCESS: All orphaned data has been cleaned up!');
      console.log('🔒 Data isolation is now properly enforced across all modules.');
    } else {
      console.log(`\n⚠️  WARNING: ${totalRemaining} orphaned records still remain.`);
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

fixDataIsolation(); 