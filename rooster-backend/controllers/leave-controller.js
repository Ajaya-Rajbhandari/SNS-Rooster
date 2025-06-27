const Leave = require('../models/Leave');
const Employee = require('../models/Employee');

// Apply for leave
exports.applyLeave = async (req, res) => {
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const employeeId = req.user && req.user.id ? req.user.id : req.body.employeeId;
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required.' });
    if (!leaveType || !startDate || !endDate) {
      return res.status(400).json({ message: 'Leave type, start date, and end date are required.' });
    }
    const leave = new Leave({
      employee: employeeId,
      leaveType,
      startDate,
      endDate,
      reason
    });
    await leave.save();
    res.status(201).json({ message: 'Leave application submitted successfully.', leave });
  } catch (error) {
    res.status(500).json({ message: 'Error applying for leave.', error: error.message });
  }
};

// (Optional) Get leave history for employee
exports.getLeaveHistory = async (req, res) => {
  try {
    // Always prefer query param if provided
    const employeeId = req.query.employeeId || (req.user && req.user.id);
    console.log('Leave history requested for employeeId:', employeeId);
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required.' });
    const leaves = await Leave.find({ employee: employeeId }).sort({ appliedAt: -1 });
    console.log('Found leaves:', leaves);
    res.json({ success: true, data: leaves });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching leave history.', error: error.message });
  }
};

// Get all leave requests for admin
exports.getAllLeaveRequests = async (req, res) => {
  try {
    const leaves = await Leave.find().populate('employee');
    const result = leaves.map(leave => ({
      _id: leave._id,
      employee: leave.employee?._id,
      employeeName: `${leave.employee?.firstName || ''} ${leave.employee?.lastName || ''}`.trim(),
      department: leave.employee?.department || '',
      leaveType: leave.leaveType,
      startDate: leave.startDate,
      endDate: leave.endDate,
      reason: leave.reason,
      status: leave.status,
      appliedAt: leave.appliedAt,
      // Add other fields as needed
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching leave requests' });
  }
};
