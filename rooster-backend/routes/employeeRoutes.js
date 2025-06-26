const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/auth');
const employeeController = require('../controllers/employee-controller');

// Get all employees (admin/manager only)
router.get('/', authMiddleware, employeeController.getAllEmployees);

// Get a single employee by ID (admin/manager or self)
router.get('/:id', authMiddleware, employeeController.getEmployeeById);

// Create a new employee (admin only)
router.post('/', authMiddleware, employeeController.createEmployee);

// Update an employee (admin/manager or self)
router.put('/:id', authMiddleware, employeeController.updateEmployee);

// Delete an employee (admin only)
router.delete('/:id', authMiddleware, employeeController.deleteEmployee);

// Employee dashboard route (authenticated users only)
router.get('/dashboard', authMiddleware, employeeController.getEmployeeDashboard);

// Get a single employee by User ID (admin/manager or self)
router.get('/user/:userId', authMiddleware, employeeController.getEmployeeByUserId);

console.log('EMPLOYEE ROUTES: Registering /dashboard route');

module.exports = router;