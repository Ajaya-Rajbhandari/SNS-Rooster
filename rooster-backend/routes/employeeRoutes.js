const express = require('express');
const router = express.Router();

// Log all incoming requests to this router
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTER: Incoming request:', req.method, req.originalUrl);
  next();
});

const authMiddleware = require('../middleware/auth');
const employeeController = require('../controllers/employee-controller');

// Get all employees (admin/manager only)
router.get('/', authMiddleware, employeeController.getAllEmployees);

// Get unassigned users (users not already assigned as employees)
router.get('/unassigned-users', authMiddleware, employeeController.getUnassignedUsers);

// Get leave balance for an employee by ID
router.get('/:id/leave-balance', authMiddleware, employeeController.getLeaveBalance);

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

// Catch-all debug route for unmatched requests
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTES: Unmatched route:', req.originalUrl);
  next();
});

module.exports = router;