// UTC DATE POLICY: All attendance and leave logic in this backend must use UTC for date storage, comparison, and queries. Never use local time for attendance/leave calculations. Always store and compare dates at UTC midnight. Display in local time on the frontend only.

/**
 * Returns a Date object set to UTC midnight for the given date (or today if not provided).
 * @param {Date} [date] - Optional date. Defaults to now.
 * @returns {Date} - Date at UTC midnight.
 */
function getUtcMidnight(date = new Date()) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0));
}

const Attendance = require("../models/Attendance");
const User = require("../models/User");
const BreakType = require("../models/BreakType");

exports.checkIn = async (req, res) => {
  // console.log("DEBUG: /check-in req.body:", req.body);
  // console.log("DEBUG: /check-in req.user:", req.user);
  // console.log("DEBUG: Authorization header:", req.header("Authorization"));
  // console.log("DEBUG: req.user at start of /check-in:", req.user);
  // console.log("DEBUG: req.user before accessing userId:", req.user);
  // console.log("DEBUG: Type of req.user:", typeof req.user);

  if (!req.user || typeof req.user !== "object") {
    console.error(
      "ERROR: req.user is undefined or not an object in /check-in route"
    );
    return res
      .status(500)
      .json({ message: "Authentication error: req.user is invalid" });
  }

  try {
    const userId = req.user.userId;
    if (!userId) {
      console.error("ERROR: userId is missing in req.user");
      return res.status(400).json({ message: "userId is required" });
    }

    // Always use UTC midnight for attendance date
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
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    console.log(
      "DEBUG: checkIn - Querying for userId:",
      userId,
      "and date range (UTC):",
      today,
      "-",
      tomorrow
    );

    const existingAttendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
    });

    console.log("DEBUG: checkIn - Existing attendance:", existingAttendance);

    if (existingAttendance) {
      return res.status(400).json({ message: "Already checked in for today." });
    }

    // Prevent check-in if user is on approved leave for today
    const Leave = require('../models/Leave');
    const leaveToday = await Leave.findOne({
      employee: userId,
      status: { $regex: /^approved$/i },
      startDate: { $lte: today },
      endDate: { $gte: today },
    });
    if (leaveToday) {
      return res.status(400).json({ message: 'You are on approved leave today and cannot check in.' });
    }

    const attendance = new Attendance({
      user: userId,
      date: today,
      checkInTime: new Date(),
    });

    await attendance.save();
    console.log("DEBUG: checkIn - Attendance created:", attendance);
    res.status(201).json({ message: "Check-in successful", attendance });
  } catch (error) {
    console.error("Check-in error:", error);
    if (error.code === 11000) {
      return res
        .status(400)
        .json({
          message:
            "A duplicate entry was detected. You might have already checked in.",
        });
    }
    res.status(500).json({ message: "Server error" });
  }
};

