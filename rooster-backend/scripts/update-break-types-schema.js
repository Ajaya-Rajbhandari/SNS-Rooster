const mongoose = require('mongoose');
const BreakType = require('../models/BreakType');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/sns_rooster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function updateBreakTypes() {
  try {
    console.log('Checking existing break types...');
    
    const breakTypes = await BreakType.find({});
    console.log(`Found ${breakTypes.length} break types`);
    
    for (const breakType of breakTypes) {
      console.log(`Checking break type: ${breakType.name}`);
      
      // If displayName doesn't exist, set it to the name
      if (!breakType.displayName) {
        console.log(`  Adding displayName for ${breakType.name}`);
        breakType.displayName = breakType.name.charAt(0).toUpperCase() + breakType.name.slice(1);
        await breakType.save();
      }
      
      // Ensure the name field is a valid string (not from enum)
      if (breakType.name && typeof breakType.name === 'string') {
        console.log(`  Name field is valid: ${breakType.name}`);
      }
    }
    
    console.log('Break types update completed successfully!');
    
    // Show final state
    const updatedBreakTypes = await BreakType.find({});
    console.log('\nFinal break types:');
    updatedBreakTypes.forEach(bt => {
      console.log(`  - ${bt.name} (displayName: ${bt.displayName})`);
    });
    
  } catch (error) {
    console.error('Error updating break types:', error);
  } finally {
    mongoose.connection.close();
  }
}

updateBreakTypes(); 