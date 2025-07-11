const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const { resolveCompanyContext, requireCompanyContext } = require('../middleware/companyContext');
const attendanceController = require("../controllers/attendance-controller");
const BreakType = require("../models/BreakType");
const Attendance = require('../models/Attendance');
const analyticsController = require('../controllers/analytics-controller');

// Check-in (User can check-in once per day)
router.post("/check-in", auth, resolveCompanyContext, requireCompanyContext, attendanceController.checkIn);

// Check-out
router.patch("/check-out", auth, resolveCompanyContext, requireCompanyContext, attendanceController.checkOut);

// Start break
router.post("/start-break", auth, resolveCompanyContext, requireCompanyContext, attendanceController.startBreak);

// End break
router.patch("/end-break", auth, resolveCompanyContext, requireCompanyContext, attendanceController.endBreak);

// Get current user's own attendance data
router.get("/my-attendance", auth, resolveCompanyContext, requireCompanyContext, attendanceController.getMyAttendance);

// Get attendance for a specific user (Admin/Manager only, or self)
router.get("/user/:userId", auth, resolveCompanyContext, requireCompanyContext, attendanceController.getUserAttendance);

// Get all attendance records (Admin only, with optional date range and employee filter)
router.get("/", auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Unauthorized to view all attendance data" });
    }
    const { start, end, employeeId } = req.query;
    let filter = { companyId: req.company._id };
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
      .populate("user", "firstName lastName email role")
      .populate("breaks.type", "displayName");
    res.json({ attendance: attendanceRecords });
  } catch (error) {
    console.error("Get all attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Edit/correct an attendance record (Admin only)
router.put("/:attendanceId", auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { attendanceId } = req.params;
    const update = req.body;
    // Only allow update if attendance belongs to the current company
    const updated = await Attendance.findOneAndUpdate(
      { _id: attendanceId, companyId: req.company._id },
      { $set: update },
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "Attendance not found" });
    res.json(updated);
  } catch (error) {
    console.error("Edit attendance error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Export attendance records as CSV (Admin only)
router.get("/export", auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { start, end, employeeId } = req.query;
    let filter = { companyId: req.company._id };
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
router.get('/break-types', auth, resolveCompanyContext, requireCompanyContext, attendanceController.getBreakTypes);

// Attendance summary for a user within a date range
router.get("/summary/:userId", auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
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

    // Parse date range
    let startDate = start ? new Date(start) : new Date("1970-01-01");
    let endDate = end ? new Date(end) : new Date();
    endDate.setHours(23, 59, 59, 999); // Include the whole end day

    // Find attendance records for user in range
    const records = await Attendance.find({
      user: userId,
      date: { $gte: startDate, $lte: endDate },
      status: "present",
      companyId: req.company._id
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

router.get("/status/:userId", auth, resolveCompanyContext, requireCompanyContext, attendanceController.getAttendanceStatus);

// Debug route for testing clock-in functionality
router.post("/debug/clock-in/:userId", auth, resolveCompanyContext, requireCompanyContext, async (req, res) => {
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
      companyId: req.company._id
    });

    if (attendance) {
      return res.status(400).json({ message: "Already clocked in for today." });
    }

    // Simulate clock-in
    const newAttendance = new Attendance({
      user: userId,
      date: new Date(),
      checkInTime: new Date(),
      companyId: req.company._id
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
router.get("/today", auth, resolveCompanyContext, requireCompanyContext, attendanceController.getTodayAttendanceStats);

// Add leave types breakdown analytics endpoint
// If you have an auth middleware, add it as needed (e.g., authMiddleware)
router.get('/analytics/leave-types-breakdown', analyticsController.getLeaveTypesBreakdown);

// Add analytics endpoints for employee dashboard
router.get('/analytics/late-checkins/:userId', analyticsController.getLateCheckins);
router.get('/analytics/avg-checkout/:userId', analyticsController.getAverageCheckoutTime);
router.get('/analytics/recent-activity/:userId', analyticsController.getRecentActivity);

module.exports = router;
