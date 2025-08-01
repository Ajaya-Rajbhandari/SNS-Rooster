const Leave = require('../models/Leave');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');
const { sendNotificationToUser, sendNotificationToTopic } = require('../services/notificationService');
const FCMToken = require('../models/FCMToken');

// Helper function to check if user is currently clocked in
async function isUserClockedIn(userId, companyId) {
  try {
    const Attendance = require('../models/Attendance');
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

    const attendance = await Attendance.findOne({
      user: userId,
      companyId: companyId,
      date: { $gte: today, $lt: tomorrow },
    });

    if (!attendance) {
      return false;
    }

    // User is clocked in if they have checkInTime but no checkOutTime
    // and they're not currently on a break
    if (attendance.checkInTime && !attendance.checkOutTime) {
      const lastBreak = attendance.breaks.length > 0 
        ? attendance.breaks[attendance.breaks.length - 1] 
        : null;
      
      // If they're on a break, they're still considered "clocked in"
      if (lastBreak && !lastBreak.end) {
        return true; // On break but still clocked in
      }
      
      return true; // Clocked in and not on break
    }

    return false;
  } catch (error) {
    console.error('Error checking clock-in status:', error);
    return false;
  }
}

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

    // ===== Validate half-day leave request =====
    if (req.body.isHalfDay) {
      const isClockedIn = await isUserClockedIn(userId, req.companyId);
      if (!isClockedIn) {
        return res.status(400).json({ 
          message: 'You must be clocked in to request a half-day leave. Please clock in first and then apply for half-day leave.' 
        });
      }
    }

    // ===== Validate against company leave policy =====
    const LeavePolicy = require('../models/LeavePolicy');
    const { validateLeaveAgainstPolicy } = require('../utils/leave-policy-validator');

    const policy = await LeavePolicy.findOne({ companyId: req.companyId, isActive: true, isDefault: true });
    const policyError = validateLeaveAgainstPolicy(policy, new Date(startDate), new Date(endDate), req.body.isHalfDay);
    if (policyError) {
      return res.status(400).json({ message: policyError });
    }
    
    // Prevent overlapping leave requests
    // Parse dates and set to start/end of day to avoid timezone issues
    // Extract just the date part (YYYY-MM-DD) to avoid timezone conversion
    const startDateStr = startDate.split('T')[0]; // Get just the date part
    const endDateStr = endDate.split('T')[0]; // Get just the date part
    
    const start = new Date(startDateStr + 'T00:00:00');
    const end = new Date(endDateStr + 'T23:59:59');
    
    console.log('DEBUG: Checking for overlapping leaves');
    console.log('DEBUG: New request - Start:', start.toISOString(), 'End:', end.toISOString());
    console.log('DEBUG: Original dates - Start:', startDate, 'End:', endDate);
    console.log('DEBUG: Date conversion details:');
    console.log('  Raw startDate:', startDate, 'Type:', typeof startDate);
    console.log('  Raw endDate:', endDate, 'Type:', typeof endDate);
    console.log('  Extracted startDateStr:', startDateStr);
    console.log('  Extracted endDateStr:', endDateStr);
    console.log('  Parsed start:', start, 'Local:', start.toLocaleDateString());
    console.log('  Parsed end:', end, 'Local:', end.toLocaleDateString());
    console.log('DEBUG: User ID:', userId, 'Role:', userRole, 'Company ID:', req.companyId);
    
    let overlappingLeave;
    if (userRole === 'admin') {
      // For admins, check overlapping leaves by user ID
      overlappingLeave = await Leave.findOne({
        user: userId,
        companyId: req.companyId,
        status: { $in: ['Pending', 'Approved'] },
        $or: [
          { startDate: { $lte: end }, endDate: { $gte: start } }
        ]
      });
    } else {
      // For employees, get employee ID and check overlapping leaves
      const employee = await Employee.findOne({ userId: userId, companyId: req.companyId });
      if (!employee) {
        return res.status(400).json({ message: 'Employee record not found.' });
      }
      console.log('DEBUG: Employee found:', employee._id);
      
      // First, let's see all existing leaves for this employee
      const allLeaves = await Leave.find({
        employee: employee._id,
        companyId: req.companyId
      }).sort({ startDate: 1 });
      
      console.log('DEBUG: All existing leaves for employee:', allLeaves.map(l => ({
        id: l._id,
        startDate: l.startDate,
        endDate: l.endDate,
        status: l.status,
        leaveType: l.leaveType
      })));
      
      // Use a more precise overlap detection that handles time components
      overlappingLeave = await Leave.findOne({
        employee: employee._id,
        companyId: req.companyId,
        status: { $in: ['Pending', 'Approved'] },
        $and: [
          { startDate: { $lt: end } },  // Existing start is before new end
          { endDate: { $gt: start } }   // Existing end is after new start
        ]
      });
    }
    
    if (overlappingLeave) {
      console.log('DEBUG: Overlapping leave found:', {
        id: overlappingLeave._id,
        startDate: overlappingLeave.startDate,
        endDate: overlappingLeave.endDate,
        status: overlappingLeave.status
      });
      
      // Debug the actual comparison
      console.log('DEBUG: Date comparison details:');
      console.log('  New request start:', start.toISOString());
      console.log('  New request end:', end.toISOString());
      console.log('  Existing start:', overlappingLeave.startDate.toISOString());
      console.log('  Existing end:', overlappingLeave.endDate.toISOString());
      console.log('  Is existing start < new end?', overlappingLeave.startDate < end);
      console.log('  Is existing end > new start?', overlappingLeave.endDate > start);
    } else {
      console.log('DEBUG: No overlapping leaves found');
    }
    
    if (overlappingLeave) {
      console.log('DEBUG: REJECTING - Overlapping leave detected');
      return res.status(400).json({ message: 'You already have a leave request that overlaps with these dates.' });
    } else {
      console.log('DEBUG: ACCEPTING - No overlapping leaves found');
    }
    
    // Create leave request
    let leave;
    if (userRole === 'admin') {
      leave = new Leave({
        user: userId,
        companyId: req.companyId,
        leaveType,
        startDate: new Date(startDateStr + 'T00:00:00'),
        endDate: new Date(endDateStr + 'T23:59:59'),
        reason,
        isHalfDay: req.body.isHalfDay || false
      });
    } else {
      const employee = await Employee.findOne({ userId: userId, companyId: req.companyId });
      if (!employee) {
        return res.status(400).json({ message: 'Employee record not found.' });
      }
      leave = new Leave({
        employee: employee._id,
        companyId: req.companyId,
        leaveType,
        startDate: new Date(startDateStr + 'T00:00:00'),
        endDate: new Date(endDateStr + 'T23:59:59'),
        reason,
        isHalfDay: req.body.isHalfDay || false
      });
    }
    
    console.log('DEBUG: Saving leave request...');
    console.log('DEBUG: Leave object before save:', {
      startDate: leave.startDate,
      endDate: leave.endDate,
      leaveType: leave.leaveType,
      reason: leave.reason
    });
    await leave.save();
    console.log('DEBUG: Leave request saved successfully:', leave._id);
    console.log('DEBUG: Leave object after save:', {
      startDate: leave.startDate,
      endDate: leave.endDate,
      leaveType: leave.leaveType,
      reason: leave.reason
    });
    
    // Notify all admins (except the requesting admin)
    const User = require('../models/User');
    console.log('DEBUG: Looking for admin users in company:', req.companyId);
    console.log('DEBUG: Current user ID:', userId);
    console.log('DEBUG: Current user role:', userRole);
    
    const adminUsers = await User.find({ 
      role: 'admin', 
      isActive: true,
      companyId: req.companyId,
      _id: { $ne: userId } // Exclude the requesting admin
    });
    
    console.log('DEBUG: Found admin users:', adminUsers.length);
    console.log('DEBUG: Admin users:', adminUsers.map(u => ({ id: u._id, name: `${u.firstName} ${u.lastName}`, email: u.email })));
    
    let requesterName = '';
    try {
      if (userRole === 'admin') {
        const requestingUser = await User.findOne({ _id: userId, companyId: req.companyId });
        requesterName = `${requestingUser?.firstName || ''} ${requestingUser?.lastName || ''}`.trim();
      } else {
        const employee = await Employee.findOne({ userId: userId, companyId: req.companyId });
        requesterName = `${employee?.firstName || ''} ${employee?.lastName || ''}`.trim();
      }
      console.log('DEBUG: Requester name:', requesterName);
    } catch (nameError) {
      console.error('DEBUG: Error getting requester name:', nameError);
      requesterName = 'Employee';
    }
    
    console.log('DEBUG: Creating notifications for admins...');
    try {
      for (const admin of adminUsers) {
        console.log('DEBUG: Creating notification for admin:', admin._id);
        const adminNotification = new Notification({
          user: admin._id,
          company: req.companyId, // Use 'company' instead of 'companyId'
          title: 'New Leave Request Submitted',
          message: `${requesterName} (${userRole}) has submitted a leave request from ${start.toDateString()} to ${end.toDateString()}.`,
          type: 'leave',
          link: '/admin/leave_management',
          isRead: false,
        });
        await adminNotification.save();
        console.log('DEBUG: Notification saved for admin:', admin._id);
      }
    } catch (notificationError) {
      console.error('DEBUG: Error creating notifications:', notificationError);
      // Don't fail the entire request if notifications fail
    }
    
    // FCM: Notify all admins via topic
    try {
      console.log('DEBUG: Sending FCM notification...');
      
      // Check if Firebase is available
      const admin = require('firebase-admin');
      if (!admin.apps.length) {
        console.log('DEBUG: FCM - Firebase not initialized, skipping push notification');
      } else {
        console.log('DEBUG: FCM - Firebase is initialized, proceeding with notification');
        await sendNotificationToTopic(
          'admins',
          'New Leave Request Submitted',
          `${requesterName} (${userRole}) has submitted a leave request from ${start.toDateString()} to ${end.toDateString()}.`,
          { type: 'leave', screen: 'leave_management', leaveId: leave._id.toString(), companyId: req.companyId }
        );
        console.log('DEBUG: FCM notification sent successfully');
      }
    } catch (fcmError) {
      console.log('FCM notification failed, but database notification was created:', fcmError.message);
    }
    
    console.log('DEBUG: Sending success response...');
    res.status(201).json({ message: 'Leave application submitted successfully.', leave });
  } catch (error) {
    console.error('DEBUG: Error in applyLeave:', error);
    console.error('DEBUG: Error stack:', error.stack);
    res.status(500).json({ message: 'Error applying for leave.', error: error.message });
  }
};

