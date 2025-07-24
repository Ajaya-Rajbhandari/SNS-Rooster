const mongoose = require('mongoose');

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');
    console.log('MongoDB connected for index cleanup');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

const cleanupAttendanceIndexes = async () => {
  try {
    const db = mongoose.connection.db;
    const attendanceCollection = db.collection('attendances');

    console.log('Starting attendance index cleanup...');

    // Get current indexes
    const indexes = await attendanceCollection.indexes();
    console.log('Current attendance indexes:');
    indexes.forEach(idx => console.log(`- ${idx.name}: ${JSON.stringify(idx.key)}`));

    // Drop old single-field unique indexes that conflict with compound indexes
    const indexesToDrop = [
      'employeeId_1',
      'date_1',
      'employeeId_1_date_1',
      'user_1',
      'user_1_date_1',
      'date_1', // ensure date_1 is dropped
    ];

    for (const indexName of indexesToDrop) {
      try {
        await attendanceCollection.dropIndex(indexName);
        console.log(`✅ Dropped index: ${indexName}`);
      } catch (error) {
        if (error.code === 27) { // Index not found
          console.log(`ℹ️ Index ${indexName} not found, skipping...`);
        } else {
          console.warn(`⚠️ Could not drop index ${indexName}:`, error.message);
        }
      }
    }

    // Verify remaining indexes
    const remainingIndexes = await attendanceCollection.indexes();
    console.log('Remaining attendance indexes:');
    remainingIndexes.forEach(idx => console.log(`- ${idx.name}: ${JSON.stringify(idx.key)}`));

    // Ensure compound indexes exist
    const Attendance = require('../models/Attendance');
    await Attendance.syncIndexes();
    console.log('✅ Attendance indexes synchronized');

    console.log('🎉 Attendance index cleanup completed successfully!');
  } catch (error) {
    console.error('❌ Error during attendance index cleanup:', error);
  } finally {
    await mongoose.disconnect();
    console.log('MongoDB disconnected');
  }
};

// Run cleanup
if (require.main === module) {
  connectDB().then(cleanupAttendanceIndexes);
}

module.exports = { cleanupAttendanceIndexes }; 