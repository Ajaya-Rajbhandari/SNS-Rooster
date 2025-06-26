const mongoose = require('mongoose');
const Employee = require('../models/Employee');

exports.getAllEmployees = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can view all employees' });
    }
    
    const employees = await Employee.find();
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
    console.log('typeof userId:', typeof userId, 'value:', userId);

    // Debug: print all employees and their userId fields
    const allEmployees = await Employee.find({});
    console.log('All employees:', allEmployees.map(e => ({_id: e._id, userId: e.userId, email: e.email})));

    // Compare as strings for robustness
    const employee = allEmployees.find(e => e.userId && e.userId.toString() === userId);

    if (!employee) {
      console.log('No employee found for userId:', userId);
      return res.status(404).json({ message: 'Employee record not found' });
    }

    const employeeObj = employee.toObject();
    if (employeeObj.userId && typeof employeeObj.userId === 'object' && employeeObj.userId.toString) {
      employeeObj.userId = employeeObj.userId.toString();
    }
    // Return under { data: employeeObj } for frontend compatibility
    res.status(200).json({ data: employeeObj });
  } catch (error) {
    console.error('Error fetching employee by userId:', error);
    res.status(500).json({ message: error.message });
  }
};