const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const adminAttendanceController = require("../controllers/admin-attendance-controller");

// Admin middleware to check if user is admin
const adminAuth = (req, res, next) => {
  if (req.user.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
};

// Admin: Start break for any employee
router.post(
  "/admin/start-break/:userId",
  auth,
  adminAuth,
  adminAttendanceController.adminStartBreak
);

// Admin: End break for any employee
router.post(
  "/admin/end-break/:userId",
  auth,
  adminAuth,
  adminAttendanceController.adminEndBreak
);

// General: Get available break types (for employees)
router.get("/break-types", auth, adminAttendanceController.getBreakTypes);

// Admin: Get current break status for an employee
router.get(
  "/admin/break-status/:userId",
  auth,
  adminAuth,
  adminAttendanceController.getAdminBreakStatus
);
// Get all break types
router.get("/admin/break-types", auth, adminAuth, async (req, res) => {
  try {
    const breakTypes = await BreakType.find({}).sort({ priority: 1 });
    res.status(200).json({ breakTypes });
  } catch (error) {
    console.error("Get break types error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// Create new break type
router.post("/admin/break-types", auth, adminAuth, async (req, res) => {
  try {
    const breakType = new BreakType(req.body);
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
router.put("/admin/break-types/:id", auth, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findByIdAndUpdate(
      req.params.id,
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
router.delete("/admin/break-types/:id", auth, adminAuth, async (req, res) => {
  try {
    const breakType = await BreakType.findByIdAndUpdate(
      req.params.id,
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

// Get break history with filters
router.get("/admin/break-history", auth, adminAuth, async (req, res) => {
  try {
    const {
      userId,
      breakType,
      startDate,
      endDate,
      page = 1,
      limit = 50,
    } = req.query;

    const filter = {};
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
        return att;
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

module.exports = router;
