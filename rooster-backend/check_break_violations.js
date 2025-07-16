const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Import models
const BreakType = require('./models/BreakType');
const Attendance = require('./models/Attendance');
const Notification = require('./models/Notification');
const User = require('./models/User');

async function checkAndNotifyBreakViolations() {
  try {
    console.log('=== CHECKING COMPLETED BREAK VIOLATIONS ===');
    
    // Get all break types
    const breakTypes = await BreakType.find({ isActive: true });
    const breakTypeMap = {};
    breakTypes.forEach(type => {
      breakTypeMap[type._id.toString()] = type;
    });
    
    // Check recent attendance records for completed break violations
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    
    const recentAttendance = await Attendance.find({
      date: { $gte: yesterday },
      'breaks.0': { $exists: true } // Has breaks
    }).populate('user', 'firstName lastName email');
    
    console.log(`Found ${recentAttendance.length} attendance records with breaks in the last 2 days`);
    
    let violationsFound = 0;
    let notificationsSent = 0;
    
    for (const attendance of recentAttendance) {
      for (const breakItem of attendance.breaks) {
        if (breakItem.end && breakItem.type) {
          const breakType = breakTypeMap[breakItem.type.toString()];
          if (!breakType) continue;
          
          const duration = breakItem.duration || 0;
          const durationMinutes = Math.round(duration / (1000 * 60));
          const maxMinutes = breakType.maxDuration;
          
          if (durationMinutes > maxMinutes) {
            violationsFound++;
            const overMinutes = durationMinutes - maxMinutes;
            
            console.log(`⚠️  VIOLATION: ${attendance.user.firstName} ${attendance.user.lastName}`);
            console.log(`   - Break Type: ${breakType.displayName}`);
            console.log(`   - Date: ${attendance.date.toDateString()}`);
            console.log(`   - Duration: ${durationMinutes} minutes`);
            console.log(`   - Max Allowed: ${maxMinutes} minutes`);
            console.log(`   - Over by: ${overMinutes} minutes`);
            
            // Check if notification already exists for this violation
            const existingNotification = await Notification.findOne({
              user: attendance.user._id,
              title: 'Break Time Violation',
              message: { $regex: new RegExp(`${breakType.displayName}.*exceeded.*${overMinutes}`, 'i') },
              createdAt: { $gte: attendance.date }
            });
            
            if (!existingNotification) {
              // Send notification for the violation
              const notification = new Notification({
                user: attendance.user._id,
                role: 'employee',
                title: 'Break Time Violation',
                message: `Your ${breakType.displayName} on ${attendance.date.toDateString()} exceeded the limit by ${overMinutes} minutes. Please be mindful of break time limits.`,
                type: 'break_violation',
                link: '/attendance',
                isRead: false,
              });
              await notification.save();
              notificationsSent++;
              console.log(`   ✅ Notification sent to ${attendance.user.firstName}`);
            } else {
              console.log(`   ℹ️  Notification already sent`);
            }
            console.log('');
          }
        }
      }
    }
    
    console.log(`=== SUMMARY ===`);
    console.log(`Found ${violationsFound} break violations`);
    console.log(`Sent ${notificationsSent} new notifications`);
    
    if (violationsFound === 0) {
      console.log('✅ No break violations found in recent records');
    }
    
  } catch (error) {
    console.error('Error checking break violations:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkAndNotifyBreakViolations(); 