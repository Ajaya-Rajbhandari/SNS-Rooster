// Script to update all users to add emergencyRelationship field if missing
// Run this with: node scripts/add_emergency_relationship_field.js

const mongoose = require('mongoose');
const User = require('../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/YOUR_DB_NAME'; // Update with your DB name

async function addEmergencyRelationshipField() {
  await mongoose.connect(MONGODB_URI);
  const result = await User.updateMany(
    { emergencyRelationship: { $exists: false } },
    { $set: { emergencyRelationship: '' } }
  );
  console.log(`Updated ${result.nModified || result.modifiedCount} users.`);
  await mongoose.disconnect();
}

addEmergencyRelationshipField().catch(err => {
  console.error(err);
  process.exit(1);
});
