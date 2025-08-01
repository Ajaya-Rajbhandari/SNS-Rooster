/*
  clear-demo-data.js – Development helper
  --------------------------------------------------
  Deletes ALL documents from the Notification and Leave
  collections so you can start with a clean slate while
  testing push-notifications and leave workflows.

  ⚠️  DO NOT run this in production.  ⚠️
*/
const mongoose = require('mongoose');
require('dotenv').config({ path: process.env.NODE_ENV === 'production' ? '.env' : '.env.development' });

(async () => {
  const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/sns_rooster';

  try {
    console.log('Connecting to MongoDB:', mongoUri);
    await mongoose.connect(mongoUri);
    console.log('Connected');

    const Notification = require('../models/Notification');
    const Leave = require('../models/Leave');

    const notifDel = await Notification.deleteMany({});
    const leaveDel = await Leave.deleteMany({});

    console.log(`Deleted ${notifDel.deletedCount} notifications`);
    console.log(`Deleted ${leaveDel.deletedCount} leave requests`);
  } catch (err) {
    console.error('Error clearing demo data:', err);
  } finally {
    await mongoose.disconnect();
    process.exit();
  }
})(); 