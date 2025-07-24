const express = require('express');
const router = express.Router();
const Expense = require('../models/Expense');
const Employee = require('../models/Employee');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/expenses/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image, PDF, and document files are allowed'));
    }
  }
});

// Get all expenses for the company
router.get('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      category,
      employeeId,
      startDate,
      endDate,
      search
    } = req.query;
    
    const query = { companyId: req.companyId };
    
    // Apply filters
    if (status) query.status = status;
    if (category) query.category = category;
    if (employeeId) query.employeeId = employeeId;
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (page - 1) * limit;
    
    const expenses = await Expense.find(query)
      .populate('employeeId', 'firstName lastName email employeeId')
      .populate('locationId', 'name')
      .populate('approvalWorkflow.submittedBy', 'firstName lastName')
      .populate('approvalWorkflow.approvedBy', 'firstName lastName')
      .populate('approvalWorkflow.rejectedBy', 'firstName lastName')
      .sort({ date: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Expense.countDocuments(query);
    
    res.json({
      success: true,
      expenses,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching expenses:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch expenses',
      message: error.message
    });
  }
});

// Get expense statistics
router.get('/stats', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { startDate, endDate, category, employeeId } = req.query;
    
    const filters = {};
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (category) filters.category = category;
    if (employeeId) filters.employeeId = employeeId;
    
    const stats = await Expense.getExpenseStats(req.companyId, filters);
    const categoryStats = await Expense.getExpensesByCategory(req.companyId, filters);
    
    res.json({
      success: true,
      stats,
      categoryStats
    });
  } catch (error) {
    console.error('Error fetching expense stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch expense statistics',
      message: error.message
    });
  }
});

// Get a specific expense by ID
router.get('/:expenseId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId)
      .populate('employeeId', 'firstName lastName email employeeId')
      .populate('locationId', 'name')
      .populate('approvalWorkflow.submittedBy', 'firstName lastName')
      .populate('approvalWorkflow.approvedBy', 'firstName lastName')
      .populate('approvalWorkflow.rejectedBy', 'firstName lastName')
      .populate('approvalWorkflow.paidBy', 'firstName lastName');
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    res.json({
      success: true,
      expense
    });
  } catch (error) {
    console.error('Error fetching expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch expense',
      message: error.message
    });
  }
});

// Create a new expense
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, upload.single('receipt'), async (req, res) => {
  try {
    const {
      employeeId,
      locationId,
      category,
      title,
      description,
      amount,
      currency,
      date,
      tags,
      project,
      client,
      isReimbursable,
      isBillable
    } = req.body;
    
    // Validate required fields
    if (!employeeId || !category || !title || !amount) {
      return res.status(400).json({
        success: false,
        error: 'Employee ID, category, title, and amount are required'
      });
    }
    
    // Verify employee belongs to company
    const employee = await Employee.findOne({
      _id: employeeId,
      companyId: req.companyId,
      isActive: true
    });
    
    if (!employee) {
      return res.status(400).json({
        success: false,
        error: 'Invalid employee'
      });
    }
    
    // Check expense limit if set
    if (employee.expenseLimit > 0 && parseFloat(amount) > employee.expenseLimit) {
      return res.status(400).json({
        success: false,
        error: 'Expense amount exceeds employee limit',
        message: `Employee limit: ${employee.expenseLimit}, Requested: ${amount}`
      });
    }
    
    const expenseData = {
      companyId: req.companyId,
      employeeId,
      locationId,
      category,
      title,
      description,
      amount: parseFloat(amount),
      currency: currency || 'NPR',
      date: date ? new Date(date) : new Date(),
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      project,
      client,
      isReimbursable: isReimbursable === 'true',
      isBillable: isBillable === 'true',
      approvalWorkflow: {
        submittedBy: req.user.id
      }
    };
    
    // Handle file upload
    if (req.file) {
      expenseData.receipt = {
        filename: req.file.filename,
        originalName: req.file.originalname,
        mimeType: req.file.mimetype,
        size: req.file.size,
        url: `/uploads/expenses/${req.file.filename}`
      };
    }
    
    const expense = new Expense(expenseData);
    await expense.save();
    
    // Populate employee info for response
    await expense.populate('employeeId', 'firstName lastName email employeeId');
    
    res.status(201).json({
      success: true,
      expense,
      message: 'Expense submitted successfully'
    });
  } catch (error) {
    console.error('Error creating expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create expense',
      message: error.message
    });
  }
});

// Update an expense
router.put('/:expenseId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, upload.single('receipt'), async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow updates if expense is pending
    if (expense.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update expense that is not pending'
      });
    }
    
    const updateData = req.body;
    
    // Handle file upload
    if (req.file) {
      updateData.receipt = {
        filename: req.file.filename,
        originalName: req.file.originalname,
        mimeType: req.file.mimetype,
        size: req.file.size,
        url: `/uploads/expenses/${req.file.filename}`
      };
    }
    
    // Update the expense
    Object.assign(expense, updateData);
    await expense.save();
    
    res.json({
      success: true,
      expense,
      message: 'Expense updated successfully'
    });
  } catch (error) {
    console.error('Error updating expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update expense',
      message: error.message
    });
  }
});

// Approve an expense
router.post('/:expenseId/approve', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (expense.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Expense is not pending approval'
      });
    }
    
    await expense.approve(req.user.id, req.body.notes);
    
    res.json({
      success: true,
      expense,
      message: 'Expense approved successfully'
    });
  } catch (error) {
    console.error('Error approving expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to approve expense',
      message: error.message
    });
  }
});

// Reject an expense
router.post('/:expenseId/reject', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const { reason } = req.body;
    
    if (!reason) {
      return res.status(400).json({
        success: false,
        error: 'Rejection reason is required'
      });
    }
    
    const expense = await Expense.findById(req.params.expenseId);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (expense.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Expense is not pending approval'
      });
    }
    
    await expense.reject(req.user.id, reason);
    
    res.json({
      success: true,
      expense,
      message: 'Expense rejected successfully'
    });
  } catch (error) {
    console.error('Error rejecting expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to reject expense',
      message: error.message
    });
  }
});

// Mark expense as paid
router.post('/:expenseId/mark-paid', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (expense.status !== 'approved') {
      return res.status(400).json({
        success: false,
        error: 'Expense must be approved before marking as paid'
      });
    }
    
    await expense.markAsPaid(req.user.id);
    
    res.json({
      success: true,
      expense,
      message: 'Expense marked as paid successfully'
    });
  } catch (error) {
    console.error('Error marking expense as paid:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to mark expense as paid',
      message: error.message
    });
  }
});

// Delete an expense
router.delete('/:expenseId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const expense = await Expense.findById(req.params.expenseId);
    
    if (!expense) {
      return res.status(404).json({
        success: false,
        error: 'Expense not found'
      });
    }
    
    // Verify the expense belongs to the company
    if (expense.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow deletion if expense is pending
    if (expense.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Cannot delete expense that is not pending'
      });
    }
    
    await Expense.findByIdAndDelete(req.params.expenseId);
    
    res.json({
      success: true,
      message: 'Expense deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting expense:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete expense',
      message: error.message
    });
  }
});

module.exports = router; 