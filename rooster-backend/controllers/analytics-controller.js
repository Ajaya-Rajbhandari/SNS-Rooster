const Attendance = require('../models/Attendance');
const Employee = require('../models/Employee');
const Leave = require('../models/Leave');
const Payroll = require('../models/Payroll');
const Notification = require('../models/Notification');

// GET /analytics/attendance/:userId
exports.getAttendanceAnalytics = async (req, res) => {
  try {
    const userId = req.params.userId;
    const range = parseInt(req.query.range) || 7;
    const attendanceRecords = await Attendance.find({ user: userId }).sort({ date: 1 });
    const lastN = attendanceRecords.slice(-range);
    let present = 0, absent = 0, leave = 0;
    lastN.forEach(record => {
      let status = (record.status || '').toLowerCase();
      // If status is missing, infer from checkIn/checkOut
      if (!status && record.checkInTime && record.checkOutTime) {
        status = 'present';
      }
      if (status === 'present' || status === 'completed') present++;
      else if (status === 'absent') absent++;
      else if (status === 'leave') leave++;
    });
    res.json({ attendance: { Present: present, Absent: absent, Leave: leave } });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching attendance analytics', error: err.message });
  }
};

// GET /analytics/work-hours/:userId
exports.getWorkHoursAnalytics = async (req, res) => {
  try {
    const userId = req.params.userId;
    const range = parseInt(req.query.range) || 7;
    const attendanceRecords = await Attendance.find({ user: userId }).sort({ date: -1 }).limit(range);
    // Return work hours for the last N days (or available days)
    const workHours = attendanceRecords.map(record => {
      if (record.checkInTime && record.checkOutTime) {
        const start = new Date(record.checkInTime);
        const end = new Date(record.checkOutTime);
        const hours = Math.max(0, (end - start) / (1000 * 60 * 60));
        return parseFloat(hours.toFixed(2));
      }
      return 0.0;
    }).reverse(); // Oldest first
    res.json({ workHours });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching work hours analytics', error: err.message });
  }
};

