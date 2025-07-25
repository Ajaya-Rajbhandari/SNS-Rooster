const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const { validateCompanyContext, validateUserCompanyAccess } = require("../middleware/companyContext");
const adminAttendanceController = require("../controllers/admin-attendance-controller");
const { getAttendanceStatusForRecord } = require("../controllers/admin-attendance-controller");
const Attendance = require('../models/Attendance');
const BreakType = require('../models/BreakType');

// Admin middleware to check if user is admin
const adminAuth = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};

// Admin: Start break for any employee
router.post(
  "/start-break/:userId",
  authenticateToken,
  validateCompanyContext,
  validateUserCompanyAccess,
  adminAuth,
  adminAttendanceController.adminStartBreak
);

// Admin: End break for any employee
router.post(
  "/end-break/:userId",
  authenticateToken,
  validateCompanyContext,
  validateUserCompanyAccess,
  adminAuth,
  adminAttendanceController.adminEndBreak
);

// Admin: Get current break status for an employee
router.get(
  "/break-status/:userId",
  authenticateToken,
  validateCompanyContext,
  validateUserCompanyAccess,
  adminAuth,
  adminAttendanceController.getAdminBreakStatus
);

// Admin: Get all break types (including inactive ones for management)
router.get("/break-types", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const breakTypes = await BreakType.find({ companyId: req.companyId }).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error("Get break types error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Create new break type
router.post("/break-types", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const breakType = new BreakType({ ...req.body, companyId: req.companyId });
    await breakType.save();
    res
      .status(201)
      .json({ message: "Break type created successfully", breakType });
  } catch (error) {
    console.error("Create break type error:", error);
    if (error.code === 11000) {
      res.status(400).json({ message: "Break type name already exists" });
    } else {
      res.status(500).json({ message: "Server error" });
    }
  }
});

// Update break type
router.put("/break-types/:id", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findOneAndUpdate(
      { _id: req.params.id, companyId: req.companyId },
      req.body,
      { new: true, runValidators: true }
    );

    if (!breakType) {
      return res.status(404).json({ message: "Break type not found" });
    }

    res
      .status(200)
      .json({ message: "Break type updated successfully", breakType });
  } catch (error) {
    console.error("Update break type error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Delete break type (soft delete by setting isActive to false)
router.delete("/break-types/:id", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findOneAndUpdate(
      { _id: req.params.id, companyId: req.companyId },
      { isActive: false },
      { new: true }
    );

    if (!breakType) {
      return res.status(404).json({ message: "Break type not found" });
    }

    res.status(200).json({ message: "Break type deactivated successfully" });
  } catch (error) {
    console.error("Delete break type error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Patch: In the break history endpoint, set status for each record
router.get("/break-history", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const {
      userId,
      breakType,
      startDate,
      endDate,
      page = 1,
      limit = 50,
    } = req.query;

    const filter = { companyId: req.companyId };
    if (userId) filter.user = userId;
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    const attendance = await Attendance.find(filter)
      .populate("user", "firstName lastName email")
      .sort({ date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    // Filter breaks by type if specified
    const filteredAttendance = attendance
      .map((att) => {
        if (breakType) {
          att.breaks = att.breaks.filter((b) => b.type === breakType);
        }
        // Patch: Set status using utility
        const attObj = att.toObject();
        attObj.status = getAttendanceStatusForRecord(attObj);
        return attObj;
      })
      .filter((att) => att.breaks.length > 0);

    res.status(200).json({
      attendance: filteredAttendance,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  } catch (error) {
    console.error("Get break history error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

function getBreakStatusForRecord(att) {
  if (!att || !att.breaks || att.breaks.length === 0) return 'no_break';
  const lastBreak = att.breaks[att.breaks.length - 1];
  if (lastBreak && lastBreak.start && !lastBreak.end) return 'on_break';
  return 'break_ended';
}

// GET /attendance?userId=...&startDate=...&endDate=...&role=employee|admin|all
router.get("/attendance", authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminAuth, async (req, res) => {
  try {
    const { userId, startDate, endDate, page = 1, limit = 50, role = 'all' } = req.query;
    const filter = { companyId: req.companyId };
    if (userId) filter.user = userId;
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }
    console.log('ADMIN ATTENDANCE FILTER: userId:', userId, 'role:', role, 'filter:', filter);

    const attendance = await Attendance.find(filter)
      .populate("user", "firstName lastName email role userId")
      .sort({ date: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit));

    // Filter by role if specified
    let filteredAttendance = attendance;
    if (role === 'employee') {
      filteredAttendance = attendance.filter(a => a.user && a.user.role === 'employee');
    } else if (role === 'admin') {
      filteredAttendance = attendance.filter(a => a.user && a.user.role === 'admin');
    }

    const total = filteredAttendance.length;

    res.json({
      attendance: filteredAttendance,
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: 1,
    });
  } catch (error) {
    console.error("Error fetching admin attendance:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// Admin: Monitor ongoing breaks and send warnings
router.get(
  "/monitor-breaks",
  authenticateToken,
  adminAuth,
  adminAttendanceController.monitorOngoingBreaks
);

module.exports = router;
