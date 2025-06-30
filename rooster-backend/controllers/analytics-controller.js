const Attendance = require('../models/Attendance');
const Employee = require('../models/Employee');

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