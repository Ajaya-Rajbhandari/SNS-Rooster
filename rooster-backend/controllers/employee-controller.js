const mongoose = require('mongoose');
const Employee = require('../models/Employee');
const User = require('../models/User');
const Notification = require('../models/Notification');

exports.getAllEmployees = async (req, res) => {
  try {
    console.log('DEBUG: getAllEmployees called, user role:', req.user.role);
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can view all employees' });
    }
    const showInactive = req.query.showInactive === 'true';
    const filter = showInactive ? {} : { isActive: true };
    console.log('DEBUG: Employee filter:', filter);
    const employees = await Employee.find(filter);
    console.log('DEBUG: Found employees count:', employees.length);
    // On-demand: Notify admins of incomplete profiles
    for (const emp of employees) {
      if (!emp.phone || !emp.address || !emp.emergencyContact) {
        // Only send one admin notification per day
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const existingAdminNotif = await Notification.findOne({
          role: 'admin',
          title: 'Incomplete Employee Profile',
          message: `${emp.firstName} ${emp.lastName} has not completed their profile.`,
          createdAt: { $gte: today }
        });
        if (!existingAdminNotif) {
          const adminNotification = new Notification({
            role: 'admin',
            title: 'Incomplete Employee Profile',
            message: `${emp.firstName} ${emp.lastName} has not completed their profile.`,
            type: 'alert',
            link: `/admin/employee_management`,
            isRead: false,
          });
          await adminNotification.save();
        }
        // Only send one employee notification per day
        const existingEmpNotif = await Notification.findOne({
          user: emp.userId,
          title: 'Incomplete Profile',
          createdAt: { $gte: today }
        });
        if (!existingEmpNotif) {
          const employeeNotification = new Notification({
            user: emp.userId,
            title: 'Incomplete Profile',
            message: 'Your profile is incomplete. Please update your information.',
            type: 'alert',
            link: '/profile',
            isRead: false,
          });
          await employeeNotification.save();
        }
      }
    }
    res.status(200).json(employees);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getEmployeeById = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== req.params.id) {
      return res.status(403).json({ message: 'Unauthorized to view this employee data' });
    }
    
    const employee = await Employee.findById(req.params.id);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    res.status(200).json(employee);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can create new employees' });
    }
    
    const employee = new Employee({
      userId: req.body.userId,
      firstName: req.body.firstName,
      lastName: req.body.lastName,
      email: req.body.email,
      employeeId: req.body.employeeId,
      hireDate: req.body.hireDate,
      position: req.body.position,
      department: req.body.department,
    });

    const newEmployee = await employee.save();
    res.status(201).json(newEmployee);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.updateEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== req.params.id) {
      return res.status(403).json({ message: 'Unauthorized to update this employee data' });
    }
    
    const employee = await Employee.findById(req.params.id);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }

    employee.firstName = req.body.firstName || employee.firstName;
    employee.lastName = req.body.lastName || employee.lastName;
    employee.email = req.body.email || employee.email;
    employee.employeeId = req.body.employeeId || employee.employeeId;
    employee.hireDate = req.body.hireDate || employee.hireDate;
    employee.position = req.body.position || employee.position;
    employee.department = req.body.department || employee.department;

    const updatedEmployee = await employee.save();
    res.status(200).json(updatedEmployee);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can delete employees' });
    }
    
    const employee = await Employee.findByIdAndDelete(req.params.id);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    res.status(200).json({ message: 'Employee deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getEmployeeDashboard = async (req, res) => {
  try {
    console.log('DASHBOARD ROUTE: Returning mock data directly');
    const mockData = {
      tasks: ['Task 1', 'Task 2'],
      notifications: ['Notification 1'],
      stats: {
        completedTasks: 10,
        pendingTasks: 5,
      },
    };
    res.status(200).json({ dashboardData: mockData });
  } catch (error) {
    console.error('DASHBOARD ROUTE: Error processing request:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getEmployeeByUserId = async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log('Fetching employee with userId:', userId);

    const employee = await Employee.findOne({ userId });

    if (!employee) {
      console.error(`No employee found for userId: ${userId}`);
      return res.status(404).json({ message: 'Employee record not found' });
    }

    const employeeObj = employee.toObject();
    employeeObj.userId = employeeObj.userId?.toString();

    res.status(200).json({ data: employeeObj });
  } catch (error) {
    console.error('Error fetching employee by userId:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.getLeaveBalance = async (req, res) => {
  try {
    const employeeId = req.params.id;
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(employeeId)) {
      return res.status(400).json({ message: 'Invalid employee ID.' });
    }
    const empId = new mongoose.Types.ObjectId(employeeId);
    console.log('Querying leave balance for employeeId:', empId);

    // Define your leave types and their annual entitlements
    const leaveTypes = {
      annual: 12,
      sick: 10,
      casual: 5,
      maternity: 90,
      paternity: 10,
      unpaid: 0
    };

    // Fetch all approved leaves for this employee (case-insensitive status)
    const Leave = require('../models/Leave');
    const leaves = await Leave.find({
      employee: empId,
      status: { $regex: /^approved$/i }
    });

    console.log('Approved leaves for balance:', leaves);

    // Calculate used days for each type (robust matching)
    const used = { annual: 0, sick: 0, casual: 0, maternity: 0, paternity: 0, unpaid: 0 };
    leaves.forEach(leave => {
      const type = (leave.leaveType || '').toLowerCase().replace(/\s/g, '');
      const days = Math.max(1, Math.ceil((new Date(leave.endDate) - new Date(leave.startDate)) / (1000 * 60 * 60 * 24)) + 1);
      if (type.includes('annual')) used.annual += days;
      else if (type.includes('sick')) used.sick += days;
      else if (type.includes('casual')) used.casual += days;
      else if (type.includes('maternity')) used.maternity += days;
      else if (type.includes('paternity')) used.paternity += days;
      else if (type.includes('unpaid')) used.unpaid += days;
    });

    res.json({
      annual: { total: leaveTypes.annual, used: used.annual },
      sick: { total: leaveTypes.sick, used: used.sick },
      casual: { total: leaveTypes.casual, used: used.casual },
      maternity: { total: leaveTypes.maternity, used: used.maternity },
      paternity: { total: leaveTypes.paternity, used: used.paternity },
      unpaid: { total: leaveTypes.unpaid, used: used.unpaid }
    });
  } catch (e) {
    console.error('Error in getLeaveBalance:', e);
    res.status(500).json({ message: 'Error fetching leave balance.' });
  }
};

exports.getUnassignedUsers = async (req, res) => {
  try {
    // Only consider Employee records with a valid userId
    const assignedUserIds = (await Employee.find({}, 'userId')).map(e => e.userId && e.userId.toString()).filter(Boolean);
    // Only return users who are not assigned, have role 'employee', and are active
    const unassignedUsers = await User.find({
      _id: { $nin: assignedUserIds },
      role: 'employee',
      isActive: true
    });
    console.log('Unassigned users:', unassignedUsers.map(u => u.email));
    res.json(unassignedUsers);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching unassigned users' });
  }
};