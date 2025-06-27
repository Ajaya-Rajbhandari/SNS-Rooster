console.log('payrollRoutes loaded');

const express = require('express');
const router = express.Router();
const payrollController = require('../controllers/payroll-controller');

// Get all payrolls
router.get('/', payrollController.getAllPayrolls);

// Get payrolls for a specific employee
router.get('/employee/:employeeId', payrollController.getEmployeePayrolls);

// Get payrolls for a specific user (by userId)
router.get('/user/:userId', payrollController.getUserPayrollsByUserId);

// Create a new payroll record
router.post('/', payrollController.createPayroll);

module.exports = router;
