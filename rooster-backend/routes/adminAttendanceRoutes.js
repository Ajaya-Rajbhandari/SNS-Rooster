const express = require('express');
const router = express.Router();
const Attendance = require('../models/Attendance');
const BreakType = require('../models/BreakType');
const auth = require('../middleware/auth');

// Admin middleware to check if user is admin
const adminAuth = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};

// Admin: Start break for any employee
router.post('/admin/start-break/:userId', auth, adminAuth, async (req, res) => {
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
          message: `Daily limit of ${breakTypeConfig.dailyLimit} ${breakTypeConfig.displayName}s exceeded` 
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
          message: `Weekly limit of ${breakTypeConfig.weeklyLimit} ${breakTypeConfig.displayName}s exceeded` 
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
});

// Admin: End break for any employee
router.post('/admin/end-break/:userId', auth, adminAuth, async (req, res) => {
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
    lastBreak.duration = Math.round((lastBreak.end - lastBreak.start) / (1000 * 60)); // Duration in minutes

    // Validate break duration if break type config exists
    if (breakTypeConfig) {
      if (breakTypeConfig.minDuration && lastBreak.duration < breakTypeConfig.minDuration) {
        return res.status(400).json({ 
          message: `${breakTypeConfig.displayName} must be at least ${breakTypeConfig.minDuration} minutes` 
        });
      }
      
      if (breakTypeConfig.maxDuration && lastBreak.duration > breakTypeConfig.maxDuration) {
        // Log warning but don't prevent ending the break
        console.warn(`Break duration (${lastBreak.duration}min) exceeded maximum for ${breakTypeConfig.displayName} (${breakTypeConfig.maxDuration}min)`);
      }
    }

    // Recalculate total break duration
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
});

// General: Get available break types (for employees)
router.get('/break-types', auth, async (req, res) => {
  try {
    const breakTypes = await BreakType.find({ isActive: true }).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error('Error fetching break types:', error);
    res.status(500).json({ message: 'Failed to fetch break types' });
  }
});

// Admin: Get current break status for an employee
router.get('/admin/break-status/:userId', auth, adminAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
    }).populate('user', 'name email');

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
      totalBreakDuration: attendance.totalBreakDuration || 0
    });
  } catch (error) {
    console.error('Admin get break status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all break types
router.get('/admin/break-types', auth, adminAuth, async (req, res) => {
  try {
    const breakTypes = await BreakType.find({}).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error('Get break types error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new break type
router.post('/admin/break-types', auth, adminAuth, async (req, res) => {
  try {
    const breakType = new BreakType(req.body);
    await breakType.save();
    res.status(201).json({ message: 'Break type created successfully', breakType });
  } catch (error) {
    console.error('Create break type error:', error);
    if (error.code === 11000) {
      res.status(400).json({ message: 'Break type name already exists' });
    } else {
      res.status(500).json({ message: 'Server error' });
    }
  }
});

// Update break type
router.put('/admin/break-types/:id', auth, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!breakType) {
      return res.status(404).json({ message: 'Break type not found' });
    }
    
    res.status(200).json({ message: 'Break type updated successfully', breakType });
  } catch (error) {
    console.error('Update break type error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete break type (soft delete by setting isActive to false)
router.delete('/admin/break-types/:id', auth, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );
    
    if (!breakType) {
      return res.status(404).json({ message: 'Break type not found' });
    }
    
    res.status(200).json({ message: 'Break type deactivated successfully' });
  } catch (error) {
    console.error('Delete break type error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get break history with filters
router.get('/admin/break-history', auth, adminAuth, async (req, res) => {
  try {
    const { userId, breakType, startDate, endDate, page = 1, limit = 50 } = req.query;
    
    const filter = {};
    if (userId) filter.user = userId;
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }
    
    const attendance = await Attendance.find(filter)
      .populate('user', 'name email')
      .sort({ date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    // Filter breaks by type if specified
    const filteredAttendance = attendance.map(att => {
      if (breakType) {
        att.breaks = att.breaks.filter(b => b.type === breakType);
      }
      return att;
    }).filter(att => att.breaks.length > 0);
    
    res.status(200).json({ 
      attendance: filteredAttendance,
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (error) {
    console.error('Get break history error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;