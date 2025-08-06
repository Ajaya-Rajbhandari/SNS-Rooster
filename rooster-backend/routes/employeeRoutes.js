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

// Simple leave balance endpoint (for testing)
router.get('/simple/:id/leave-balance', authenticateToken, async (req, res) => {
  try {
    console.log('DEBUG: Simple leave balance endpoint hit');
    console.log('DEBUG: Request headers:', req.headers);
    console.log('DEBUG: Request user:', req.user);
    
    // Get company ID from user or headers
    const companyId = req.user?.companyId || req.headers['x-company-id'];
    
    console.log('DEBUG: Company ID:', companyId);
    
    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'Company ID required. Please provide x-company-id header or ensure user has companyId'
      });
    }

    // Add company ID to request
    req.companyId = companyId;
    req.company = { _id: companyId };
    
    console.log('DEBUG: Calling getLeaveBalance with companyId:', req.companyId);
    const result = await employeeController.getLeaveBalance(req, res);
  } catch (error) {
    console.error('DEBUG: Error in simple leave balance endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave balance',
      error: error.message
    });
  }
});

// Check if email is already used by any employee (global check)
router.get('/check-email', authenticateToken, async (req, res) => {
  try {
    const { email } = req.query;
    
    if (!email) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email parameter is required' 
      });
    }
    
    // Check if any employee (across all companies) has this email
    const Employee = require('../models/Employee');
    const existingEmployee = await Employee.findOne({ 
      email: email.toLowerCase() 
    });
    
    res.json({
      success: true,
      exists: !!existingEmployee,
      data: { exists: !!existingEmployee }
    });
    
  } catch (error) {
    console.error('Error checking email:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error checking email availability',
      data: { exists: true } // Assume exists on error for safety
    });
  }
});

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

// Bulk create employees (admin only)
router.post('/bulk-create', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.bulkCreateEmployees);

// Update an employee (admin/manager or self)
router.put('/:id', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.updateEmployee);

// Bulk update employees (admin only)
router.put('/bulk-update', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.bulkUpdateEmployees);

// Bulk delete employees (admin only)
router.delete('/bulk-delete', authenticateToken, validateCompanyContext, validateUserCompanyAccess, employeeController.bulkDeleteEmployees);

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