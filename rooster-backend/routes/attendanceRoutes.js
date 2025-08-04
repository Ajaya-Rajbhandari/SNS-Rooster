const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const { validateCompanyContext, validateUserCompanyAccess, requireFeature } = require("../middleware/companyContext");
const attendanceController = require("../controllers/attendance-controller");
const BreakType = require("../models/BreakType");
const Attendance = require('../models/Attendance');
const analyticsController = require('../controllers/analytics-controller');

// Simple endpoint for checking attendance status (bypasses company context)
router.get("/simple/status", authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple attendance status endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      console.log('DEBUG: No company ID found, returning error');
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling getAttendanceStatus with companyId:', req.companyId);
    console.log('DEBUG: User ID:', req.user.userId);
    
    const result = await attendanceController.getAttendanceStatus(req, res);
    console.log('DEBUG: getAttendanceStatus result completed');
  } catch (error) {
    console.error('DEBUG: Error in simple attendance status endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting attendance status',
      error: error.message
    });
  }
});

// Test notification endpoint (before auth middleware for easier testing)
router.post("/test-notification", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    console.log('DEBUG: Test notification endpoint hit for user:', userId);
    
    const FCMToken = require('../models/FCMToken');
    const { sendNotificationToUser } = require('../services/notificationService');
    
    const fcmDoc = await FCMToken.findOne({ userId });
    console.log('DEBUG: FCM token found:', fcmDoc ? 'Yes' : 'No');
    
    if (fcmDoc && fcmDoc.token) {
      console.log('DEBUG: Sending test notification to token:', fcmDoc.token.substring(0, 20) + '...');
      
      await sendNotificationToUser(
        fcmDoc.token,
        'Test Notification',
        'This is a test notification from the backend',
        { type: 'test', event: 'test_notification', time: new Date().toISOString() },
        userId
      );
      
      console.log('DEBUG: Test notification sent successfully');
      res.json({ success: true, message: 'Test notification sent' });
    } else {
      console.log('DEBUG: No FCM token found for user');
      res.status(404).json({ success: false, message: 'No FCM token found for user' });
    }
  } catch (error) {
    console.error('DEBUG: Error sending test notification:', error);
    res.status(500).json({ success: false, message: 'Error sending test notification', error: error.message });
  }
});

// Apply authentication first, then company context
router.use(authenticateToken);
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);

// Check-in (User can check-in once per day)
router.post("/check-in", attendanceController.checkIn);

// Check-out
router.patch("/check-out", attendanceController.checkOut);

// Start break
router.post("/start-break", attendanceController.startBreak);

// End break
router.patch("/end-break", attendanceController.endBreak);

// Get current user's own attendance data
router.get("/my-attendance", attendanceController.getMyAttendance);

// Get current user's timesheet entries
router.get("/timesheet", attendanceController.getMyTimesheet);

// Get attendance for a specific user (Admin/Manager only, or self)
router.get("/user/:userId", attendanceController.getUserAttendance);

// Get all attendance records (Admin only, with optional date range and employee filter)
router.get("/", async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Unauthorized to view all attendance data" });
    }
    const { start, end, employeeId } = req.query;
    let filter = { companyId: req.companyId };
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
router.put("/:attendanceId", async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { attendanceId } = req.params;
    const update = req.body;
    const updated = await Attendance.findOneAndUpdate(
      { _id: attendanceId, companyId: req.companyId }, 
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
router.get("/export", async (req, res) => {
  try {
    if (req.user.role !== "admin") {
      return res.status(403).json({ message: "Admin access required" });
    }
    const { start, end, employeeId } = req.query;
    let filter = { companyId: req.companyId };
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

// Get available break types (for employees) - company-scoped
router.get('/break-types', async (req, res) => {
  try {
    const breakTypes = await BreakType.find({ companyId: req.companyId });
    res.json({ breakTypes });
  } catch (error) {
    console.error("Get break types error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Attendance summary for a user within a date range
router.get("/summary/:userId", async (req, res) => {
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

    // Find attendance records for user in range - company-scoped
    console.log('DEBUG: Attendance summary query params:', {
      userId,
      companyId: req.companyId,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      statusFilter: { $in: ["present", "completed", "approved"] }
    });
    
    const records = await Attendance.find({
      user: userId,
      companyId: req.companyId,
      date: { $gte: startDate, $lte: endDate },
      status: { $in: ["present", "completed", "approved"] },
    });
    
    console.log('DEBUG: Found attendance records:', records.length);
    if (records.length > 0) {
      console.log('DEBUG: Sample record:', {
        id: records[0]._id,
        date: records[0].date,
        status: records[0].status,
        checkInTime: records[0].checkInTime,
        checkOutTime: records[0].checkOutTime,
        totalBreakDuration: records[0].totalBreakDuration
      });
    }

    // Calculate summary
    let totalDaysPresent = records.length;
    let totalHoursWorked = 0;
    let totalBreakTime = 0;
    records.forEach((rec) => {
      if (rec.checkInTime && rec.checkOutTime) {
        let workMs =
          rec.checkOutTime - rec.checkInTime - (rec.totalBreakDuration || 0);
        totalHoursWorked += workMs > 0 ? workMs / (1000 * 60 * 60) : 0;
      }
      // Add break time
      totalBreakTime += (rec.totalBreakDuration || 0) / (1000 * 60 * 60);
    });

    // Calculate average hours per day
    const averageHoursPerDay = totalDaysPresent > 0 ? totalHoursWorked / totalDaysPresent : 0;
    
    console.log('DEBUG: Summary calculation results:', {
      totalDaysPresent,
      totalHoursWorked,
      totalBreakTime,
      averageHoursPerDay
    });

    res.json({
      userId,
      totalDaysPresent,
      totalHoursWorked: Number(totalHoursWorked.toFixed(2)),
      totalBreakTime: Number(totalBreakTime.toFixed(2)),
      averageHoursPerDay: Number(averageHoursPerDay.toFixed(2)),
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

    // Check if user has already clocked in today - company-scoped
    const attendance = await Attendance.findOne({
      user: userId,
      companyId: req.companyId,
      date: { $gte: today, $lt: tomorrow },
    });

    if (attendance) {
      return res.status(400).json({ message: "Already clocked in for today." });
    }

    // Simulate clock-in
    const newAttendance = new Attendance({
      user: userId,
      companyId: req.companyId,
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

// Add leave types breakdown analytics endpoint - requires analytics feature
router.get('/analytics/leave-types-breakdown', requireFeature('analytics'), analyticsController.getLeaveTypesBreakdown);

// Add analytics endpoints for employee dashboard - requires analytics feature
router.get('/analytics/late-checkins/:userId', requireFeature('analytics'), analyticsController.getLateCheckins);
router.get('/analytics/avg-checkout/:userId', requireFeature('analytics'), analyticsController.getAverageCheckoutTime);
router.get('/analytics/recent-activity/:userId', requireFeature('analytics'), analyticsController.getRecentActivity);

// GET /attendance/today-list?status=present|absent|onleave
router.get('/today-list', authenticateToken, attendanceController.getTodayEmployeeList);

// Timesheet approval routes (admin only)
router.put('/:attendanceId/approve', authenticateToken, attendanceController.approveTimesheet);
router.put('/:attendanceId/reject', authenticateToken, attendanceController.rejectTimesheet);
router.get('/pending', authenticateToken, attendanceController.getPendingTimesheets);

module.exports = router;