exports.checkOut = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Use UTC for date comparison to match checkIn logic
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
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    console.log(
      "DEBUG: checkOut - Querying for userId:",
      userId,
      "and date range (UTC):",
      today,
      "-",
      tomorrow
    );

    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
      checkOutTime: { $exists: false },
    });

    console.log("DEBUG: checkOut - Retrieved attendance object:", attendance);

    if (!attendance) {
      console.warn(
        "DEBUG: checkOut - No attendance found for userId:",
        userId,
        "in date range:",
        today,
        "-",
        tomorrow
      );
      return res
        .status(400)
        .json({ message: "Not checked in for today or already checked out." });
    }

    attendance.checkOutTime = new Date();
    await attendance.save();

    console.log(
      "DEBUG: checkOut - Successfully checked out for userId:",
      userId,
      "attendance:",
      attendance
    );

    res.json({ message: "Check-out successful", attendance });
  } catch (error) {
    console.error("Check-out error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.startBreak = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { breakTypeId } = req.body;
    if (!breakTypeId) {
      console.error(
        "startBreak error: breakTypeId is missing in request body",
        req.body
      );
      return res.status(400).json({ message: "breakTypeId is required" });
    }

    // ensure it's a valid type
    const typeObj = await BreakType.findById(breakTypeId);
    if (!typeObj) {
      console.error("startBreak error: Break type not found for id", breakTypeId);
      return res.status(404).json({ message: "Break type not found" });
    }

    // Use UTC midnight for today, matching check-in logic
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
      checkOutTime: { $exists: false },
    });
    if (!attendance) {
      console.error(
        "startBreak error: Cannot start break, not checked in",
        { userId, today }
      );
      return res
        .status(400)
        .json({ message: "Cannot start break: not checked in." });
    }
    const last = attendance.breaks.slice(-1)[0];
    if (last && !last.end) {
      console.error("startBreak error: Already on break", last);
      return res.status(400).json({ message: "Already on break." });
    }

    attendance.breaks.push({
      type: breakTypeId,
      start: new Date(),
    });

    console.log("DEBUG: Attendance object before save in startBreak:", attendance);
    await attendance.save();
    console.log("DEBUG: Attendance object after save in startBreak:", attendance);
    // Populate the breaks so the client gets the type details if they want:
    await attendance.populate("breaks.type", "displayName icon color");
    res.status(200).json({ message: "Break started", attendance });
  } catch (error) {
    console.error("Start break error:", error, req.body);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

exports.endBreak = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Use UTC for date comparison to match DB storage and avoid timezone issues
    const now = new Date();
    const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    // Find attendance for today (UTC)
    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
      checkInTime: { $exists: true },
      checkOutTime: { $exists: false },
    });

    if (!attendance) {
      return res.status(400).json({
        message: "Cannot end break: User not checked in or already checked out.",
      });
    }

    const lastBreak =
      attendance.breaks.length > 0
        ? attendance.breaks[attendance.breaks.length - 1]
        : null;

    if (!lastBreak || lastBreak.end) {
      return res.status(400).json({ message: "Not currently on break." });
    }

    // End the break and calculate duration
    lastBreak.end = new Date();
    lastBreak.duration = lastBreak.end.getTime() - lastBreak.start.getTime();
    attendance.markModified("breaks"); // Ensure subdocument is saved
    attendance.totalBreakDuration = attendance.breaks.reduce(
      (sum, b) => sum + (b.duration || 0),
      0
    );
    attendance.status = "clocked_in";
    await attendance.save();

    res.status(200).json({ message: "Break ended successfully", attendance });
  } catch (error) {
    console.error("End break error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getAttendanceStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Use UTC for date comparison to avoid timezone issues
    const now = new Date();
    const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    console.log(
      "DEBUG: getAttendanceStatus - Querying for userId:",
      userId,
      "and date (today UTC):",
      today,
      "to",
      tomorrow
    );

    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
    });

    console.log(
      "DEBUG: getAttendanceStatus - Retrieved attendance object:",
      attendance
    );
    console.log("DEBUG: getAttendanceStatus - Found attendance:", attendance);

    let status = "not_clocked_in";
    if (attendance) {
      if (attendance.checkOutTime) {
        status = "clocked_out";
      } else if (attendance.checkInTime) {
        const lastBreak =
          attendance.breaks.length > 0
            ? attendance.breaks[attendance.breaks.length - 1]
            : null;
        if (lastBreak && !lastBreak.end) {
          status = "on_break";
        } else {
          status = "clocked_in";
        }
      }
    }
    console.log(
      "DEBUG: getAttendanceStatus - Final status before sending:",
      status
    );
    res.status(200).json({ status, attendance });
  } catch (error) {
    console.error("Get attendance status error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getMyAttendance = async (req, res) => {
  try {
    const userId = req.user.userId;
    const attendanceRecords = await Attendance.find({ user: userId }).populate(
      "user",
      "firstName lastName email role"
    );

    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error("Get my attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Get attendance records for a specific user (Admin/Manager only, or self)
exports.getUserAttendance = async (req, res) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.userId;

    // Allow users to access their own data, or admin/manager to access any data
    if (
      req.user.role !== "admin" &&
      req.user.role !== "manager" &&
      requestingUserId !== userId
    ) {
      return res
        .status(403)
        .json({ message: "Unauthorized to view this attendance data" });
    }

    const attendanceRecords = await Attendance.find({ user: userId })
      .populate("user", "firstName lastName email role")
      .sort({ date: -1 }); // Sort by date, newest first

    // Calculate status for each attendance record
    const recordsWithStatus = attendanceRecords.map(record => {
      let status = "absent";
      
      if (record.checkInTime) {
        if (record.checkOutTime) {
          // Check if they were late (after 9:00 AM)
          const checkInTime = new Date(record.checkInTime);
          const checkInHour = checkInTime.getHours();
          const checkInMinute = checkInTime.getMinutes();
          const isLate = checkInHour > 9 || (checkInHour === 9 && checkInMinute > 0);
          
          status = isLate ? "late" : "present";
        } else {
          // Still clocked in or on break
          const lastBreak = record.breaks.length > 0 
            ? record.breaks[record.breaks.length - 1] 
            : null;
          if (lastBreak && !lastBreak.end) {
            status = "on break";
          } else {
            status = "working";
          }
        }
      }

      // Convert to plain object and add status
      const recordObj = record.toObject();
      recordObj.status = status;
      return recordObj;
    });

    res.json(recordsWithStatus);
  } catch (error) {
    console.error("Get user attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getBreakTypes = async (req, res) => {
  try {
    const types = await BreakType.find({ isActive: true }).sort("displayName");
    res.json(types);
  } catch (err) {
    console.error("Error fetching break types", err);
    res.status(500).json({ message: "Server error" });
  }
};

// AGGREGATE: Get today's attendance stats for all employees
exports.getTodayAttendanceStats = async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Unauthorized" });
    }

    // Get all active users (employees and admins)
    const users = await User.find({ isActive: true, role: { $in: ['employee', 'admin'] } });
    // Separate pending users (never logged in)
    const pendingUsers = users.filter(u => !u.lastLogin);
    const activeConfirmedUsers = users.filter(u => u.lastLogin); // Only those who have logged in
    const userIds = activeConfirmedUsers.map(u => u._id);
    // Get all Employee docs for those users
    const EmployeeModel = require('../models/Employee');
    const employees = await EmployeeModel.find({ userId: { $in: userIds } });
    const employeeIds = employees.map(e => e._id.toString());

    // Get today's date at UTC midnight
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0, 0, 0, 0
      )
    );
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    // Find all attendance records for today
    const attendanceToday = await Attendance.find({
      user: { $in: userIds },
      date: { $gte: today, $lt: tomorrow },
    });
    const presentIds = attendanceToday.map((a) => String(a.user));
    const present = presentIds.length;

    // In getTodayAttendanceStats, update leave count logic
    let onLeave = 0;
    let leaveIds = new Set();
    try {
      const Leave = require("../models/Leave");
      const leaveToday = await Leave.find({
        employee: { $in: employeeIds },
        status: { $regex: /^approved$/i },
        startDate: { $lte: today },
        endDate: { $gte: today },
      });
      leaveIds = new Set(leaveToday.map(lr => lr.employee.toString()));
      onLeave = leaveIds.size;
    } catch (e) {
      onLeave = 0;
    }

    // Absent = total confirmed users - present - onLeave
    const absentUsers = activeConfirmedUsers.filter(u => !presentIds.includes(u._id.toString()) && !leaveIds.has(employees.find(e => e.userId.toString() === u._id.toString())?._id.toString()));
    const absent = absentUsers.length;
    const pending = pendingUsers.length;

    res.json({ present, absent, onLeave, pending });
  } catch (error) {
    console.error("getTodayAttendanceStats error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/attendance/today-list?status=present|absent|onleave|pending
exports.getTodayEmployeeList = async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }
    const status = (req.query.status || '').toLowerCase();
    if (!['present', 'absent', 'onleave', 'pending'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status parameter' });
    }
    // Get all active users (employees and admins)
    const User = require('../models/User');
    const users = await User.find({ isActive: true, role: { $in: ['employee', 'admin'] } });
    // Separate pending users (never logged in)
    const pendingUsers = users.filter(u => !u.lastLogin);
    const activeConfirmedUsers = users.filter(u => u.lastLogin);
    const userIds = activeConfirmedUsers.map(u => u._id);

    // Get all Employee docs for those users
    const EmployeeModel = require('../models/Employee');
    const employees = await EmployeeModel.find({ userId: { $in: userIds } });
    const employeeIds = employees.map(e => e._id.toString());

    // Get today's date at UTC midnight
    const now = new Date();
    const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    // Attendance records for today
    const Attendance = require('../models/Attendance');
    const attendanceToday = await Attendance.find({
      user: { $in: userIds },
      date: { $gte: today, $lt: tomorrow },
    });
    const presentIds = new Set(attendanceToday.map(a => a.user.toString()));

    // Leave requests for today (approved only, case-insensitive)
    const Leave = require('../models/Leave');
    const leaveToday = await Leave.find({
      employee: { $in: employeeIds },
      status: { $regex: /^approved$/i },
      startDate: { $lte: today },
      endDate: { $gte: today },
    });
    const leaveIds = new Set(leaveToday.map(lr => lr.employee.toString()));

    let filteredEmployees;
    if (status === 'present') {
      filteredEmployees = activeConfirmedUsers.filter(u => presentIds.has(u._id.toString()) && !leaveIds.has(employees.find(e => e.userId.toString() === u._id.toString())?._id.toString()));
    } else if (status === 'onleave') {
      filteredEmployees = activeConfirmedUsers.filter(u => leaveIds.has(employees.find(e => e.userId.toString() === u._id.toString())?._id.toString()));
    } else if (status === 'absent') {
      filteredEmployees = activeConfirmedUsers.filter(u => !presentIds.has(u._id.toString()) && !leaveIds.has(employees.find(e => e.userId.toString() === u._id.toString())?._id.toString()));
    } else if (status === 'pending') {
      filteredEmployees = pendingUsers;
    }
    // Return basic info
    const result = filteredEmployees.map(u => ({
      _id: u._id,
      firstName: u.firstName,
      lastName: u.lastName,
      email: u.email,
      role: u.role,
    }));
    res.json({ employees: result });
  } catch (error) {
    console.error('getTodayEmployeeList error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
