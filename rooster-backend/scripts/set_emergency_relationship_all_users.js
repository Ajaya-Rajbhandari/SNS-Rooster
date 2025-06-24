// Script to set emergencyRelationship field for all users
// Run this with: node scripts/set_emergency_relationship_all_users.js

const mongoose = require('mongoose');
const User = require('../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/YOUR_DB_NAME'; // Update with your DB name

async function setEmergencyRelationshipForAll() {
  await mongoose.connect(MONGODB_URI);
  const result = await User.updateMany(
    {}, // Match all users
    { $set: { emergencyRelationship: '' } }
  );
  console.log(`Updated ${result.nModified || result.modifiedCount} users.`);
  await mongoose.disconnect();
}

setEmergencyRelationshipForAll().catch(err => {
  console.error(err);
  process.exit(1);
});
