const mongoose = require('mongoose');
const PerformanceReview = require('../models/PerformanceReview');
const { Logger } = require('../config/logger');

// Database connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster';

async function migratePerformanceReviewStatuses() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    Logger.info('Connected to MongoDB');

    // Find all performance reviews with old status values
    const oldStatusReviews = await PerformanceReview.find({
      status: { $in: ['in_progress'] }
    });

    Logger.info(`Found ${oldStatusReviews.length} performance reviews with old status values`);

    if (oldStatusReviews.length === 0) {
      Logger.info('No reviews need migration');
      return;
    }

    // Update status from 'in_progress' to 'submitted_for_employee_review'
    // This assumes that reviews in 'in_progress' should be moved to the employee review phase
    const updateResult = await PerformanceReview.updateMany(
      { status: 'in_progress' },
      { 
        $set: { 
          status: 'submitted_for_employee_review',
          updatedAt: new Date()
        }
      }
    );

    Logger.info(`Successfully migrated ${updateResult.modifiedCount} performance reviews`);
    Logger.info('Migration completed successfully');

    // Verify the migration
    const remainingOldStatus = await PerformanceReview.find({
      status: { $in: ['in_progress'] }
    });

    if (remainingOldStatus.length === 0) {
      Logger.info('✅ All old status values have been successfully migrated');
    } else {
      Logger.warn(`⚠️  ${remainingOldStatus.length} reviews still have old status values`);
    }

  } catch (error) {
    Logger.error('Error during migration:', error);
    throw error;
  } finally {
    // Close the database connection
    await mongoose.connection.close();
    Logger.info('Database connection closed');
  }
}

// Run the migration if this script is executed directly
if (require.main === module) {
  migratePerformanceReviewStatuses()
    .then(() => {
      Logger.info('Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      Logger.error('Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = { migratePerformanceReviewStatuses }; 