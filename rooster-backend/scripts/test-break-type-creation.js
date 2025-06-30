const mongoose = require('mongoose');
const BreakType = require('../models/BreakType');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/sns_rooster', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function testBreakTypeCreation() {
  try {
    console.log('Testing break type creation with custom name...');
    
    // Test creating a break type with a custom name
    const customBreakType = new BreakType({
      name: 'custom_break_type',
      displayName: 'Custom Break Type',
      description: 'A test break type with custom name',
      color: '#10B981',
      icon: 'restaurant',
      minDuration: 15,
      maxDuration: 60,
      dailyLimit: 2,
      isPaid: true,
      requiresApproval: false,
      isActive: true
    });
    
    await customBreakType.save();
    console.log('✅ Successfully created break type with custom name:', customBreakType.name);
    
    // Test creating another break type with different custom name
    const anotherBreakType = new BreakType({
      name: 'admin_created_break',
      displayName: 'Admin Created Break',
      description: 'Another test break type',
      color: '#3B82F6',
      icon: 'local_cafe',
      minDuration: 10,
      maxDuration: 30,
      dailyLimit: 3,
      isPaid: false,
      requiresApproval: true,
      isActive: true
    });
    
    await anotherBreakType.save();
    console.log('✅ Successfully created another break type:', anotherBreakType.name);
    
    // Fetch all break types to verify
    const allBreakTypes = await BreakType.find({});
    console.log('\n📋 All break types in database:');
    allBreakTypes.forEach(bt => {
      console.log(`  - ${bt.name} (${bt.displayName}) - Active: ${bt.isActive}`);
    });
    
    // Clean up - remove test break types
    await BreakType.deleteMany({ name: { $in: ['custom_break_type', 'admin_created_break'] } });
    console.log('\n🧹 Cleaned up test break types');
    
  } catch (error) {
    console.error('❌ Error testing break type creation:', error.message);
    if (error.code === 11000) {
      console.error('  This is a duplicate key error - the name field should be unique');
    }
  } finally {
    mongoose.connection.close();
  }
}

testBreakTypeCreation(); 