// GET /analytics/summary/:userId
exports.getAnalyticsSummary = async (req, res) => {
  try {
    const userId = req.params.userId;
    const range = parseInt(req.query.range) || 7;
    const attendanceRecords = await Attendance.find({ user: userId }).sort({ date: 1 }); // oldest first
    const lastN = attendanceRecords.slice(-range);
    // Longest Present Streak (in all records)
    let longestStreak = 0, currentStreak = 0;
    attendanceRecords.forEach(record => {
      let status = (record.status || '').toLowerCase();
      if (!status && record.checkInTime && record.checkOutTime) {
        status = 'present';
      }
      if (status === 'present' || status === 'completed') {
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    });
    // Most Productive Day (max work hours in last N days)
    let maxHours = 0;
    let mostProductiveDay = null;
    lastN.forEach(record => {
      if (record.checkInTime && record.checkOutTime) {
        const start = new Date(record.checkInTime);
        const end = new Date(record.checkOutTime);
        const hours = (end - start) / (1000 * 60 * 60);
        if (hours > maxHours) {
          maxHours = hours;
          mostProductiveDay = record.date ? record.date.toISOString().slice(0,10) : null;
        }
      }
    });
    // Average Check-in Time (last N days)
    let totalMinutes = 0, count = 0;
    lastN.forEach(record => {
      if (record.checkInTime) {
        const checkIn = new Date(record.checkInTime);
        totalMinutes += checkIn.getHours() * 60 + checkIn.getMinutes();
        count++;
      }
    });
    let avgCheckIn = null;
    if (count > 0) {
      const avgMinutes = Math.round(totalMinutes / count);
      const hours = Math.floor(avgMinutes / 60);
      const minutes = avgMinutes % 60;
      avgCheckIn = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    }
    res.json({
      longestStreak,
      mostProductiveDay,
      avgCheckIn
    });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching analytics summary', error: err.message });
  }
};

// GET /analytics/leave-types-breakdown
exports.getLeaveTypesBreakdown = async (req, res) => {
  try {
    // If using authentication middleware, get user from req.user; fallback to query param for demo
    const userId = req.user ? req.user.id : req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID required' });
    }
    // Optional: filter by date range
    const { startDate, endDate } = req.query;
    const match = { user: userId };
    if (startDate && endDate) {
      match.startDate = { $gte: new Date(startDate) };
      match.endDate = { $lte: new Date(endDate) };
    }
    const breakdown = await Leave.aggregate([
      { $match: match },
      { $group: { _id: '$leaveType', count: { $sum: 1 } } }
    ]);
    const result = {};
    breakdown.forEach(item => {
      result[item._id] = item.count;
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Server error', details: err.message });
  }
};

// GET /analytics/late-checkins/:userId
exports.getLateCheckins = async (req, res) => {
  try {
    const userId = req.params.userId || (req.user && req.user.id);
    if (!userId) return res.status(400).json({ error: 'User ID required' });
    const range = parseInt(req.query.range) || 30; // default last 30 days
    const attendanceRecords = await Attendance.find({ user: userId }).sort({ date: -1 }).limit(range);
    const lateThresholdHour = 9, lateThresholdMinute = 15;
    let lateCount = 0;
    const lateDates = [];
    attendanceRecords.forEach(record => {
      if (record.checkInTime) {
        const checkIn = new Date(record.checkInTime);
        if (checkIn.getHours() > lateThresholdHour || (checkIn.getHours() === lateThresholdHour && checkIn.getMinutes() > lateThresholdMinute)) {
          lateCount++;
          lateDates.push(record.date ? record.date.toISOString().slice(0,10) : null);
        }
      }
    });
    res.json({ lateCount, lateDates });
  } catch (err) {
    res.status(500).json({ error: 'Error fetching late check-ins', details: err.message });
  }
};

// GET /analytics/avg-checkout/:userId
exports.getAverageCheckoutTime = async (req, res) => {
  try {
    const userId = req.params.userId || (req.user && req.user.id);
    if (!userId) return res.status(400).json({ error: 'User ID required' });
    const range = parseInt(req.query.range) || 30;
    const attendanceRecords = await Attendance.find({ user: userId, checkOutTime: { $exists: true, $ne: null } }).sort({ date: -1 }).limit(range);
    let totalMinutes = 0, count = 0;
    attendanceRecords.forEach(record => {
      if (record.checkOutTime) {
        const checkOut = new Date(record.checkOutTime);
        totalMinutes += checkOut.getHours() * 60 + checkOut.getMinutes();
        count++;
      }
    });
    let avgCheckOut = null;
    if (count > 0) {
      const avgMinutes = Math.round(totalMinutes / count);
      const hours = Math.floor(avgMinutes / 60);
      const minutes = avgMinutes % 60;
      avgCheckOut = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    }
    res.json({ avgCheckOut });
  } catch (err) {
    res.status(500).json({ error: 'Error fetching average check-out time', details: err.message });
  }
};

// GET /analytics/recent-activity/:userId
exports.getRecentActivity = async (req, res) => {
  try {
    const userId = req.params.userId || (req.user && req.user.id);
    if (!userId) return res.status(400).json({ error: 'User ID required' });
    const limit = parseInt(req.query.limit) || 10;
    const records = await Attendance.find({ user: userId }).sort({ date: -1 }).limit(limit);
    res.json({ recentActivity: records });
  } catch (err) {
    res.status(500).json({ error: 'Error fetching recent activity', details: err.message });
  }
};

// GET /analytics/admin/overview
exports.getAdminOverview = async (req, res) => {
  console.log('DEBUG: /analytics/admin/overview endpoint hit');
  try {
    // Only allow admin
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    const range = parseInt(req.query.range) || 7;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const startDate = new Date(today);
    startDate.setDate(today.getDate() - range + 1);

    // Get all employees
    const employees = await require('../models/User').find({ role: 'employee' });
    const employeeIds = employees.map(e => e._id);

    // Attendance breakdown for the last N days
    const attendanceRecords = await Attendance.find({
      user: { $in: employeeIds },
      date: { $gte: startDate, $lte: today }
    });
    let present = 0, absent = 0, leave = 0;
    attendanceRecords.forEach(record => {
      let status = (record.status || '').toLowerCase();
      if (!status && record.checkInTime && record.checkOutTime) status = 'present';
      if (status === 'present' || status === 'completed') present++;
      else if (status === 'absent') absent++;
      else if (status === 'leave') leave++;
    });

    // Work hours trend (average per day for all employees)
    const workHoursByDay = {};
    attendanceRecords.forEach(record => {
      if (record.checkInTime && record.checkOutTime) {
        const dateStr = record.date.toISOString().slice(0, 10);
        const start = new Date(record.checkInTime);
        const end = new Date(record.checkOutTime);
        const hours = Math.max(0, (end - start) / (1000 * 60 * 60));
        if (!workHoursByDay[dateStr]) workHoursByDay[dateStr] = [];
        workHoursByDay[dateStr].push(hours);
      }
    });
    const workHoursTrend = Object.keys(workHoursByDay).sort().map(dateStr => {
      const hoursArr = workHoursByDay[dateStr];
      const avg = hoursArr.length ? (hoursArr.reduce((a, b) => a + b, 0) / hoursArr.length) : 0;
      return { date: dateStr, avgHours: parseFloat(avg.toFixed(2)) };
    });

    // Department stats
    const departmentStats = {};
    employees.forEach(emp => {
      const dept = emp.department || 'Unknown';
      if (!departmentStats[dept]) departmentStats[dept] = 0;
      departmentStats[dept]++;
    });

    // Recent activity (last 10 attendance records, newest first)
    const recentActivity = await Attendance.find({ user: { $in: employeeIds } })
      .sort({ date: -1 })
      .limit(10)
      .populate('user', 'firstName lastName email');

    // New: Count total payslips and notifications with error handling
    let payslipCount = 0;
    let notificationCount = 0;
    try {
      const Payroll = require('../models/Payroll');
      payslipCount = await Payroll.countDocuments();
    } catch (err) {
      console.error('Error counting payslips:', err);
      payslipCount = 0;
    }
    try {
      const Notification = require('../models/Notification');
      notificationCount = await Notification.countDocuments();
    } catch (err) {
      console.error('Error counting notifications:', err);
      notificationCount = 0;
    }

    // Calculate total employees from departmentStats
    const totalEmployees = Object.values(departmentStats).reduce((sum, count) => sum + count, 0);

    res.json({
      attendance: { Present: present, Absent: absent, Leave: leave },
      workHoursTrend,
      departmentStats,
      recentActivity,
      payslipCount,
      notificationCount,
      // Add quickStats for frontend compatibility
      quickStats: {
        totalEmployees: totalEmployees,
        presentToday: present,
        absentToday: absent,
        onLeave: leave,
        pendingRequests: 0 // TODO: implement pending requests count
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching admin overview analytics', error: err.message });
  }
}; 