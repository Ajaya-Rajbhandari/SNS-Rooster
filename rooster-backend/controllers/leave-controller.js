const Leave = require('../models/Leave');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');
const { sendNotificationToUser, sendNotificationToTopic } = require('../services/notificationService');
const FCMToken = require('../models/FCMToken');

// Apply for leave
exports.applyLeave = async (req, res) => {
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const employeeId = req.user && req.user.id ? req.user.id : req.body.employeeId;
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required.' });
    if (!leaveType || !startDate || !endDate) {
      return res.status(400).json({ message: 'Leave type, start date, and end date are required.' });
    }
    // Prevent overlapping leave requests
    const start = new Date(startDate);
    const end = new Date(endDate);
    const overlappingLeave = await Leave.findOne({
      employee: employeeId,
      status: { $in: ['Pending', 'Approved'] },
      $or: [
        { startDate: { $lte: end }, endDate: { $gte: start } }
      ]
    });
    if (overlappingLeave) {
      return res.status(400).json({ message: 'You already have a leave request that overlaps with these dates.' });
    }
    const leave = new Leave({
      employee: employeeId,
      leaveType,
      startDate,
      endDate,
      reason
    });
    await leave.save();
    // Notify all admins
    const employee = await Employee.findById(employeeId);
    // FCM: Notify all admins via topic
    await sendNotificationToTopic(
      'admins',
      'New Leave Request Submitted',
      `${employee?.firstName || 'An employee'} ${employee?.lastName || ''} has submitted a leave request from ${start.toDateString()} to ${end.toDateString()}.`,
      { type: 'leave', leaveId: leave._id.toString() }
    );
    res.status(201).json({ message: 'Leave application submitted successfully.', leave });
  } catch (error) {
    res.status(500).json({ message: 'Error applying for leave.', error: error.message });
  }
};

// (Optional) Get leave history for employee
exports.getLeaveHistory = async (req, res) => {
  try {
    const employeeId = req.query.employeeId || (req.user && req.user.id);
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required.' });
    const leaves = await Leave.find({ employee: employeeId }).populate('employee').sort({ appliedAt: -1 });
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
    }));
    res.json(result);
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

exports.approveLeaveRequest = async (req, res) => {
  try {
    const leave = await Leave.findByIdAndUpdate(
      req.params.id,
      { status: 'Approved' },
      { new: true }
    ).populate('employee');
    if (!leave) {
      return res.status(404).json({ message: 'Leave request not found.' });
    }
    // Notify the employee
    const employeeNotification = new Notification({
      user: leave.employee?._id,
      title: 'Leave Request Approved',
      message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
      type: 'info',
      link: '/leave_request',
      isRead: false,
    });
    await employeeNotification.save();
    // FCM: Notify the employee
    const tokenDoc = await FCMToken.findOne({ userId: leave.employee?._id });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        'Leave Request Approved',
        `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
        { type: 'leave', leaveId: leave._id.toString(), status: 'Approved' }
      );
    }
    res.json({
      message: 'Leave request approved.',
      leave: {
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
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Error approving leave request.' });
  }
};

exports.rejectLeaveRequest = async (req, res) => {
  try {
    const leave = await Leave.findByIdAndUpdate(
      req.params.id,
      { status: 'Rejected' },
      { new: true }
    ).populate('employee');
    if (!leave) {
      return res.status(404).json({ message: 'Leave request not found.' });
    }
    // Notify the employee
    const employeeNotification = new Notification({
      user: leave.employee?._id,
      title: 'Leave Request Rejected',
      message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been rejected.`,
      type: 'alert',
      link: '/leave_request',
      isRead: false,
    });
    await employeeNotification.save();
    // FCM: Notify the employee
    const tokenDoc = await FCMToken.findOne({ userId: leave.employee?._id });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        'Leave Request Rejected',
        `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been rejected.`,
        { type: 'leave', leaveId: leave._id.toString(), status: 'Rejected' }
      );
    }
    res.json({
      message: 'Leave request rejected.',
      leave: {
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
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Error rejecting leave request.' });
  }
};