// (Optional) Get leave history for employee
exports.getLeaveHistory = async (req, res) => {
  try {
    const employeeId = req.query.employeeId || (req.user && req.user.id);
    if (!employeeId) return res.status(400).json({ message: 'Employee ID is required.' });
    const leaves = await Leave.find({ employee: employeeId, companyId: req.companyId }).populate('employee').sort({ appliedAt: -1 });
    const result = leaves.map(leave => ({
      _id: leave._id,
      employee: leave.employee?._id,
      employeeName: `${leave.employee?.firstName || ''} ${leave.employee?.lastName || ''}`.trim(),
      department: leave.employee?.department || '',
      leaveType: leave.leaveType,
      startDate: leave.startDate,
      endDate: leave.endDate,
      reason: leave.reason,
      isHalfDay: leave.isHalfDay, // Add isHalfDay field
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
    const { includeAdmins = 'true', role = 'all' } = req.query;
    
    // Get all leaves with both employee and user population, sorted by latest appliedAt first
    let leaves = await Leave.find({ companyId: req.companyId })
      .sort({ appliedAt: -1 })
      .populate('employee')
      .populate('user', 'firstName lastName email role');
    
    // Apply role filtering
    if (role === 'employee' || includeAdmins === 'false') {
      // Show only employee leaves
      leaves = leaves.filter(leave => leave.employee && !leave.user);
    } else if (role === 'admin') {
      // Show only admin leaves
      leaves = leaves.filter(leave => leave.user && !leave.employee);
    }
    // If role === 'all' or includeAdmins === 'true', show both (no filtering)
    
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
        isHalfDay: leave.isHalfDay, // Add isHalfDay field
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
      console.log('FCM: DEBUG - Approving leave for user:', recipientUserId);
      console.log('FCM: DEBUG - Recipient name:', recipientName);
      
      const notification = new Notification({
        user: recipientUserId,
        title: 'Leave Request Approved',
        message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
        type: 'info',
        link: '/leave_request',
        isRead: false,
        company: req.companyId,
      });
      await notification.save();
      console.log('FCM: DEBUG - Database notification saved successfully');
      
      // FCM: Notify the user
      console.log('FCM: DEBUG - Looking for FCM token for user:', recipientUserId);
      const tokenDoc = await FCMToken.findOne({ userId: recipientUserId });
      console.log('FCM: DEBUG - FCM token found:', !!tokenDoc);
      console.log('FCM: DEBUG - Token document:', tokenDoc ? { userId: tokenDoc.userId, hasToken: !!tokenDoc.fcmToken } : 'null');
      
      if (tokenDoc && tokenDoc.fcmToken) {
        console.log('FCM: DEBUG - Sending approval notification to user:', recipientUserId);
        console.log('FCM: DEBUG - FCM token (first 20 chars):', tokenDoc.fcmToken.substring(0, 20) + '...');
        
        try {
          await sendNotificationToUser(
            tokenDoc.fcmToken,
            'Leave Request Approved',
            `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been approved.`,
            { type: 'leave', screen: 'leave_detail', leaveId: leave._id.toString(), status: 'Approved' }
          );
          console.log('FCM: DEBUG - Approval notification sent successfully');
        } catch (error) {
          console.error('FCM: DEBUG - Error sending approval notification:', error);
        }
      } else {
        console.log('FCM: DEBUG - No FCM token found for user:', recipientUserId);
        console.log('FCM: DEBUG - Available FCM tokens in database:');
        const allTokens = await FCMToken.find({});
        console.log('FCM: DEBUG - Total FCM tokens:', allTokens.length);
        allTokens.forEach(token => {
          console.log('FCM: DEBUG - Token for user:', token.userId, 'has token:', !!token.fcmToken);
        });
      }
    } else {
      console.log('FCM: DEBUG - No recipient user ID found for leave approval');
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
    
    // Get employee's user ID for notification
    let recipientUserId;
    let recipientName = '';
    
    if (leave.employee) {
      const employee = await Employee.findById(leave.employee);
      recipientUserId = employee?.userId;
      recipientName = `${employee?.firstName || ''} ${employee?.lastName || ''}`.trim();
    }
    
    // Notify the employee
    if (recipientUserId) {
      console.log('FCM: DEBUG - Rejecting leave for user:', recipientUserId);
      console.log('FCM: DEBUG - Recipient name:', recipientName);
      
      const employeeNotification = new Notification({
        user: recipientUserId,
        title: 'Leave Request Rejected',
        message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been rejected.`,
        type: 'alert',
        link: '/leave_request',
        isRead: false,
        company: req.companyId,
      });
      await employeeNotification.save();
      console.log('FCM: DEBUG - Database notification saved successfully');
      
      // FCM: Notify the employee
      console.log('FCM: DEBUG - Looking for FCM token for user:', recipientUserId);
      const tokenDoc = await FCMToken.findOne({ userId: recipientUserId });
      console.log('FCM: DEBUG - FCM token found:', !!tokenDoc);
      console.log('FCM: DEBUG - Token document:', tokenDoc ? { userId: tokenDoc.userId, hasToken: !!tokenDoc.fcmToken } : 'null');
      
      if (tokenDoc && tokenDoc.fcmToken) {
        console.log('FCM: DEBUG - Sending rejection notification to user:', recipientUserId);
        console.log('FCM: DEBUG - FCM token (first 20 chars):', tokenDoc.fcmToken.substring(0, 20) + '...');
        
        try {
          await sendNotificationToUser(
            tokenDoc.fcmToken,
            'Leave Request Rejected',
            `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been rejected.`,
            { type: 'leave', screen: 'leave_detail', leaveId: leave._id.toString(), status: 'Rejected' }
          );
          console.log('FCM: DEBUG - Rejection notification sent successfully');
        } catch (error) {
          console.error('FCM: DEBUG - Error sending rejection notification:', error);
        }
      } else {
        console.log('FCM: DEBUG - No FCM token found for user:', recipientUserId);
        console.log('FCM: DEBUG - Available FCM tokens in database:');
        const allTokens = await FCMToken.find({});
        console.log('FCM: DEBUG - Total FCM tokens:', allTokens.length);
        allTokens.forEach(token => {
          console.log('FCM: DEBUG - Token for user:', token.userId, 'has token:', !!token.fcmToken);
        });
      }
    } else {
      console.log('FCM: DEBUG - No recipient user ID found for leave rejection');
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

// ===== PHASE 2 ENHANCEMENTS =====

// Get leave policies for the company
exports.getLeavePolicies = async (req, res) => {
  try {
    // Default leave policies (can be customized per company)
    const policies = {
      annual: {
        name: 'Annual Leave',
        daysPerYear: 12,
        description: 'Paid annual leave for vacation and personal time',
        requiresApproval: true,
        maxConsecutiveDays: 30,
        advanceNotice: 7 // days
      },
      sick: {
        name: 'Sick Leave',
        daysPerYear: 10,
        description: 'Paid sick leave for medical reasons',
        requiresApproval: false,
        maxConsecutiveDays: 14,
        advanceNotice: 0
      },
      casual: {
        name: 'Casual Leave',
        daysPerYear: 5,
        description: 'Short-term leave for personal matters',
        requiresApproval: true,
        maxConsecutiveDays: 3,
        advanceNotice: 1
      },
      maternity: {
        name: 'Maternity Leave',
        daysPerYear: 90,
        description: 'Maternity leave for expecting mothers',
        requiresApproval: true,
        maxConsecutiveDays: 90,
        advanceNotice: 30
      },
      paternity: {
        name: 'Paternity Leave',
        daysPerYear: 10,
        description: 'Paternity leave for new fathers',
        requiresApproval: true,
        maxConsecutiveDays: 10,
        advanceNotice: 14
      },
      unpaid: {
        name: 'Unpaid Leave',
        daysPerYear: 0,
        description: 'Unpaid leave for extended absences',
        requiresApproval: true,
        maxConsecutiveDays: 60,
        advanceNotice: 14
      }
    };

    res.json(policies);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching leave policies.', error: error.message });
  }
};

// Get leave calendar data for a specific month
exports.getLeaveCalendar = async (req, res) => {
  try {
    const { year, month, employeeId } = req.query;
    
    if (!year || !month) {
      return res.status(400).json({ message: 'Year and month are required.' });
    }

    const startDate = new Date(parseInt(year), parseInt(month) - 1, 1);
    const endDate = new Date(parseInt(year), parseInt(month), 0);

    let query = {
      companyId: req.companyId,
      status: 'Approved',
      $or: [
        { startDate: { $lte: endDate, $gte: startDate } },
        { endDate: { $gte: startDate, $lte: endDate } },
        { startDate: { $lte: startDate }, endDate: { $gte: endDate } }
      ]
    };

    // Filter by employee if specified
    if (employeeId) {
      const employee = await Employee.findOne({ _id: employeeId, companyId: req.companyId });
      if (employee) {
        query.employee = employeeId;
      }
    }

    const leaves = await Leave.find(query)
      .populate('employee', 'firstName lastName department')
      .populate('user', 'firstName lastName');

    const calendarData = leaves.map(leave => {
      const person = leave.employee || leave.user;
      return {
        id: leave._id,
        title: `${person?.firstName || ''} ${person?.lastName || ''}`,
        start: leave.startDate,
        end: leave.endDate,
        leaveType: leave.leaveType,
        department: leave.employee?.department || 'Administration',
        role: leave.user ? 'admin' : 'employee',
        color: getLeaveTypeColor(leave.leaveType)
      };
    });

    res.json(calendarData);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching leave calendar.', error: error.message });
  }
};

// Bulk approve/reject leave requests
exports.bulkUpdateLeaveRequests = async (req, res) => {
  try {
    const { leaveIds, action, reason } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    if (userRole !== 'admin') {
      return res.status(403).json({ message: 'Only admins can perform bulk operations.' });
    }

    if (!leaveIds || !Array.isArray(leaveIds) || leaveIds.length === 0) {
      return res.status(400).json({ message: 'Leave IDs array is required.' });
    }

    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ message: 'Action must be either "approve" or "reject".' });
    }

    const updateData = {
      status: action === 'approve' ? 'Approved' : 'Rejected'
    };

    if (action === 'approve') {
      updateData.approvedBy = userId;
      updateData.approvedAt = new Date();
    }

    const result = await Leave.updateMany(
      { 
        _id: { $in: leaveIds },
        companyId: req.companyId,
        status: 'Pending'
      },
      updateData
    );

    // Send notifications for updated leaves
    const updatedLeaves = await Leave.find({ _id: { $in: leaveIds } })
      .populate('employee')
      .populate('user');

    for (const leave of updatedLeaves) {
      let recipientUserId;
      let recipientName = '';

      if (leave.employee) {
        const employee = await Employee.findById(leave.employee);
        recipientUserId = employee?.userId;
        recipientName = `${employee?.firstName || ''} ${employee?.lastName || ''}`.trim();
      } else if (leave.user) {
        recipientUserId = leave.user._id;
        recipientName = `${leave.user?.firstName || ''} ${leave.user?.lastName || ''}`.trim();
      }

      if (recipientUserId) {
        const notification = new Notification({
          user: recipientUserId,
          title: `Leave Request ${action === 'approve' ? 'Approved' : 'Rejected'}`,
          message: `Your leave request from ${leave.startDate.toDateString()} to ${leave.endDate.toDateString()} has been ${action === 'approve' ? 'approved' : 'rejected'}.`,
          type: action === 'approve' ? 'info' : 'alert',
          link: '/leave_request',
          isRead: false,
          company: req.companyId,
        });
        await notification.save();
      }
    }

    res.json({
      message: `Successfully ${action}d ${result.modifiedCount} leave requests.`,
      updatedCount: result.modifiedCount
    });
  } catch (error) {
    res.status(500).json({ message: 'Error performing bulk operation.', error: error.message });
  }
};

// Get leave statistics and analytics
exports.getLeaveStatistics = async (req, res) => {
  try {
    const { year, department } = req.query;
    const currentYear = year || new Date().getFullYear();

    let matchQuery = {
      companyId: req.companyId,
      appliedAt: {
        $gte: new Date(currentYear, 0, 1),
        $lt: new Date(currentYear + 1, 0, 1)
      }
    };

    if (department) {
      // Get employees in the specified department
      const employees = await Employee.find({ 
        companyId: req.companyId, 
        department: department 
      }).select('_id');
      const employeeIds = employees.map(emp => emp._id);
      matchQuery.$or = [
        { employee: { $in: employeeIds } },
        { user: { $exists: true } } // Include admin leaves
      ];
    }

    const leaves = await Leave.aggregate([
      { $match: matchQuery },
      {
        $lookup: {
          from: 'employees',
          localField: 'employee',
          foreignField: '_id',
          as: 'employeeData'
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: 'user',
          foreignField: '_id',
          as: 'userData'
        }
      },
      {
        $addFields: {
          department: {
            $cond: {
              if: { $gt: [{ $size: '$employeeData' }, 0] },
              then: { $arrayElemAt: ['$employeeData.department', 0] },
              else: 'Administration'
            }
          },
          duration: {
            $add: [
              1,
              {
                $divide: [
                  { $subtract: ['$endDate', '$startDate'] },
                  1000 * 60 * 60 * 24
                ]
              }
            ]
          }
        }
      },
      {
        $group: {
          _id: {
            leaveType: '$leaveType',
            status: '$status',
            department: '$department'
          },
          count: { $sum: 1 },
          totalDays: { $sum: '$duration' }
        }
      }
    ]);

    // Calculate summary statistics
    const summary = {
      totalRequests: 0,
      approvedRequests: 0,
      rejectedRequests: 0,
      pendingRequests: 0,
      totalDays: 0,
      byLeaveType: {},
      byDepartment: {},
      byStatus: {}
    };

    leaves.forEach(item => {
      const { leaveType, status, department } = item._id;
      
      summary.totalRequests += item.count;
      summary.totalDays += item.totalDays;

      // By status
      summary.byStatus[status] = (summary.byStatus[status] || 0) + item.count;

      // By leave type
      if (!summary.byLeaveType[leaveType]) {
        summary.byLeaveType[leaveType] = { count: 0, days: 0 };
      }
      summary.byLeaveType[leaveType].count += item.count;
      summary.byLeaveType[leaveType].days += item.totalDays;

      // By department
      if (!summary.byDepartment[department]) {
        summary.byDepartment[department] = { count: 0, days: 0 };
      }
      summary.byDepartment[department].count += item.count;
      summary.byDepartment[department].days += item.totalDays;
    });

    summary.approvedRequests = summary.byStatus['Approved'] || 0;
    summary.rejectedRequests = summary.byStatus['Rejected'] || 0;
    summary.pendingRequests = summary.byStatus['Pending'] || 0;

    res.json({
      year: currentYear,
      summary,
      details: leaves
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching leave statistics.', error: error.message });
  }
};

// Cancel leave request (for employees)
exports.cancelLeaveRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    const leave = await Leave.findById(id);
    if (!leave) {
      return res.status(404).json({ message: 'Leave request not found.' });
    }

    // Check if user owns this leave request
    let isOwner = false;
    if (userRole === 'admin' && leave.user && leave.user.toString() === userId) {
      isOwner = true;
    } else if (userRole === 'employee') {
      const employee = await Employee.findOne({ userId: userId, companyId: req.companyId });
      if (employee && leave.employee && leave.employee.toString() === employee._id.toString()) {
        isOwner = true;
      }
    }

    if (!isOwner) {
      return res.status(403).json({ message: 'You can only cancel your own leave requests.' });
    }

    // Only allow cancellation of pending requests
    if (leave.status !== 'Pending') {
      return res.status(400).json({ message: 'Only pending leave requests can be cancelled.' });
    }

    // Check policy if cancellation allowed
    const LeavePolicy = require('../models/LeavePolicy');
    const policy = await LeavePolicy.findOne({ companyId: req.companyId, isActive: true, isDefault: true });
    if (policy && policy.rules && policy.rules.allowCancellation === false) {
      return res.status(403).json({ message: 'Cancellation of leave requests is disabled by company policy.' });
    }

    // TESTING: 24-hour restriction disabled
    // // Check if leave starts within 24 hours
    // const now = new Date();
    // const leaveStart = new Date(leave.startDate);
    // const hoursUntilLeave = (leaveStart - now) / (1000 * 60 * 60);
    
    // if (hoursUntilLeave < 24) {
    //   return res.status(400).json({ message: 'Leave requests cannot be cancelled within 24 hours of start date.' });
    // }

    await Leave.findByIdAndDelete(id);

    // Notify admins about cancellation
    const User = require('../models/User');
    
    // Get the user details for the notification
    const currentUser = await User.findById(userId);
    const userName = currentUser ? `${currentUser.firstName || ''} ${currentUser.lastName || ''}`.trim() : 'Unknown User';
    
    const adminUsers = await User.find({ 
      role: 'admin', 
      isActive: true,
      companyId: req.companyId
    });

    for (const admin of adminUsers) {
      const notification = new Notification({
        user: admin._id,
        title: 'Leave Request Cancelled',
        message: `A leave request has been cancelled by ${userName}.`,
        type: 'info',
        link: '/admin/leave_management',
        isRead: false,
        company: req.companyId,
      });
      await notification.save();
    }

    res.json({ message: 'Leave request cancelled successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Error cancelling leave request.', error: error.message });
  }
};

// Helper function to get color for leave type
function getLeaveTypeColor(leaveType) {
  const colors = {
    'Annual Leave': '#4CAF50',
    'Sick Leave': '#F44336',
    'Casual Leave': '#FF9800',
    'Maternity Leave': '#E91E63',
    'Paternity Leave': '#2196F3',
    'Unpaid Leave': '#9E9E9E'
  };
  return colors[leaveType] || '#607D8B';
}
