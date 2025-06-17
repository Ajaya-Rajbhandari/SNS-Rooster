const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const BreakType = require('../models/BreakType');

// Check-in (User can check-in once per day)
router.post('/check-in', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existingAttendance = await Attendance.findOne({
      user: userId,
      date: today,
    });

    if (existingAttendance) {
      return res.status(400).json({ message: 'Already checked in for today.' });
    }

    const attendance = new Attendance({
      user: userId,
      date: today,
      checkInTime: new Date(),
    });

    await attendance.save();
    res.status(201).json({ message: 'Check-in successful', attendance });
  } catch (error) {
    console.error('Check-in error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Check-out
router.patch('/check-out', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
      checkOutTime: { $exists: false }, // Only update if not already checked out
    });

    if (!attendance) {
      return res.status(400).json({ message: 'Not checked in for today or already checked out.' });
    }

    attendance.checkOutTime = new Date();
    await attendance.save();

    res.json({ message: 'Check-out successful', attendance });
  } catch (error) {
    console.error('Check-out error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Start break
router.post('/start-break', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
      checkInTime: { $exists: true }, // Must be checked in to start a break
      checkOutTime: { $exists: false }, // Must not be checked out
    });

    if (!attendance) {
      return res.status(400).json({ message: 'Cannot start break: User not checked in.' });
    }

    // Check if already on break (last break in array has no end time)
    const lastBreak = attendance.breaks.length > 0 ? attendance.breaks[attendance.breaks.length - 1] : null;
    if (lastBreak && !lastBreak.end) {
      return res.status(400).json({ message: 'Already on break.' });
    }

    attendance.breaks.push({ start: new Date() });
    await attendance.save();

    res.status(200).json({ message: 'Break started successfully', attendance });
  } catch (error) {
    console.error('Start break error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// End break
router.patch('/end-break', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await Attendance.findOne({
      user: userId,
      date: today,
      checkInTime: { $exists: true },
      checkOutTime: { $exists: false },
    });

    if (!attendance) {
      return res.status(400).json({ message: 'Cannot end break: User not checked in or already checked out.' });
    }

    const lastBreak = attendance.breaks.length > 0 ? attendance.breaks[attendance.breaks.length - 1] : null;

    if (!lastBreak || lastBreak.end) {
      return res.status(400).json({ message: 'Not currently on break.' });
    }

    lastBreak.end = new Date();
    lastBreak.duration = lastBreak.end.getTime() - lastBreak.start.getTime();

    // Calculate total break duration
    attendance.totalBreakDuration = attendance.breaks.reduce((sum, b) => sum + (b.duration || 0), 0);

    await attendance.save();

    res.status(200).json({ message: 'Break ended successfully', attendance });
  } catch (error) {
    console.error('End break error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get current user's own attendance data
router.get('/my-attendance', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const attendanceRecords = await Attendance.find({ user: userId }).populate('user', 'name email role');

    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error('Get my attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get attendance for a specific user (Admin/Manager only, or self)
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Allow users to access their own data, or admin/manager to access any data
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== userId) {
      return res.status(403).json({ message: 'Unauthorized to view this attendance data' });
    }

    const attendanceRecords = await Attendance.find({ user: userId }).populate('user', 'name email role');

    if (!attendanceRecords) {
      return res.status(404).json({ message: 'No attendance records found for this user' });
    }

    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error('Get user attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all attendance records (Admin only)
router.get('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized to view all attendance data' });
    }

    const attendanceRecords = await Attendance.find({}).populate('user', 'name email role');
    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error('Get all attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get available break types (for employees)
router.get('/break-types', auth, async (req, res) => {
  try {
    const breakTypes = await BreakType.find({ isActive: true }).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error('Error fetching break types:', error);
    res.status(500).json({ message: 'Failed to fetch break types' });
  }
});

module.exports = router;