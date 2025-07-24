const mongoose = require('mongoose');

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('MongoDB connected for force index cleanup');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

const forceCleanupAttendanceIndexes = async () => {
  try {
    const db = mongoose.connection.db;
    const attendanceCollection = db.collection('attendances');

    console.log('🔧 Force cleaning attendance indexes...');

    // Get all indexes
    const indexes = await attendanceCollection.indexes();
    console.log('Current attendance indexes:');
    indexes.forEach(idx => console.log(`- ${idx.name}: ${JSON.stringify(idx.key)}`));

    // Drop any index that contains 'date' field (except _id)
    for (const index of indexes) {
      if (index.name !== '_id_' && index.key.date) {
        try {
          console.log(`🗑️ Dropping index: ${index.name} (${JSON.stringify(index.key)})`);
          await attendanceCollection.dropIndex(index.name);
          console.log(`✅ Successfully dropped: ${index.name}`);
        } catch (error) {
          console.warn(`⚠️ Could not drop index ${index.name}:`, error.message);
        }
      }
    }

    // Also try dropping by key pattern for any remaining date indexes
    try {
      console.log('🗑️ Attempting to drop any remaining date indexes by key pattern...');
      await attendanceCollection.dropIndex({ date: 1 });
      console.log('✅ Dropped index by key pattern: { date: 1 }');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️ No { date: 1 } index found');
      } else {
        console.warn('⚠️ Could not drop by key pattern:', error.message);
      }
    }

    // Verify remaining indexes
    const remainingIndexes = await attendanceCollection.indexes();
    console.log('\nRemaining attendance indexes:');
    remainingIndexes.forEach(idx => console.log(`- ${idx.name}: ${JSON.stringify(idx.key)}`));

    // Ensure compound indexes exist
    const Attendance = require('../models/Attendance');
    await Attendance.syncIndexes();
    console.log('✅ Attendance indexes synchronized');

    console.log('🎉 Force attendance index cleanup completed!');
  } catch (error) {
    console.error('❌ Error during force attendance index cleanup:', error);
  } finally {
    await mongoose.disconnect();
    console.log('MongoDB disconnected');
  }
};

// Run cleanup
if (require.main === module) {
  connectDB().then(forceCleanupAttendanceIndexes);
}

module.exports = { forceCleanupAttendanceIndexes }; 