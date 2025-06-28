console.log('payrollRoutes loaded');

const express = require('express');
const router = express.Router();
const payrollController = require('../controllers/payroll-controller');
const authMiddleware = require('../middleware/auth');

// Download all payslips for the current logged-in employee as PDF
router.get('/employee/pdf', authMiddleware, payrollController.downloadAllPayslipsPdfForCurrentUser);
// Download all payslips for the current logged-in employee as CSV
router.get('/employee/csv', authMiddleware, payrollController.downloadAllPayslipsCsvForCurrentUser);

// Download all payslips for an employee as PDF
router.get('/employee/:employeeId/pdf', payrollController.downloadAllPayslipsPdf);
// Download all payslips for an employee as CSV
router.get('/employee/:employeeId/csv', payrollController.downloadAllPayslipsCsv);

// Get payrolls for a specific employee
router.get('/employee/:employeeId', (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/employee/:employeeId route hit for employeeId:', req.params.employeeId);
  next();
}, payrollController.getEmployeePayrolls);

// Get payrolls for a specific user (by userId)
router.get('/user/:userId', (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/user/:userId route hit for userId:', req.params.userId);
  next();
}, payrollController.getUserPayrollsByUserId);

// Create a new payroll record
router.post('/', (req, res, next) => {
  console.log('DEBUG: POST /api/payroll - createPayroll route hit');
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.createPayroll);

// Download payslip PDF
router.get('/:payslipId/pdf', (req, res, next) => {
  console.log('DEBUG: GET /api/payroll/:payslipId/pdf route hit for payslipId:', req.params.payslipId);
  next();
}, payrollController.downloadPayslipPdf);

// Update payslip status and comment
router.patch('/:payslipId/status', (req, res, next) => {
  console.log('DEBUG: PATCH /api/payroll/:payslipId/status route hit for payslipId:', req.params.payslipId);
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.updatePayslipStatus);

// Update a payroll record
router.put('/:payrollId', (req, res, next) => {
  console.log('DEBUG: PUT /api/payroll/:payrollId route hit for payrollId:', req.params.payrollId);
  console.log('DEBUG: Request body:', req.body);
  next();
}, payrollController.updatePayroll);

module.exports = router;
