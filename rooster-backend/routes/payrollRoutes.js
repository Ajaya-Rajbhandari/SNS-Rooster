console.log('payrollRoutes loaded');

const express = require('express');
const router = express.Router();
const payrollController = require('../controllers/payroll-controller');
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');

// DEBUG: Test company context
router.get('/test', (req, res) => {
  console.log('DEBUG: /payroll/test route hit');
  console.log('DEBUG: req.companyId:', req.companyId);
  console.log('DEBUG: req.user:', req.user);
  console.log('DEBUG: req.headers:', req.headers);
  
  res.json({
    success: true,
    message: 'Payroll test endpoint working',
    companyId: req.companyId,
    userId: req.user?.userId,
    headers: {
      'x-company-id': req.headers['x-company-id'],
      'authorization': req.headers['authorization'] ? 'Present' : 'Missing'
    }
  });
});

// DEBUG: Update all payslips with latest company info
router.post('/update-company-info', payrollController.updatePayslipsCompanyInfo);

// Download all payslips for the current logged-in employee as PDF
router.get('/employee/pdf', authenticateToken, validateCompanyContext, validateUserCompanyAccess, payrollController.downloadAllPayslipsPdfForCurrentUser);
// Download all payslips for the current logged-in employee as CSV
router.get('/employee/csv', authenticateToken, validateCompanyContext, validateUserCompanyAccess, payrollController.downloadAllPayslipsCsvForCurrentUser);

// Get current user's payroll slips
router.get('/employee', authenticateToken, validateCompanyContext, validateUserCompanyAccess, payrollController.getCurrentUserPayrolls);

// Download all payslips for an employee as PDF
router.get('/employee/:employeeId/pdf', authenticateToken, validateCompanyContext, validateUserCompanyAccess, payrollController.downloadAllPayslipsPdf);
// Download all payslips for an employee as CSV
router.get('/employee/:employeeId/csv', authenticateToken, validateCompanyContext, validateUserCompanyAccess, payrollController.downloadAllPayslipsCsv);

// Get payrolls for a specific employee
router.get('/employee/:employeeId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/employee/:employeeId route hit for employeeId:', req.params.employeeId);
  next();
}, payrollController.getEmployeePayrolls);

// Get payrolls for a specific user (by userId)
router.get('/user/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/user/:userId route hit for userId:', req.params.userId);
  next();
}, payrollController.getUserPayrollsByUserId);

// Create a new payroll record
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: POST /api/payroll - createPayroll route hit');
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.createPayroll);

// Download payslip PDF
router.get('/:payslipId/pdf', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/:payslipId/pdf route hit for payslipId:', req.params.payslipId);
  next();
}, payrollController.downloadPayslipPdf);

// Update payslip status and comment
router.patch('/:payslipId/status', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: PATCH /api/payroll/:payslipId/status route hit for payslipId:', req.params.payslipId);
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.updatePayslipStatus);

// Update a payroll record
router.put('/:payrollId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res, next) => {
  console.log('DEBUG: PUT /api/payroll/:payrollId route hit for payrollId:', req.params.payrollId);
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.updatePayroll);

module.exports = router;
