const mongoose = require('mongoose');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
require('dotenv').config();

async function cleanupOrphanedData() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find attendance records without companyId
    const orphanedAttendance = await Attendance.find({ companyId: { $exists: false } });
    console.log(`\n📊 Found ${orphanedAttendance.length} attendance records without companyId`);

    if (orphanedAttendance.length > 0) {
      console.log('⚠️  These records are causing data leaks between companies!');
      console.log('🗑️  Deleting orphaned attendance records...');
      
      const deleteResult = await Attendance.deleteMany({ companyId: { $exists: false } });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned attendance records`);
    }

    // Find users without companyId (except super_admin)
    const orphanedUsers = await User.find({ 
      companyId: { $exists: false },
      role: { $ne: 'super_admin' }
    });
    console.log(`\n👥 Found ${orphanedUsers.length} users without companyId (excluding super_admin)`);

    if (orphanedUsers.length > 0) {
      console.log('⚠️  These users are not properly isolated by company!');
      orphanedUsers.forEach(user => {
        console.log(`- ${user.email} (${user.role})`);
      });
      
      console.log('🗑️  Deleting orphaned users...');
      const deleteResult = await User.deleteMany({ 
        companyId: { $exists: false },
        role: { $ne: 'super_admin' }
      });
      console.log(`✅ Deleted ${deleteResult.deletedCount} orphaned users`);
    }

    // Verify cleanup
    const remainingOrphanedAttendance = await Attendance.find({ companyId: { $exists: false } });
    const remainingOrphanedUsers = await User.find({ 
      companyId: { $exists: false },
      role: { $ne: 'super_admin' }
    });

    console.log('\n✅ Cleanup verification:');
    console.log(`- Remaining orphaned attendance records: ${remainingOrphanedAttendance.length}`);
    console.log(`- Remaining orphaned users: ${remainingOrphanedUsers.length}`);

    if (remainingOrphanedAttendance.length === 0 && remainingOrphanedUsers.length === 0) {
      console.log('🎉 All orphaned data has been cleaned up!');
      console.log('🔒 Data isolation is now properly enforced.');
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

cleanupOrphanedData(); 