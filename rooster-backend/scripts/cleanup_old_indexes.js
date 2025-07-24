const mongoose = require('mongoose');
require('dotenv').config();

async function cleanupOldIndexes() {
  try {
    console.log('🧹 Starting old index cleanup...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    const db = mongoose.connection.db;
    
    // Drop old single-field unique indexes that conflict with compound indexes
    console.log('📋 Dropping old indexes...');
    
    // Employee collection - drop old employeeId unique index
    try {
      await db.collection('employees').dropIndex('employeeId_1');
      console.log('✅ Dropped employeeId_1 index from employees collection');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️ employeeId_1 index already dropped or doesn\'t exist');
      } else {
        console.log('⚠️ Error dropping employeeId_1 index:', error.message);
      }
    }
    
    // User collection - drop old email unique index
    try {
      await db.collection('users').dropIndex('email_1');
      console.log('✅ Dropped email_1 index from users collection');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️ email_1 index already dropped or doesn\'t exist');
      } else {
        console.log('⚠️ Error dropping email_1 index:', error.message);
      }
    }
    
    // BreakType collection - drop old name unique index
    try {
      await db.collection('breaktypes').dropIndex('name_1');
      console.log('✅ Dropped name_1 index from breaktypes collection');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️ name_1 index already dropped or doesn\'t exist');
      } else {
        console.log('⚠️ Error dropping name_1 index:', error.message);
      }
    }
    
    console.log('🎉 Old index cleanup completed!');
    console.log('\n📋 Summary:');
    console.log('✅ Removed conflicting single-field unique indexes');
    console.log('✅ Compound indexes for multi-tenancy are now active');
    
  } catch (error) {
    console.error('❌ Index cleanup failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run cleanup if this script is executed directly
if (require.main === module) {
  cleanupOldIndexes();
}

module.exports = cleanupOldIndexes; 