const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const BreakType = require('../models/BreakType');

// Check-in (User can check-in once per day)
router.post('/check-in', auth, async (req, res) => {
  console.log('DEBUG: /check-in req.body:', req.body);
  console.log('DEBUG: /check-in req.user:', req.user);

  // Add logs to trace Authorization header and req.user
  console.log('DEBUG: Authorization header:', req.header('Authorization'));
  console.log('DEBUG: req.user at start of /check-in:', req.user);

  // Add logs to trace req.user before accessing userId
  console.log('DEBUG: req.user before accessing userId:', req.user);
  console.log('DEBUG: Type of req.user:', typeof req.user);

  // Add defensive checks and logs to verify req.user structure
  if (!req.user || typeof req.user !== 'object') {
    console.error('ERROR: req.user is undefined or not an object in /check-in route');
    return res.status(500).json({ message: 'Authentication error: req.user is invalid' });
  }

  try {
    const userId = req.user.userId;
    if (!userId) {
      console.error('ERROR: userId is missing in req.user');
      return res.status(400).json({ message: 'userId is required' });
    }

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
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Duplicate check-in for today or missing userId.' });
    }
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
    console.log('BACKEND_ROUTE_DEBUG: User accessing break-types', req.user);
    console.log('BACKEND_ROUTE_DEBUG: Checking user role:', req.user.role);

    if (req.user.role !== 'employee') {
      console.log('BACKEND_ROUTE_DEBUG: Forbidden - User role is not employee');
      return res.status(403).json({ message: 'Forbidden' });
    }

    const breakTypes = await BreakType.find({});
    console.log('BACKEND_ROUTE_DEBUG: Break types fetched successfully', breakTypes);
    res.status(200).json(breakTypes);
  } catch (error) {
    console.log('BACKEND_ROUTE_DEBUG: Error fetching break types', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// Attendance summary for a user within a date range
router.get('/summary/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { start, end } = req.query;

    // Allow users to access their own data, or admin/manager to access any data
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== userId) {
      return res.status(403).json({ message: 'Unauthorized to view this attendance summary' });
    }

    // Parse date range
    let startDate = start ? new Date(start) : new Date('1970-01-01');
    let endDate = end ? new Date(end) : new Date();
    endDate.setHours(23, 59, 59, 999); // Include the whole end day

    // Find attendance records for user in range
    const records = await Attendance.find({
      user: userId,
      date: { $gte: startDate, $lte: endDate },
      status: 'present',
    });

    // Calculate summary
    let totalDaysPresent = records.length;
    let totalHoursWorked = 0;
    records.forEach((rec) => {
      if (rec.checkInTime && rec.checkOutTime) {
        let workMs = rec.checkOutTime - rec.checkInTime - (rec.totalBreakDuration || 0);
        totalHoursWorked += workMs > 0 ? workMs / (1000 * 60 * 60) : 0;
      }
    });

    res.json({
      userId,
      totalDaysPresent,
      totalHoursWorked: Number(totalHoursWorked.toFixed(2)),
      startDate: startDate.toISOString().slice(0, 10),
      endDate: endDate.toISOString().slice(0, 10),
    });
  } catch (error) {
    console.error('Attendance summary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Attendance status endpoint
router.get('/status/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);

    // Find today's attendance for the user
    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
    });

    console.log('DEBUG: Attendance status response:', { status: attendance ? 'clocked_in' : 'not_clocked_in', attendance });

    if (!attendance) {
      console.log('No attendance record found for today. Creating a new record.');
      const newAttendance = new Attendance({
        user: userId,
        date: today,
        checkInTime: null,
        status: 'not_clocked_in',
      });
      await newAttendance.save();
      console.log('DEBUG: Attendance record created:', newAttendance);
      return res.json({ status: 'not_clocked_in', attendance: newAttendance });
    }
    if (attendance.checkOutTime) {
      return res.json({ status: 'clocked_out' });
    }
    return res.json({ status: 'clocked_in' });
  } catch (error) {
    console.error('Attendance status error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Debug route for testing clock-in functionality
router.post('/debug/clock-in/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);

    // Check if user has already clocked in today
    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
    });

    if (attendance) {
      return res.status(400).json({ message: 'Already clocked in for today.' });
    }

    // Simulate clock-in
    const newAttendance = new Attendance({
      user: userId,
      date: new Date(),
      checkInTime: new Date(),
    });
    await newAttendance.save();

    return res.json({ message: 'Clock-in successful', attendance: newAttendance });
  } catch (error) {
    console.error('Debug clock-in error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;