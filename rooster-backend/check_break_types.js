const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Import models
const BreakType = require('./models/BreakType');
const Attendance = require('./models/Attendance');

async function checkBreakTypes() {
  try {
    console.log('=== CHECKING BREAK TYPES ===');
    
    // Get all break types
    const breakTypes = await BreakType.find({ isActive: true });
    
    console.log(`Total active break types: ${breakTypes.length}`);
    
    if (breakTypes.length === 0) {
      console.log('No break types configured!');
      return;
    }
    
    console.log('\n=== BREAK TYPE CONFIGURATIONS ===');
    breakTypes.forEach((type, index) => {
      console.log(`${index + 1}. ${type.displayName} (${type.name})`);
      console.log(`   - Min Duration: ${type.minDuration} minutes`);
      console.log(`   - Max Duration: ${type.maxDuration} minutes`);
      console.log(`   - Daily Limit: ${type.dailyLimit || 'Unlimited'}`);
      console.log(`   - Weekly Limit: ${type.weeklyLimit || 'Unlimited'}`);
      console.log(`   - Requires Approval: ${type.requiresApproval ? 'Yes' : 'No'}`);
      console.log(`   - Is Paid: ${type.isPaid ? 'Yes' : 'No'}`);
      console.log('');
    });
    
    // Check recent attendance records for break violations
    console.log('=== CHECKING RECENT BREAK VIOLATIONS ===');
    
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    
    const recentAttendance = await Attendance.find({
      date: { $gte: yesterday },
      'breaks.0': { $exists: true } // Has breaks
    }).populate('user', 'firstName lastName email')
      .populate('breaks.type', 'displayName maxDuration');
    
    console.log(`Found ${recentAttendance.length} attendance records with breaks in the last 2 days`);
    
    let violationsFound = 0;
    
    for (const attendance of recentAttendance) {
      for (const breakItem of attendance.breaks) {
        if (breakItem.end && breakItem.type) {
          const duration = breakItem.duration || 0;
          const durationMinutes = Math.round(duration / (1000 * 60));
          const maxMinutes = breakItem.type.maxDuration;
          
          if (durationMinutes > maxMinutes) {
            violationsFound++;
            console.log(`⚠️  VIOLATION: ${attendance.user.firstName} ${attendance.user.lastName}`);
            console.log(`   - Break Type: ${breakItem.type.displayName}`);
            console.log(`   - Date: ${attendance.date.toDateString()}`);
            console.log(`   - Duration: ${durationMinutes} minutes`);
            console.log(`   - Max Allowed: ${maxMinutes} minutes`);
            console.log(`   - Over by: ${durationMinutes - maxMinutes} minutes`);
            console.log('');
          }
        }
      }
    }
    
    if (violationsFound === 0) {
      console.log('✅ No break violations found in recent records');
    } else {
      console.log(`⚠️  Found ${violationsFound} break violations`);
    }
    
  } catch (error) {
    console.error('Error checking break types:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkBreakTypes(); 