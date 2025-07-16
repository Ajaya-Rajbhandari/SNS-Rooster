const express = require('express');
const router = express.Router();

// Log all incoming requests to this router
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTER: Incoming request:', req.method, req.originalUrl);
  next();
});

const { authenticateToken } = require('../middleware/auth');
const employeeController = require('../controllers/employee-controller');

// Get all employees (admin/manager only)
router.get('/', authenticateToken, employeeController.getAllEmployees);

// Get unassigned users (users not already assigned as employees)
router.get('/unassigned-users', authenticateToken, employeeController.getUnassignedUsers);

// Get leave balance for an employee by ID
router.get('/:id/leave-balance', authenticateToken, employeeController.getLeaveBalance);

// Get a single employee by ID (admin/manager or self)
router.get('/:id', authenticateToken, employeeController.getEmployeeById);

// Create a new employee (admin only)
router.post('/', authenticateToken, employeeController.createEmployee);

// Update an employee (admin/manager or self)
router.put('/:id', authenticateToken, employeeController.updateEmployee);

// Delete an employee (admin only)
router.delete('/:id', authenticateToken, employeeController.deleteEmployee);

// Employee dashboard route (authenticated users only)
router.get('/dashboard', authenticateToken, employeeController.getEmployeeDashboard);

// Get a single employee by User ID (admin/manager or self)
router.get('/user/:userId', authenticateToken, employeeController.getEmployeeByUserId);

// Document verification (admin only)
router.patch('/users/:userId/documents/:docId/verify', authenticateToken, employeeController.verifyUserDocument);

// Admin: Change user password
router.patch('/:id/password', authenticateToken, employeeController.adminChangeUserPassword);

console.log('EMPLOYEE ROUTES: Registering /dashboard route');

// Catch-all debug route for unmatched requests
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTES: Unmatched route:', req.originalUrl);
  next();
});

module.exports = router;