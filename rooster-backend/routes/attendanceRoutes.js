const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const attendanceController = require("../controllers/attendance-controller");
const BreakType = require("../models/BreakType");
const Attendance = require('../models/Attendance');
const analyticsController = require('../controllers/analytics-controller');

// Check-in (User can check-in once per day)
router.post("/check-in", authenticateToken, attendanceController.checkIn);

// Check-out
router.patch("/check-out", authenticateToken, attendanceController.checkOut);

// Start break
router.post("/start-break", authenticateToken, attendanceController.startBreak);

// End break
router.patch("/end-break", authenticateToken, attendanceController.endBreak);

// Get current user's own attendance data
router.get("/my-attendance", authenticateToken, attendanceController.getMyAttendance);

// Get current user's timesheet entries
router.get("/timesheet", authenticateToken, attendanceController.getMyTimesheet);

// Get attendance for a specific user (Admin/Manager only, or self)
router.get("/user/:userId", authenticateToken, attendanceController.getUserAttendance);

// Get all attendance records (Admin only, with optional date range and employee filter)
router.get("/", authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Unauthorized to view all attendance data" });
    }
    const { start, end, employeeId } = req.query;
    let filter = {};
    if (start || end) {
      filter.date = {};
      if (start) filter.date.$gte = new Date(start);
      if (end) {
        const endDate = new Date(end);
        endDate.setHours(23, 59, 59, 999);
        filter.date.$lte = endDate;
      }
    }
    if (employeeId) filter.user = employeeId;
    const attendanceRecords = await Attendance.find(filter)
      .populate("user", "firstName lastName email role userId")
      .populate("breaks.type", "displayName");
    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error("Get all attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Edit/correct an attendance record (Admin only)
router.put("/:attendanceId", authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { attendanceId } = req.params;
    const update = req.body;
    const updated = await Attendance.findByIdAndUpdate(attendanceId, { $set: update }, { new: true });
    if (!updated) return res.status(404).json({ message: "Attendance not found" });
    res.json(updated);
  } catch (error) {
    console.error("Edit attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Export attendance records as CSV (Admin only)
router.get("/export", authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { start, end, employeeId } = req.query;
    let filter = {};
    if (start || end) {
      filter.date = {};
      if (start) filter.date.$gte = new Date(start);
      if (end) {
        const endDate = new Date(end);
        endDate.setHours(23, 59, 59, 999);
        filter.date.$lte = endDate;
      }
    }
    if (employeeId) filter.user = employeeId;
    const records = await Attendance.find(filter)
      .populate("user", "firstName lastName email role")
      .populate("breaks.type", "displayName");
    // Build CSV
    let csv = "Employee,Date,CheckIn,CheckOut,TotalBreak(ms)\n";
    records.forEach(r => {
      csv += `"${r.user.name}","${r.date.toISOString().slice(0,10)}","${r.checkInTime || ""}","${r.checkOutTime || ""}","${r.totalBreakDuration || 0}"\n`;
    });
    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", "attachment; filename=attendance.csv");
    res.send(csv);
  } catch (error) {
    console.error("Export attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Get available break types (for employees)
router.get('/break-types', authenticateToken, attendanceController.getBreakTypes);

// Attendance summary for a user within a date range
router.get("/summary/:userId", authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { start, end } = req.query;

    // Allow users to access their own data, or admin/manager to access any data
    if (
      req.user.role !== "admin" &&
      req.user.role !== "manager" &&
      req.user.userId !== userId
    ) {
      return res
        .status(403)
        .json({ message: "Unauthorized to view this attendance summary" });
    }

    // Parse date range as UTC
    let startDate = start ? new Date(Date.UTC(new Date(start).getUTCFullYear(), new Date(start).getUTCMonth(), new Date(start).getUTCDate(), 0, 0, 0, 0)) : new Date("1970-01-01T00:00:00.000Z");
    let endDate;
    if (end) {
      const endObj = new Date(end);
      endDate = new Date(Date.UTC(endObj.getUTCFullYear(), endObj.getUTCMonth(), endObj.getUTCDate(), 23, 59, 59, 999));
    } else {
      const now = new Date();
      endDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 23, 59, 59, 999));
    }

    // Find attendance records for user in range
    const records = await Attendance.find({
      user: userId,
      date: { $gte: startDate, $lte: endDate },
      status: "present",
    });

    // Calculate summary
    let totalDaysPresent = records.length;
    let totalHoursWorked = 0;
    records.forEach((rec) => {
      if (rec.checkInTime && rec.checkOutTime) {
        let workMs =
          rec.checkOutTime - rec.checkInTime - (rec.totalBreakDuration || 0);
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
    console.error("Attendance summary error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/status/:userId", authenticateToken, attendanceController.getAttendanceStatus);

// Get current user's attendance status (simplified endpoint)
router.get("/status", authenticateToken, (req, res) => {
  req.params.userId = req.user.userId;
  attendanceController.getAttendanceStatus(req, res);
});

// Debug route for testing clock-in functionality
router.post("/debug/clock-in/:userId", authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    // Use UTC midnight for today
    const now = new Date();
    const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);

    // Check if user has already clocked in today
    const attendance = await Attendance.findOne({
      user: userId,
      date: { $gte: today, $lt: tomorrow },
    });

    if (attendance) {
      return res.status(400).json({ message: "Already clocked in for today." });
    }

    // Simulate clock-in
    const newAttendance = new Attendance({
      user: userId,
      date: today,
      checkInTime: new Date(),
    });
    await newAttendance.save();

    return res.json({
      message: "Clock-in successful",
      attendance: newAttendance,
    });
  } catch (error) {
    console.error("Debug clock-in error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Aggregate attendance stats for today (admin only)
router.get("/today", authenticateToken, attendanceController.getTodayAttendanceStats);

// Add leave types breakdown analytics endpoint
// If you have an auth middleware, add it as needed (e.g., authMiddleware)
router.get('/analytics/leave-types-breakdown', analyticsController.getLeaveTypesBreakdown);

// Add analytics endpoints for employee dashboard
router.get('/analytics/late-checkins/:userId', analyticsController.getLateCheckins);
router.get('/analytics/avg-checkout/:userId', analyticsController.getAverageCheckoutTime);
router.get('/analytics/recent-activity/:userId', analyticsController.getRecentActivity);

// GET /attendance/today-list?status=present|absent|onleave
router.get('/today-list', authenticateToken, attendanceController.getTodayEmployeeList);

// Timesheet approval routes (admin only)
router.put('/:attendanceId/approve', authenticateToken, attendanceController.approveTimesheet);
router.put('/:attendanceId/reject', authenticateToken, attendanceController.rejectTimesheet);
router.get('/pending', authenticateToken, attendanceController.getPendingTimesheets);

module.exports = router;
