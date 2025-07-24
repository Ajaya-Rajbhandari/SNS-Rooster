const express = require('express');
const router = express.Router();
const PerformanceReview = require('../models/PerformanceReview');
const Employee = require('../models/Employee');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/performance/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
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

// Get all performance reviews for the company
router.get('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      reviewType,
      employeeId,
      startDate,
      endDate,
      search
    } = req.query;
    
    const query = { companyId: req.companyId };
    
    // Apply filters
    if (status) query.status = status;
    if (reviewType) query.reviewType = reviewType;
    if (employeeId) query.employeeId = employeeId;
    if (startDate || endDate) {
      query['reviewPeriod.startDate'] = {};
      if (startDate) query['reviewPeriod.startDate'].$gte = new Date(startDate);
      if (endDate) query['reviewPeriod.startDate'].$lte = new Date(endDate);
    }
    if (search) {
      query.$or = [
        { summary: { $regex: search, $options: 'i' } },
        { recommendations: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (page - 1) * limit;
    
    const reviews = await PerformanceReview.find(query)
      .populate('employeeId', 'firstName lastName email employeeId position department')
      .populate('reviewerId', 'firstName lastName')
      .populate('workflow.createdBy', 'firstName lastName')
      .populate('workflow.submittedBy', 'firstName lastName')
      .populate('workflow.approvedBy', 'firstName lastName')
      .populate('workflow.acknowledgedBy', 'firstName lastName')
      .sort({ 'reviewPeriod.startDate': -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await PerformanceReview.countDocuments(query);
    
    res.json({
      success: true,
      reviews,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching performance reviews:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch performance reviews',
      message: error.message
    });
  }
});

// Get performance review statistics
router.get('/stats', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { startDate, endDate, reviewType, status } = req.query;
    
    const filters = {};
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (reviewType) filters.reviewType = reviewType;
    if (status) filters.status = status;
    
    const stats = await PerformanceReview.getPerformanceStats(req.companyId, filters);
    
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('Error fetching performance stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch performance statistics',
      message: error.message
    });
  }
});

// Get a specific performance review by ID
router.get('/:reviewId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId)
      .populate('employeeId', 'firstName lastName email employeeId position department')
      .populate('reviewerId', 'firstName lastName')
      .populate('workflow.createdBy', 'firstName lastName')
      .populate('workflow.submittedBy', 'firstName lastName')
      .populate('workflow.approvedBy', 'firstName lastName')
      .populate('workflow.acknowledgedBy', 'firstName lastName');
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    res.json({
      success: true,
      review
    });
  } catch (error) {
    console.error('Error fetching performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch performance review',
      message: error.message
    });
  }
});

// Create a new performance review
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const {
      employeeId,
      reviewerId,
      reviewType,
      reviewPeriod,
      goals,
      achievements,
      areasForImprovement,
      strengths,
      weaknesses,
      summary,
      recommendations,
      nextReviewDate,
      tags
    } = req.body;
    
    // Validate required fields
    if (!employeeId || !reviewerId || !reviewType || !reviewPeriod) {
      return res.status(400).json({
        success: false,
        error: 'Employee ID, reviewer ID, review type, and review period are required'
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
    
    const reviewData = {
      companyId: req.companyId,
      employeeId,
      reviewerId,
      reviewType,
      reviewPeriod: {
        startDate: new Date(reviewPeriod.startDate),
        endDate: new Date(reviewPeriod.endDate)
      },
      goals: goals || [],
      achievements: achievements || [],
      areasForImprovement: areasForImprovement || [],
      strengths: strengths || [],
      weaknesses: weaknesses || [],
      summary,
      recommendations,
      nextReviewDate: nextReviewDate ? new Date(nextReviewDate) : null,
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      workflow: {
        createdBy: req.user.id
      }
    };
    
    const review = new PerformanceReview(reviewData);
    await review.save();
    
    // Update employee's last performance review date
    employee.lastPerformanceReview = new Date();
    if (nextReviewDate) {
      employee.nextPerformanceReview = new Date(nextReviewDate);
    }
    await employee.save();
    
    // Populate employee info for response
    await review.populate('employeeId', 'firstName lastName email employeeId position department');
    await review.populate('reviewerId', 'firstName lastName');
    
    res.status(201).json({
      success: true,
      review,
      message: 'Performance review created successfully'
    });
  } catch (error) {
    console.error('Error creating performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create performance review',
      message: error.message
    });
  }
});

// Update a performance review
router.put('/:reviewId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow updates if review is draft
    if (review.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update review that is not in draft status'
      });
    }
    
    const updateData = req.body;
    
    // Update the review
    Object.assign(review, updateData);
    await review.save();
    
    res.json({
      success: true,
      review,
      message: 'Performance review updated successfully'
    });
  } catch (error) {
    console.error('Error updating performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update performance review',
      message: error.message
    });
  }
});

// Submit a performance review
router.post('/:reviewId/submit', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (review.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Review is not in draft status'
      });
    }
    
    await review.submit(req.user.id);
    
    res.json({
      success: true,
      review,
      message: 'Performance review submitted successfully'
    });
  } catch (error) {
    console.error('Error submitting performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to submit performance review',
      message: error.message
    });
  }
});

// Complete a performance review
router.post('/:reviewId/complete', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (review.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        error: 'Review is not in progress'
      });
    }
    
    await review.complete();
    
    res.json({
      success: true,
      review,
      message: 'Performance review completed successfully'
    });
  } catch (error) {
    console.error('Error completing performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to complete performance review',
      message: error.message
    });
  }
});

// Approve a performance review
router.post('/:reviewId/approve', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (review.status !== 'completed') {
      return res.status(400).json({
        success: false,
        error: 'Review must be completed before approval'
      });
    }
    
    await review.approve(req.user.id);
    
    res.json({
      success: true,
      review,
      message: 'Performance review approved successfully'
    });
  } catch (error) {
    console.error('Error approving performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to approve performance review',
      message: error.message
    });
  }
});

// Acknowledge a performance review (by employee)
router.post('/:reviewId/acknowledge', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Verify the user is the employee being reviewed
    if (review.employeeId.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'Only the reviewed employee can acknowledge the review'
      });
    }
    
    await review.acknowledge(req.user.id);
    
    res.json({
      success: true,
      review,
      message: 'Performance review acknowledged successfully'
    });
  } catch (error) {
    console.error('Error acknowledging performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to acknowledge performance review',
      message: error.message
    });
  }
});

// Delete a performance review
router.delete('/:reviewId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const review = await PerformanceReview.findById(req.params.reviewId);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        error: 'Performance review not found'
      });
    }
    
    // Verify the review belongs to the company
    if (review.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow deletion if review is draft
    if (review.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Cannot delete review that is not in draft status'
      });
    }
    
    await PerformanceReview.findByIdAndDelete(req.params.reviewId);
    
    res.json({
      success: true,
      message: 'Performance review deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting performance review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete performance review',
      message: error.message
    });
  }
});

module.exports = router; 