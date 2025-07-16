const Attendance = require('../models/Attendance');
const BreakType = require('../models/BreakType');

// Admin middleware to check if user is admin
const adminAuth = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};

// Admin: Start break for any employee
exports.adminStartBreak = async (req, res) => {
  try {
    const { userId } = req.params;
    const { breakType = 'other', reason } = req.body;
    // Use UTC midnight for consistency with attendance records
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0,
        0,
        0,
        0
      )
    );

    // Validate break type
    const breakTypeConfig = await BreakType.findOne({ name: breakType, isActive: true });
    if (!breakTypeConfig) {
      return res.status(400).json({ message: 'Invalid or inactive break type' });
    }

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
      checkInTime: { $exists: true },
      checkOutTime: { $exists: false },
    });

    if (!attendance) {
      return res.status(400).json({ message: 'Cannot start break: Employee not checked in or already checked out.' });
    }

    // Check if already on break
    const lastBreak = attendance.breaks.length > 0 ? attendance.breaks[attendance.breaks.length - 1] : null;
    if (lastBreak && !lastBreak.end) {
      return res.status(400).json({ message: 'Employee is already on break.' });
    }

    // Check daily limit for this break type
    if (breakTypeConfig.dailyLimit) {
      const todayBreaksOfType = attendance.breaks.filter(b => b.type.toString() === breakTypeConfig._id.toString()).length;
      if (todayBreaksOfType >= breakTypeConfig.dailyLimit) {
        return res.status(400).json({
          message: `Daily limit of ${breakTypeConfig.displayName}s exceeded`
        });
      }
    }

    // Check weekly limit for this break type (if needed)
    if (breakTypeConfig.weeklyLimit) {
      const weekStart = new Date(today);
      weekStart.setUTCDate(today.getUTCDate() - today.getUTCDay());
      const weekEnd = new Date(weekStart);
      weekEnd.setUTCDate(weekStart.getUTCDate() + 7);

      const weeklyAttendance = await Attendance.find({
        user: userId,
        date: { $gte: weekStart, $lt: weekEnd }
      });

      const weeklyBreaksOfType = weeklyAttendance.reduce((count, att) => {
        return count + att.breaks.filter(b => b.type.toString() === breakTypeConfig._id.toString()).length;
      }, 0);

      if (weeklyBreaksOfType >= breakTypeConfig.weeklyLimit) {
        return res.status(400).json({
          message: `Weekly limit of ${breakTypeConfig.displayName}s exceeded`
        });
      }
    }

    const newBreak = {
      start: new Date(),
      type: breakTypeConfig._id, // Use the ObjectId, not the name
      reason: reason || '',
      approvedBy: req.user.userId
    };

    attendance.breaks.push(newBreak);
    await attendance.save();

    res.status(200).json({
      message: `${breakTypeConfig.displayName} started successfully for employee`,
      attendance,
      breakType: breakTypeConfig
    });
  } catch (error) {
    console.error('Admin start break error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Admin: End break for any employee
exports.adminEndBreak = async (req, res) => {
  try {
    const { userId } = req.params;
    // Use UTC midnight for consistency with attendance records
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0,
        0,
        0,
        0
      )
    );

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
      checkInTime: { $exists: true },
      checkOutTime: { $exists: false },
    });

    if (!attendance) {
      return res.status(400).json({ message: 'Cannot end break: Employee not checked in or already checked out.' });
    }

    // Find the last break that hasn't ended
    const lastBreak = attendance.breaks.length > 0 ? attendance.breaks[attendance.breaks.length - 1] : null;
    if (!lastBreak || lastBreak.end) {
      return res.status(400).json({ message: 'Employee is not currently on break.' });
    }

    // Get break type configuration for validation
    const breakTypeConfig = await BreakType.findById(lastBreak.type);

    // End the break and calculate duration
    lastBreak.end = new Date();
    // Store duration in milliseconds for consistency
    lastBreak.duration = lastBreak.end - lastBreak.start; // ms

    // Validate break duration if break type config exists
    if (breakTypeConfig) {
      if (breakTypeConfig.minDuration && lastBreak.duration < breakTypeConfig.minDuration) {
        return res.status(400).json({
          message: `${breakTypeConfig.displayName} must be at least ${breakTypeConfig.minDuration} minutes`
        });
      }

      if (breakTypeConfig.maxDuration && lastBreak.duration > breakTypeConfig.maxDuration) {
        // Log warning but don't prevent ending the break
        console.warn(`Break duration (${lastBreak.duration}ms) exceeded maximum for ${breakTypeConfig.displayName} (${breakTypeConfig.maxDuration}ms)`);
        
        // Send notification to employee about break time violation
        await _sendBreakTimeViolationNotification(userId, breakTypeConfig, lastBreak.duration);
      }
    }

    // Recalculate total break duration
    // Sum all break durations in ms
    attendance.totalBreakDuration = attendance.breaks.reduce((total, breakItem) => {
      return total + (breakItem.duration || 0);
    }, 0);

    await attendance.save();

    res.status(200).json({
      message: `${breakTypeConfig ? breakTypeConfig.displayName : 'Break'} ended successfully for employee`,
      attendance,
      breakDuration: lastBreak.duration,
      breakType: breakTypeConfig
    });
  } catch (error) {
    console.error('Admin end break error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// General: Get available break types (for employees)
exports.getBreakTypes = async (req, res) => {
  try {
    const breakTypes = await BreakType.find({ isActive: true }).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error('Error fetching break types:', error);
    res.status(500).json({ message: 'Failed to fetch break types' });
  }
};

// Admin: Get current break status for an employee
exports.getAdminBreakStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    // Use UTC midnight for consistency with attendance records
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0,
        0,
        0,
        0
      )
    );

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
    }).populate('user', 'firstName lastName email');

    if (!attendance) {
      return res.status(404).json({ message: 'No attendance record found for today' });
    }

    const lastBreak = attendance.breaks.length > 0 ? attendance.breaks[attendance.breaks.length - 1] : null;
    const isOnBreak = lastBreak && !lastBreak.end;
    const isCheckedIn = attendance.checkInTime && !attendance.checkOutTime;

    res.json({
      employee: attendance.user,
      isCheckedIn,
      isOnBreak,
      currentBreak: isOnBreak ? lastBreak : null,
      totalBreaks: attendance.breaks.length,
    });
  } catch (error) {
    console.error('Admin get break status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Utility: Calculate status for a given attendance record
function getAttendanceStatusForRecord(att) {
  if (!att) return 'absent';
  if (att.checkOutTime) return 'clocked_out';
  if (att.checkInTime) {
    const breaks = att.breaks || [];
    const lastBreak = breaks.length > 0 ? breaks[breaks.length - 1] : null;
    if (lastBreak && lastBreak.start && !lastBreak.end) {
      return 'on_break';
    }
    return 'present';
  }
  return 'absent';
}

module.exports.getAttendanceStatusForRecord = getAttendanceStatusForRecord;

// Helper function to send break time violation notifications
async function _sendBreakTimeViolationNotification(userId, breakTypeConfig, actualDuration) {
  try {
    const Notification = require('../models/Notification');
    const FCMToken = require('../models/FCMToken');
    const { sendNotificationToUser } = require('../services/notificationService');
    
    // Calculate duration in minutes
    const actualMinutes = Math.round(actualDuration / (1000 * 60));
    const maxMinutes = Math.round(breakTypeConfig.maxDuration / (1000 * 60));
    const overMinutes = actualMinutes - maxMinutes;
    
    const title = 'Break Time Exceeded';
    const message = `Your ${breakTypeConfig.displayName} exceeded the limit by ${overMinutes} minutes. Please be mindful of break time limits.`;
    
    // Create database notification
    const notification = new Notification({
      user: userId,
      title: title,
      message: message,
      type: 'break_violation',
      link: '/attendance',
      isRead: false,
    });
    await notification.save();
    
    // Send FCM push notification
    const tokenDoc = await FCMToken.findOne({ userId: userId });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        title,
        message,
        { 
          type: 'break_violation', 
          breakType: breakTypeConfig.displayName,
          actualDuration: actualMinutes,
          maxDuration: maxMinutes,
          overMinutes: overMinutes
        }
      );
    }
    
    console.log(`Break time violation notification sent to user ${userId} for ${breakTypeConfig.displayName}`);
  } catch (error) {
    console.error('Error sending break time violation notification:', error);
  }
}

