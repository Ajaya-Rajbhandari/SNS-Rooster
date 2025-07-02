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

// GET /analytics/admin/leave-types-breakdown
// Returns count of each leave type across all employees (optionally filtered by date range)
exports.getLeaveTypesBreakdownAdmin = async (req, res) => {
  try {
    // Ensure admin user
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const { startDate, endDate } = req.query;
    const match = {};
    if (startDate && endDate) {
      match.startDate = { $gte: new Date(startDate) };
      match.endDate = { $lte: new Date(endDate) };
    }

    const breakdown = await Leave.aggregate([
      { $match: match },
      { $group: { _id: '$leaveType', count: { $sum: 1 } } },
    ]);

    const result = {};
    breakdown.forEach((item) => {
      result[item._id] = item.count;
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: 'Server error', details: err.message });
  }
};

// GET /analytics/admin/monthly-hours-trend
// Returns total work hours aggregated per month for the last 12 months
exports.getMonthlyHoursTrendAdmin = async (req, res) => {
  try {
    // Ensure admin
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    let { start, end } = req.query;
    let startDate, endDate;
    if (start && end) {
      startDate = new Date(start);
      endDate = new Date(end);
    } else {
      endDate = new Date();
      startDate = new Date(endDate.getFullYear(), endDate.getMonth() - 11, 1);
    }

    // Fetch attendance records in range
    const records = await Attendance.find({
      date: { $gte: startDate, $lte: endDate },
    }).lean();

    // Aggregate hours per month
    const monthMap = {}; // key: YYYY-MM
    records.forEach((r) => {
      if (r.checkInTime && r.checkOutTime) {
        const workedMs = new Date(r.checkOutTime) - new Date(r.checkInTime) - (r.totalBreakDuration || 0);
        const dt = new Date(r.date);
        const key = `${dt.getFullYear()}-${(dt.getMonth() + 1)
          .toString()
          .padStart(2, '0')}`; // e.g., 2024-07
        if (!monthMap[key]) monthMap[key] = 0;
        monthMap[key] += workedMs;
      }
    });

    // Convert to array and hours
    const trend = Object.keys(monthMap)
      .sort()
      .map((key) => ({
        month: key,
        hours: +(monthMap[key] / (1000 * 60 * 60)).toFixed(1),
      }));

    console.log('DEBUG: payroll trend raw length', trend.length);
    const formatted = trend.map((t) => {
      const monthStr = `${t.month}`;
      return {
        month: monthStr,
        totalHours: t.hours,
      };
    });

    res.json({ trend: formatted });
  } catch (err) {
    console.error('Monthly hours trend error:', err);
    res.status(500).json({ message: 'Error computing monthly hours trend' });
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
    let { start, end, range } = req.query;
    let startDate, today;
    if (start && end) {
      startDate = new Date(start);
      today = new Date(end);
    } else {
      range = parseInt(range) || 7;
      today = new Date();
      today.setHours(0, 0, 0, 0);
      startDate = new Date(today);
      startDate.setDate(today.getDate() - range + 1);
    }

    // Get all employees
    const employees = await require('../models/User').find({ role: 'employee' });
    const employeeIds = employees.map(e => e._id);

    // Attendance breakdown for today
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    // ===== Attendance Counters =====
    let present = 0;
    let leave = 0;
    let absent = 0;

    try {
      console.time('presentAttendance');
      const presentAttendance = await Attendance.find({
        user: { $in: employeeIds },
        date: { $gte: todayStart, $lte: todayEnd },
        $or: [
          { status: { $in: ['present', 'completed'] } },
          { $and: [{ checkInTime: { $ne: null } }, { checkOutTime: { $ne: null } }] },
        ],
      }).distinct('user');
      console.timeEnd('presentAttendance');

      const presentSet = new Set(presentAttendance.map((id) => id.toString()));

      console.time('employeeDocs');
      const employeeDocs = await Employee.find({ userId: { $in: employeeIds } }, '_id userId');
      console.timeEnd('employeeDocs');

      const empIdMap = new Map();
      employeeDocs.forEach((e) => empIdMap.set(e._id.toString(), e.userId.toString()));

      console.time('leaveDocs');
      const leaveDocs = await Leave.find({
        employee: { $in: employeeDocs.map((e) => e._id) },
        startDate: { $lte: todayEnd },
        endDate: { $gte: todayStart },
        status: { $regex: /^approved$/i },
      }).distinct('employee');
      console.timeEnd('leaveDocs');

      const leaveSet = new Set(
        leaveDocs
          .map((id) => empIdMap.get(id.toString()))
          .filter(Boolean)
      );

      present = presentSet.size;
      leave = leaveSet.size;
      absent = employeeIds.length - present - leave;
    } catch (attErr) {
      console.error('Admin overview attendance calc error:', attErr);
      // Fallback to previous simple logic: everyone absent except presentSet if available
      present = 0;
      leave = 0;
      absent = employeeIds.length;
    }

    // Work hours trend (average per day for all employees)
    const workHoursByDay = {};
    const attendanceRecords = await Attendance.find({ user: { $in: employeeIds } }).sort({ date: -1 });
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

// GET /api/analytics/summary?start=YYYY-MM-DD&end=YYYY-MM-DD
// Returns basic KPIs for the given date range (defaults to current month)
exports.getSummary = async (req, res) => {
  try {
    const start = req.query.start ? new Date(req.query.start) : new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const end = req.query.end ? new Date(req.query.end) : new Date();

    // Total hours & overtime approximation (duration between checkIn/Out minus breaks)
    const records = await Attendance.find({
      date: { $gte: start, $lte: end }
    }).lean();

    let totalMs = 0;
    let overtimeMs = 0;

    records.forEach(r => {
      if (r.checkInTime && r.checkOutTime) {
        const worked = new Date(r.checkOutTime) - new Date(r.checkInTime) - (r.totalBreakDuration || 0);
        totalMs += worked;
        if (worked > 8 * 60 * 60 * 1000) {
          overtimeMs += worked - 8 * 60 * 60 * 1000;
        }
      }
    });

    const totalHours = +(totalMs / (1000 * 60 * 60)).toFixed(1);
    const overtimeHours = +(overtimeMs / (1000 * 60 * 60)).toFixed(1);

    // Absence rate
    const totalDays = records.length;
    const absentDays = records.filter(r => (r.status || '').toLowerCase() === 'absent').length;
    const absenceRate = totalDays ? +(absentDays / totalDays * 100).toFixed(1) : 0;

    // Average check-in time
    const checkIns = records
      .filter(r => r.checkInTime)
      .map(r => new Date(r.checkInTime));
    let avgCheckIn = null;
    if (checkIns.length) {
      const avgMs = checkIns.reduce((a, b) => a + b.getTime(), 0) / checkIns.length;
      avgCheckIn = new Date(avgMs);
    }

    res.json({
      summary: {
        totalHours,
        overtimeHours,
        absenceRate,
        avgCheckIn: avgCheckIn ? avgCheckIn.toISOString() : null,
      },
    });
  } catch (err) {
    console.error('Analytics summary error:', err);
    res.status(500).json({ message: 'Failed to compute analytics' });
  }
};

// === ADMIN PAYROLL ANALYTICS ===

// GET /analytics/admin/payroll-trend
// Returns total gross, net and deductions aggregated per month for the last N months (default 6)
exports.getPayrollTrendAdmin = async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const months = parseInt(req.query.months) || 6;
    const freq = (req.query.freq || 'monthly').toLowerCase();
    const endDate = new Date();
    const startDate = new Date(endDate.getFullYear(), endDate.getMonth() - months + 1, 1);

    let groupStage;
    if (freq === 'weekly') {
      groupStage = {
        _id: {
          year: { $year: '$issueDate' },
          week: { $isoWeek: '$issueDate' },
        },
      };
    } else if (freq === 'bi-weekly') {
      // group by bi-week index (every 2 ISO weeks)
      groupStage = {
        _id: {
          year: { $year: '$issueDate' },
          biweek: {
            $floor: {
              $divide: [{ $subtract: [{ $isoWeek: '$issueDate' }, 1] }, 2],
            },
          },
        },
      };
    } else if (freq === 'semi-monthly') {
      groupStage = {
        _id: {
          year: { $year: '$issueDate' },
          month: { $month: '$issueDate' },
          half: {
            $cond: [{ $lte: [{ $dayOfMonth: '$issueDate' }, 15] }, 1, 2],
          },
        },
      };
    } else {
      // monthly default
      groupStage = {
        _id: {
          year: { $year: '$issueDate' },
          month: { $month: '$issueDate' },
        },
      };
    }

    const trend = await Payroll.aggregate([
      {
        $match: {
          issueDate: { $gte: startDate, $lte: endDate },
        },
      },
      {
        $group: {
          ...groupStage,
          totalGross: { $sum: '$grossPay' },
          totalNet: { $sum: '$netPay' },
          totalDeductions: { $sum: '$deductions' },
        },
      },
      {
        $sort: { '_id.year': 1 },
      },
    ]);

    console.log('DEBUG: payroll trend raw length', trend.length);
    const formatted = trend.map((t) => {
      let label;
      if (freq === 'weekly') {
        label = `${t._id.year}-W${t._id.week}`;
      } else if (freq === 'bi-weekly') {
        label = `${t._id.year}-B${t._id.biweek + 1}`;
      } else if (freq === 'semi-monthly') {
        label = `${t._id.year}-${t._id.month.toString().padStart(2, '0')}-${t._id.half}`;
      } else {
        label = `${t._id.year}-${t._id.month.toString().padStart(2, '0')}`;
      }
      return {
        month: label,
        totalGross: t.totalGross,
        totalNet: t.totalNet,
        totalDeductions: t.totalDeductions,
      };
    });

    res.json({ trend: formatted });
  } catch (err) {
    console.error('Payroll trend admin error:', err);
    res.status(500).json({ message: 'Error fetching payroll trend', error: err.message });
  }
};

// GET /analytics/admin/payroll-deductions-breakdown
// Returns sum of deduction types for a given month (YYYY-MM). Defaults to current month.
exports.getPayrollDeductionsBreakdownAdmin = async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const monthParam = req.query.month; // format YYYY-MM
    let year, month;
    if (monthParam && /^\d{4}-\d{2}$/.test(monthParam)) {
      [year, month] = monthParam.split('-').map((v) => parseInt(v));
    } else {
      const now = new Date();
      year = now.getFullYear();
      month = now.getMonth() + 1; // 1-12
    }

    // Calculate date range for that month
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999); // last day of month

    const breakdown = await Payroll.aggregate([
      {
        $match: {
          issueDate: { $gte: startDate, $lte: endDate },
        },
      },
      { $unwind: '$deductionsList' },
      {
        $group: {
          _id: '$deductionsList.type',
          amount: { $sum: '$deductionsList.amount' },
        },
      },
    ]);

    const result = {};
    breakdown.forEach((b) => {
      result[b._id] = b.amount;
    });

    res.json({ breakdown: result });
  } catch (err) {
    console.error('Payroll deduction breakdown admin error:', err);
    res.status(500).json({ message: 'Error fetching deduction breakdown', error: err.message });
  }
}; 