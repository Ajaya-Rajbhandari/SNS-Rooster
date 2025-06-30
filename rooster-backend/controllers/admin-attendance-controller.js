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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

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
      const todayBreaksOfType = attendance.breaks.filter(b => b.type === breakType).length;
      if (todayBreaksOfType >= breakTypeConfig.dailyLimit) {
        return res.status(400).json({
          message: `Daily limit of ${breakTypeConfig.displayName}s exceeded`
        });
      }
    }

    // Check weekly limit for this break type (if needed)
    if (breakTypeConfig.weeklyLimit) {
      const weekStart = new Date(today);
      weekStart.setDate(today.getDate() - today.getDay());
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 7);

      const weeklyAttendance = await Attendance.find({
        user: userId,
        date: { $gte: weekStart, $lt: weekEnd }
      });

      const weeklyBreaksOfType = weeklyAttendance.reduce((count, att) => {
        return count + att.breaks.filter(b => b.type === breakType).length;
      }, 0);

      if (weeklyBreaksOfType >= breakTypeConfig.weeklyLimit) {
        return res.status(400).json({
          message: `Weekly limit of ${breakTypeConfig.displayName}s exceeded`
        });
      }
    }

    const newBreak = {
      start: new Date(),
      type: breakType,
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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

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
    const breakTypeConfig = await BreakType.findOne({ name: lastBreak.type || 'other' });

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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

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