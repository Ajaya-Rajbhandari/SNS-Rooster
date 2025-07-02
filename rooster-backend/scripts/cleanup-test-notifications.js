const mongoose = require('mongoose');
const Notification = require('../models/Notification');

async function cleanupTestNotifications() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('✅ Connected to database: sns-rooster');

    // Count test notifications before deletion
    const testNotificationCount = await Notification.countDocuments({
      title: { $regex: /^\[TEST\]/ }
    });

    if (testNotificationCount === 0) {
      console.log('ℹ️  No test notifications found to clean up.');
      return;
    }

    console.log(`🧹 Found ${testNotificationCount} test notifications to clean up...`);

    // Delete all test notifications
    const result = await Notification.deleteMany({
      title: { $regex: /^\[TEST\]/ }
    });

    console.log(`✅ Successfully deleted ${result.deletedCount} test notifications`);

    // Verify cleanup
    const remainingTestNotifications = await Notification.countDocuments({
      title: { $regex: /^\[TEST\]/ }
    });

    if (remainingTestNotifications === 0) {
      console.log('✅ All test notifications have been cleaned up successfully!');
    } else {
      console.log(`⚠️  Warning: ${remainingTestNotifications} test notifications still remain`);
    }

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  } finally {
    mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the cleanup
cleanupTestNotifications(); 