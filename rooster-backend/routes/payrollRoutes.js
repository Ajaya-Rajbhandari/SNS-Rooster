const express = require('express');
const router = express.Router();
const Payroll = require('../models/Payroll');
const Employee = require('../models/Employee');

// Get all payrolls
router.get('/', async (req, res) => {
  try {
    const payrolls = await Payroll.find().populate('employee');
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get payrolls for a specific employee
router.get('/employee/:employeeId', async (req, res) => {
  try {
    const payrolls = await Payroll.find({ employee: req.params.employeeId }).populate('employee');
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new payroll record
router.post('/', async (req, res) => {
  try {
    const { employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions } = req.body;
    const payroll = new Payroll({ employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions });
    await payroll.save();
    res.status(201).json(payroll);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
