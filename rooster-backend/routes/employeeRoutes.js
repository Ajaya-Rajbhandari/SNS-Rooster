const express = require('express');
const router = express.Router();

const Employee = require('../models/Employee');
const authMiddleware = require('../middleware/auth');

// Get all employees (admin/manager only)
router.get('/', authMiddleware, async (req, res) => {
  try {
    // Check if requester is admin or manager
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can view all employees' });
    }
    
    const employees = await Employee.find();
    res.status(200).json(employees);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get a single employee by ID (admin/manager or self)
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    // Check if requester is admin/manager or requesting their own data
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
});

// Create a new employee (admin only)
router.post('/', authMiddleware, async (req, res) => {
  try {
    // Check if requester is admin
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
});

// Update an employee (admin/manager or self)
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    // Check if requester is admin/manager or updating their own data
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== req.params.id) {
      return res.status(403).json({ message: 'Unauthorized to update this employee data' });
    }
    
    const employee = await Employee.findById(req.params.id);
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }

    // Update fields
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
});

// Delete an employee (admin only)
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    // Check if requester is admin
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
});

// Employee dashboard route (authenticated users only)
router.get('/dashboard', authMiddleware, async (req, res) => {
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
});

console.log('EMPLOYEE ROUTES: Registering /dashboard route');

module.exports = router;