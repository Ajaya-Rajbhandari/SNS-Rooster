const express = require('express');
const router = express.Router();

// Mock data for now
const employees = [
  { id: '1', name: 'John Doe', role: 'Developer', email: 'john@example.com' },
  { id: '2', name: 'Jane Smith', role: 'Designer', email: 'jane@example.com' },
  { id: '3', name: 'Bob Johnson', role: 'Manager', email: 'bob@example.com' },
];

// @route   GET /api/employees
// @desc    Get all employees
// @access  Public (for now, will add auth later)
router.get('/', (req, res) => {
  res.json(employees);
});

module.exports = router; 