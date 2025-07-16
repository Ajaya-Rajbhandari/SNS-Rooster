const Leave = require('../models/Leave');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');
const { sendNotificationToUser, sendNotificationToTopic } = require('../services/notificationService');
const FCMToken = require('../models/FCMToken');

// Apply for leave
exports.applyLeave = async (req, res) => {
  try {
    const { leaveType, startDate, endDate, reason } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    if (!userId) return res.status(400).json({ message: 'User ID is required.' });
    if (!leaveType || !startDate || !endDate) {
      return res.status(400).json({ message: 'Leave type, start date, and end date are required.' });
    }
    
    // Prevent overlapping leave requests
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    let overlappingLeave;
    if (userRole === 'admin') {
      // For admins, check overlapping leaves by user ID
      overlappingLeave = await Leave.findOne({
        user: userId,
        status: { $in: ['Pending', 'Approved'] },
        $or: [
          { startDate: { $lte: end }, endDate: { $gte: start } }
        ]
      });
    } else {
      // For employees, get employee ID and check overlapping leaves
      const employee = await Employee.findOne({ userId: userId });
      if (!employee) {
        return res.status(400).json({ message: 'Employee record not found.' });
      }
      overlappingLeave = await Leave.findOne({
        employee: employee._id,
        status: { $in: ['Pending', 'Approved'] },
        $or: [
          { startDate: { $lte: end }, endDate: { $gte: start } }
        ]
      });
    }
    
    if (overlappingLeave) {
      return res.status(400).json({ message: 'You already have a leave request that overlaps with these dates.' });
    }
    
    // Create leave request
    let leave;
    if (userRole === 'admin') {
      leave = new Leave({
        user: userId,
        leaveType,
        startDate,
        endDate,
        reason
      });
    } else {
      const employee = await Employee.findOne({ userId: userId });
      if (!employee) {
        return res.status(400).json({ message: 'Employee record not found.' });
      }
      leave = new Leave({
        employee: employee._id,
        leaveType,
        startDate,
        endDate,
        reason
      });
    }
    
    await leave.save();
    
    // Notify all admins (except the requesting admin)
    const User = require('../models/User');
    const adminUsers = await User.find({ 
      role: 'admin', 
      isActive: true,
      _id: { $ne: userId } // Exclude the requesting admin
    });
    
    let requesterName = '';
    if (userRole === 'admin') {
      const requestingUser = await User.findById(userId);
      requesterName = `${requestingUser?.firstName || ''} ${requestingUser?.lastName || ''}`.trim();
    } else {
      const employee = await Employee.findOne({ userId: userId });
      requesterName = `${employee?.firstName || ''} ${employee?.lastName || ''}`.trim();
    }
    
    for (const admin of adminUsers) {
      const adminNotification = new Notification({
        user: admin._id,
        title: 'New Leave Request Submitted',
        message: `${requesterName} (${userRole}) has submitted a leave request from ${start.toDateString()} to ${end.toDateString()}.`,
        type: 'leave',
        link: '/admin/leave_management',
        isRead: false,
      });
      await adminNotification.save();
    }
    
    // FCM: Notify all admins via topic
    try {
      await sendNotificationToTopic(
        'admins',
        'New Leave Request Submitted',
        `${requesterName} (${userRole}) has submitted a leave request from ${start.toDateString()} to ${end.toDateString()}.`,
        { type: 'leave', leaveId: leave._id.toString() }
      );
    } catch (fcmError) {
      console.log('FCM notification failed, but database notification was created:', fcmError.message);
    }
    
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
    const { includeAdmins = 'true' } = req.query;
    
    // Get all leaves with both employee and user population, sorted by latest appliedAt first
    let leaves = await Leave.find()
      .sort({ appliedAt: -1 })
      .populate('employee')
      .populate('user', 'firstName lastName email role');
    
    // If filtering for employees only, exclude admin leaves
    if (includeAdmins === 'false') {
      leaves = leaves.filter(leave => leave.employee && !leave.user);
    }
    
    const result = leaves.map(leave => {
      let employeeName = '';
      let department = '';
      let role = '';
      
      if (leave.employee) {
        // Employee leave
        employeeName = `${leave.employee?.firstName || ''} ${leave.employee?.lastName || ''}`.trim();
        department = leave.employee?.department || '';
        role = 'employee';
      } else if (leave.user) {
        // Admin leave
        employeeName = `${leave.user?.firstName || ''} ${leave.user?.lastName || ''}`.trim();
        department = 'Administration';
        role = 'admin';
      }
      
      return {
        _id: leave._id,
        employee: leave.employee?._id,
        user: leave.user?._id,
        employeeName: employeeName,
        department: department,
        role: role,
        leaveType: leave.leaveType,
        startDate: leave.startDate,
        endDate: leave.endDate,
        reason: leave.reason,
        status: leave.status,
        appliedAt: leave.appliedAt,
        approvedBy: leave.approvedBy,
        approvedAt: leave.approvedAt,
      };
    });
    res.json(result);
  } catch (err) {
    console.error('Error in getAllLeaveRequests:', err);
    res.status(500).json({ message: 'Error fetching leave requests' });
  }
};

