const express = require('express');
const router = express.Router();

// Log all incoming requests to this router
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTER: Incoming request:', req.method, req.originalUrl);
  next();
});

const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const employeeController = require('../controllers/employee-controller');

// Get all employees (admin/manager only)
router.get('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getAllEmployees);

// Get unassigned users (users not already assigned as employees)
router.get('/unassigned-users', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getUnassignedUsers);

// Get leave balance for an employee by ID
router.get('/:id/leave-balance', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getLeaveBalance);

// Get a single employee by ID (admin/manager or self)
router.get('/:id', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getEmployeeById);

// Create a new employee (admin only)
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.createEmployee);

// Update an employee (admin/manager or self)
router.put('/:id', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.updateEmployee);

// Delete an employee (admin only)
router.delete('/:id', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.deleteEmployee);

// Employee dashboard route (authenticated users only)
router.get('/dashboard', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getEmployeeDashboard);

// Get employee's assigned location
router.get('/me/location', authenticateToken, validateCompanyContext, employeeController.getEmployeeLocation);

// Update employee's assigned location
router.put('/:id/location', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.updateEmployeeLocation);

// Remove employee from location (unassign)
router.delete('/:id/location', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.removeEmployeeFromLocation);

// Get employees assigned to a specific location
router.get('/location/:locationId/assigned', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getEmployeesByLocation);

// Get a single employee by User ID (admin/manager or self)
router.get('/user/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.getEmployeeByUserId);

// Document verification (admin only)
router.patch('/users/:userId/documents/:docId/verify', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.verifyUserDocument);

// Admin: Change user password
router.patch('/:id/password', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.adminChangeUserPassword);

console.log('EMPLOYEE ROUTES: Registering /dashboard route');

// Catch-all debug route for unmatched requests
router.use((req, res, next) => {
  console.log('EMPLOYEE ROUTES: Unmatched route:', req.originalUrl);
  next();
});

module.exports = router;