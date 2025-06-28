const Attendance = require("../models/Attendance");
const User = require("../models/User");
const BreakType = require("../models/BreakType");

exports.checkIn = async (req, res) => {
  console.log("DEBUG: /check-in req.body:", req.body);
  console.log("DEBUG: /check-in req.user:", req.user);
  console.log("DEBUG: Authorization header:", req.header("Authorization"));
  console.log("DEBUG: req.user at start of /check-in:", req.user);
  console.log("DEBUG: req.user before accessing userId:", req.user);
  console.log("DEBUG: Type of req.user:", typeof req.user);

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
    
    // Use UTC for date comparison to match other methods
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

    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
      checkInTime: { $exists: true },
      checkOutTime: { $exists: false },
    });

    if (!attendance) {
      return res.status(400).json({
        message:
          "Cannot end break: User not checked in or already checked out.",
      });
    }

    const lastBreak =
      attendance.breaks.length > 0
        ? attendance.breaks[attendance.breaks.length - 1]
        : null;

    if (!lastBreak || lastBreak.end) {
      return res.status(400).json({ message: "Not currently on break." });
    }

    console.log("DEBUG: Last break before ending:", lastBreak);
    lastBreak.end = new Date();
    lastBreak.duration = lastBreak.end.getTime() - lastBreak.start.getTime();
    console.log("DEBUG: Last break after setting end:", lastBreak);
    attendance.markModified("breaks"); // Ensure subdocument is saved
    attendance.totalBreakDuration = attendance.breaks.reduce(
      (sum, b) => sum + (b.duration || 0),
      0
    );
    console.log("DEBUG: Attendance status before update:", attendance.status);
    attendance.status = "clocked_in";
    console.log("DEBUG: Attendance status after update:", attendance.status);
    await attendance.save();
    console.log("DEBUG: Attendance after save:", attendance);

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

    res.json(attendanceRecords);
  } catch (error) {
    console.error("Get user attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

exports.getBreakTypes = async (req, res) => {
  try {
    const types = await BreakType.find().sort("displayName");
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

    // Get all employees
    const employees = await User.find({ role: "employee" });
    const employeeIds = employees.map((u) => u._id);
    const totalEmployees = employeeIds.length;

    // Get today's date at UTC midnight
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

    // Find all attendance records for today
    const attendanceToday = await Attendance.find({
      user: { $in: employeeIds },
      date: { $gte: today, $lt: tomorrow },
    });
    const presentIds = attendanceToday.map((a) => String(a.user));
    const present = presentIds.length;

    // Find all leave requests for today (approved only)
    // (Assumes you have a LeaveRequest model with user, startDate, endDate, status)
    let onLeave = 0;
    try {
      const LeaveRequest = require("../models/LeaveRequest");
      const leaveToday = await LeaveRequest.find({
        user: { $in: employeeIds },
        status: "approved",
        startDate: { $lte: today },
        endDate: { $gte: today },
      });
      // Only count unique users on leave
      const leaveIds = new Set(leaveToday.map((lr) => String(lr.user)));
      onLeave = leaveIds.size;
    } catch (e) {
      // If LeaveRequest model missing, just skip
      onLeave = 0;
    }

    // Absent = total - present - onLeave
    const absent = Math.max(totalEmployees - present - onLeave, 0);

    res.json({ present, absent, onLeave });
  } catch (error) {
    console.error("getTodayAttendanceStats error:", error);
    res.status(500).json({ message: "Server error" });
  }
};