exports.approveLeaveRequest = async (req, res) => {
  try {
    const approvingUserId = req.user.userId;
    const approvingUserRole = req.user.role;
    
    // Only admins can approve leave requests
    if (approvingUserRole !== 'admin') {
      return res.status(403).json({ message: 'Only admins can approve leave requests.' });
    }
    
    const leave = await Leave.findByIdAndUpdate(
      req.params.id,
      { 
        status: 'Approved',
        approvedBy: approvingUserId,
        approvedAt: new Date()
      },
      { new: true }
    ).populate('employee').populate('user', 'firstName lastName email role');
    
    if (!leave) {
      return res.status(404).json({ message: 'Leave request not found.' });
    }
    
    // Check if this is an admin leave request
    if (leave.user && leave.user.role === 'admin') {
      // Prevent admins from approving their own leave requests
      if (leave.user._id.toString() === approvingUserId) {
        return res.status(403).json({ message: 'You cannot approve your own leave request.' });
      }
    }
    
    // Determine the recipient for notification
    let recipientUserId;
    let recipientName = '';
    
    if (leave.employee) {
      // Employee leave
      const employee = await Employee.findById(leave.employee);
      recipientUserId = employee?.userId;
      recipientName = `${employee?.firstName || ''} ${employee?.lastName || ''}`.trim();
    } else if (leave.user) {
      // Admin leave
      recipientUserId = leave.user._id;
      recipientName = `${leave.user?.firstName || ''} ${leave.user?.lastName || ''}`.trim();
    }
    
    // Notify the leave requester
    if (recipientUserId) {
      const notification = new Notification({
        user: recipientUserId,
        title: 'Leave Request Approved',
        message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
        type: 'info',
        link: '/leave_request',
        isRead: false,
      });
      await notification.save();
      
      // FCM: Notify the user
      const tokenDoc = await FCMToken.findOne({ userId: recipientUserId });
      if (tokenDoc && tokenDoc.fcmToken) {
        await sendNotificationToUser(
          tokenDoc.fcmToken,
          'Leave Request Approved',
          `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
          { type: 'leave', leaveId: leave._id.toString(), status: 'Approved' }
        );
      }
    }
    
    res.json({
      message: 'Leave request approved.',
      leave: {
        _id: leave._id,
        employee: leave.employee?._id,
        user: leave.user?._id,
        employeeName: recipientName,
        department: leave.employee?.department || 'Administration',
        role: leave.user ? 'admin' : 'employee',
        leaveType: leave.leaveType,
        startDate: leave.startDate,
        endDate: leave.endDate,
        reason: leave.reason,
        status: leave.status,
        appliedAt: leave.appliedAt,
        approvedBy: leave.approvedBy,
        approvedAt: leave.approvedAt,
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