// Admin: Monitor ongoing breaks and send warnings
exports.monitorOngoingBreaks = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    // Use UTC midnight for consistency with attendance records
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0,
        0,
        0,
        0
      )
    );

    // Find all attendance records with ongoing breaks
    const attendanceWithOngoingBreaks = await Attendance.find({
      date: today,
      'breaks.end': { $exists: false }
    }).populate('user', 'firstName lastName email')
      .populate('breaks.type', 'displayName maxDuration');

    const warnings = [];

    for (const attendance of attendanceWithOngoingBreaks) {
      const lastBreak = attendance.breaks[attendance.breaks.length - 1];
      if (lastBreak && !lastBreak.end && lastBreak.type) {
        const breakStart = new Date(lastBreak.start);
        const currentDuration = now.getTime() - breakStart.getTime();
        const maxDuration = lastBreak.type.maxDuration * 1000 * 60; // Convert to milliseconds
        const warningThreshold = maxDuration * 0.8; // Warn at 80% of max duration

        if (currentDuration >= maxDuration) {
          // Break time exceeded - send violation notification
          await _sendBreakTimeViolationNotification(
            attendance.user._id,
            lastBreak.type,
            currentDuration
          );
          warnings.push({
            userId: attendance.user._id,
            userName: `${attendance.user.firstName} ${attendance.user.lastName}`,
            breakType: lastBreak.type.displayName,
            duration: Math.round(currentDuration / (1000 * 60)),
            maxDuration: Math.round(maxDuration / (1000 * 60)),
            status: 'exceeded'
          });
        } else if (currentDuration >= warningThreshold) {
          // Approaching limit - send warning notification
          await _sendBreakTimeWarningNotification(
            attendance.user._id,
            lastBreak.type,
            currentDuration,
            maxDuration
          );
          warnings.push({
            userId: attendance.user._id,
            userName: `${attendance.user.firstName} ${attendance.user.lastName}`,
            breakType: lastBreak.type.displayName,
            duration: Math.round(currentDuration / (1000 * 60)),
            maxDuration: Math.round(maxDuration / (1000 * 60)),
            status: 'warning'
          });
        }
      }
    }

    res.json({
      message: 'Break monitoring completed',
      warnings: warnings,
      totalOngoingBreaks: attendanceWithOngoingBreaks.length
    });
  } catch (error) {
    console.error('Monitor ongoing breaks error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Helper function to send break time warning notifications
async function _sendBreakTimeWarningNotification(userId, breakTypeConfig, currentDuration, maxDuration) {
  try {
    const Notification = require('../models/Notification');
    const FCMToken = require('../models/FCMToken');
    const { sendNotificationToUser } = require('../services/notificationService');
    
    // Calculate duration in minutes
    const currentMinutes = Math.round(currentDuration / (1000 * 60));
    const maxMinutes = Math.round(maxDuration / (1000 * 60));
    const remainingMinutes = maxMinutes - currentMinutes;
    
    const title = 'Break Time Warning';
    const message = `Your ${breakTypeConfig.displayName} is approaching the limit. You have approximately ${remainingMinutes} minutes remaining.`;
    
    // Create database notification
    const notification = new Notification({
      user: userId,
      title: title,
      message: message,
      type: 'break_warning',
      link: '/attendance',
      isRead: false,
    });
    await notification.save();
    
    // Send FCM push notification
    const tokenDoc = await FCMToken.findOne({ userId: userId });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        title,
        message,
        { 
          type: 'break_warning', 
          breakType: breakTypeConfig.displayName,
          currentDuration: currentMinutes,
          maxDuration: maxMinutes,
          remainingMinutes: remainingMinutes
        }
      );
    }
    
    console.log(`Break time warning notification sent to user ${userId} for ${breakTypeConfig.displayName}`);
  } catch (error) {
    console.error('Error sending break time warning notification:', error);
  }
}