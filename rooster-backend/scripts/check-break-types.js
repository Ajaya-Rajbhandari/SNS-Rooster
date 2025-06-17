const mongoose = require('mongoose');
const BreakType = require('../models/BreakType');

async function checkBreakTypes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Count documents
    const count = await BreakType.countDocuments();
    console.log('Total break types in database:', count);

    // Get all break types
    const breakTypes = await BreakType.find();
    console.log('\nBreak types found:');
    breakTypes.forEach(bt => {
      console.log(`- ${bt.displayName} (${bt.name}) - Active: ${bt.isActive}`);
    });

    if (breakTypes.length === 0) {
      console.log('\nNo break types found in database!');
    }

  } catch (error) {
    console.error('Error checking break types:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run the check
if (require.main === module) {
  checkBreakTypes();
}

module.exports = checkBreakTypes;