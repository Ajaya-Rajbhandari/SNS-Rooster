const mongoose = require('mongoose');
const BreakType = require('../models/BreakType');

async function initializeBreakTypes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Default break types configuration
    const defaultBreakTypes = [
      {
        name: 'lunch',
        displayName: 'Lunch Break',
        description: 'Main meal break during work hours',
        color: '#10B981', // Green
        icon: 'restaurant',
        minDuration: 30,
        maxDuration: 90,
        dailyLimit: 1,
        weeklyLimit: null,
        requiresApproval: false,
        isPaid: true,
        isActive: true,
        priority: 1
      },
      {
        name: 'coffee',
        displayName: 'Coffee Break',
        description: 'Short refreshment break',
        color: '#8B5CF6', // Purple
        icon: 'local_cafe',
        minDuration: 5,
        maxDuration: 20,
        dailyLimit: 3,
        weeklyLimit: null,
        requiresApproval: false,
        isPaid: true,
        isActive: true,
        priority: 2
      },
      {
        name: 'personal',
        displayName: 'Personal Break',
        description: 'Personal time for various needs',
        color: '#F59E0B', // Amber
        icon: 'person',
        minDuration: 5,
        maxDuration: 30,
        dailyLimit: 2,
        weeklyLimit: null,
        requiresApproval: false,
        isPaid: true,
        isActive: true,
        priority: 3
      },
      {
        name: 'medical',
        displayName: 'Medical Break',
        description: 'Health-related break or medical appointment',
        color: '#EF4444', // Red
        icon: 'local_hospital',
        minDuration: 10,
        maxDuration: 120,
        dailyLimit: null,
        weeklyLimit: null,
        requiresApproval: true,
        isPaid: true,
        isActive: true,
        priority: 4
      },
      {
        name: 'smoke',
        displayName: 'Smoke Break',
        description: 'Smoking break',
        color: '#6B7280', // Gray
        icon: 'smoking_rooms',
        minDuration: 5,
        maxDuration: 15,
        dailyLimit: 4,
        weeklyLimit: null,
        requiresApproval: false,
        isPaid: false,
        isActive: true,
        priority: 5
      },
      {
        name: 'other',
        displayName: 'Other Break',
        description: 'Miscellaneous break type',
        color: '#6B7280', // Gray
        icon: 'more_horiz',
        minDuration: 5,
        maxDuration: 60,
        dailyLimit: null,
        weeklyLimit: null,
        requiresApproval: true,
        isPaid: true,
        isActive: true,
        priority: 6
      }
    ];

    // Clear existing break types
    await BreakType.deleteMany({});
    console.log('Cleared existing break types');

    // Insert default break types
    const insertedBreakTypes = await BreakType.insertMany(defaultBreakTypes);
    console.log(`Inserted ${insertedBreakTypes.length} break types:`);
    
    insertedBreakTypes.forEach(breakType => {
      console.log(`- ${breakType.displayName} (${breakType.name})`);
    });

    console.log('\nBreak types initialized successfully!');
    
  } catch (error) {
    console.error('Error initializing break types:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the initialization
if (require.main === module) {
  initializeBreakTypes();
}

module.exports = initializeBreakTypes;