const express = require('express');
const router = express.Router();
const payrollController = require('../controllers/payroll-controller');

// Get all payrolls
router.get('/', payrollController.getAllPayrolls);

// Get payrolls for a specific employee
router.get('/employee/:employeeId', payrollController.getEmployeePayrolls);

// Create a new payroll record
router.post('/', payrollController.createPayroll);

module.exports = router;
