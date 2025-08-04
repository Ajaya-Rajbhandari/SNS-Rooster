const PerformanceReview = require('../models/PerformanceReview');
const Employee = require('../models/Employee');
const User = require('../models/User');
const { Logger } = require('../config/logger');

// Get all performance reviews for the company
exports.getPerformanceReviews = async (req, res) => {
  try {
    const { status, employeeId, page = 1, limit = 20 } = req.query;
    const companyId = req.companyId;
    const currentUserId = req.user.userId;
    const userRole = req.user.role;

    // Build filter
    const filter = { companyId };
    if (status && status !== 'all') {
      filter.status = status;
    }
    
    // If user is an employee, only show their own reviews
    if (userRole === 'employee') {
      // Find the employee record for the current user
      const employee = await Employee.findOne({ userId: currentUserId, companyId });
      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee record not found'
        });
      }
      filter.employeeId = employee._id;
    } else if (employeeId) {
      // For admins, allow filtering by specific employee
      filter.employeeId = employeeId;
    }

    // Calculate pagination
    const skip = (page - 1) * limit;

    // Get reviews with pagination
    const reviews = await PerformanceReview.find(filter)
      .populate('employeeId', 'firstName lastName email')
      .populate('reviewerId', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count for pagination
    const totalReviews = await PerformanceReview.countDocuments(filter);

    Logger.info(`Retrieved ${reviews.length} performance reviews for company ${companyId}`);  

    res.json({
      success: true,
      data: reviews,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalReviews / limit),
        totalReviews,
        hasNext: page * limit < totalReviews,
        hasPrev: page > 1
      }
    });
  } catch (error) {
    Logger.error('Error fetching performance reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch performance reviews',
      error: error.message
    });
  }
};

// Get performance review statistics
exports.getStatistics = async (req, res) => {
  try {
    const companyId = req.companyId;

    const statistics = await PerformanceReview.getCompanyStatistics(companyId);

    Logger.info(`Retrieved performance review statistics for company ${companyId}`);

    res.json({
      success: true,
      data: statistics
    });
  } catch (error) {
    Logger.error('Error fetching performance review statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message
    });
  }
};

// Get a specific performance review
exports.getPerformanceReview = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;
    const currentUserId = req.user.userId;
    const userRole = req.user.role;

    // Build filter
    const filter = { _id: id, companyId };
    
    // If user is an employee, ensure they can only access their own reviews
    if (userRole === 'employee') {
      const employee = await Employee.findOne({ userId: currentUserId, companyId });
      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee record not found'
        });
      }
      filter.employeeId = employee._id;
    }

    const review = await PerformanceReview.findOne(filter)
      .populate('employeeId', 'firstName lastName email department position')
      .populate('reviewerId', 'firstName lastName email')
      .populate('createdBy', 'firstName lastName email');

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Performance review not found'
      });
    }

    Logger.info(`Retrieved performance review ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: review
    });
  } catch (error) {
    Logger.error('Error fetching performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch performance review',
      error: error.message
    });
  }
};

// Create a new performance review
exports.createPerformanceReview = async (req, res) => {
  try {
    const companyId = req.companyId;
    const createdBy = req.user.userId;
    const {
      employeeId,
      reviewerId,
      reviewPeriod,
      startDate,
      endDate,
      dueDate,
      goals = [],
      scores = {}
    } = req.body;

    // Validate employee exists and belongs to company
    const employee = await Employee.findOne({ _id: employeeId, companyId });
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found'
      });
    }

    // Validate reviewer exists
    const reviewer = await User.findById(reviewerId);
    if (!reviewer) {
      return res.status(404).json({
        success: false,
        message: 'Reviewer not found'
      });
    }

    // Create performance review
    const performanceReview = new PerformanceReview({
      employeeId,
      employeeName: `${employee.firstName} ${employee.lastName}`,
      reviewerId,
      reviewerName: `${reviewer.firstName} ${reviewer.lastName}`,
      companyId,
      reviewPeriod,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      dueDate: new Date(dueDate),
      goals,
      scores,
      createdBy
    });

    await performanceReview.save();

    Logger.info(`Created performance review for employee ${employeeId} in company ${companyId}`);

    res.status(201).json({
      success: true,
      data: performanceReview,
      message: 'Performance review created successfully'
    });
  } catch (error) {
    Logger.error('Error creating performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create performance review',
      error: error.message
    });
  }
};

// Update a performance review
exports.updatePerformanceReview = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;
    const currentUserId = req.user.userId;
    const userRole = req.user.role;
    const updateData = { ...req.body, updatedBy: currentUserId };

    // Build filter
    const filter = { _id: id, companyId };
    
    // If user is an employee, ensure they can only update their own reviews
    if (userRole === 'employee') {
      const employee = await Employee.findOne({ userId: currentUserId, companyId });
      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee record not found'
        });
      }
      filter.employeeId = employee._id;
      
      // Employees can only update specific fields
      const allowedFields = ['employeeComments', 'status'];
      const filteredUpdateData = {};
      allowedFields.forEach(field => {
        if (updateData[field] !== undefined) {
          filteredUpdateData[field] = updateData[field];
        }
      });
      filteredUpdateData.updatedBy = currentUserId;
      
      // Only allow status change to 'employee_review_complete' when employee adds comments
      if (filteredUpdateData.status && filteredUpdateData.status !== 'employee_review_complete') {
        return res.status(403).json({
          success: false,
          message: 'Employees can only complete their self-assessment'
        });
      }
      
      Object.assign(updateData, filteredUpdateData);
    }

    const review = await PerformanceReview.findOneAndUpdate(
      filter,
      updateData,
      { new: true, runValidators: true }
    ).populate('employeeId', 'firstName lastName email')
     .populate('reviewerId', 'firstName lastName email');

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Performance review not found'
      });
    }

    Logger.info(`Updated performance review ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: review,
      message: 'Performance review updated successfully'
    });
  } catch (error) {
    Logger.error('Error updating performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update performance review',
      error: error.message
    });
  }
};

// Submit a performance review (change status to in_progress)
exports.submitPerformanceReview = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;

    const review = await PerformanceReview.findOneAndUpdate(
      { _id: id, companyId, status: 'draft' },
      { status: 'in_progress' },
      { new: true }
    );

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Performance review not found or cannot be submitted'
      });
    }

    Logger.info(`Submitted performance review ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: review,
      message: 'Performance review submitted successfully'
    });
  } catch (error) {
    Logger.error('Error submitting performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit performance review',
      error: error.message
    });
  }
};

// Complete a performance review
exports.completePerformanceReview = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;
    const { overallRating, comments, employeeComments, achievements, areasOfImprovement } = req.body;

    const review = await PerformanceReview.findOneAndUpdate(
      { _id: id, companyId },
      {
        status: 'completed',
        completedAt: new Date(),
        overallRating,
        comments,
        employeeComments,
        achievements: achievements || [],
        areasOfImprovement: areasOfImprovement || []
      },
      { new: true }
    );

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Performance review not found'
      });
    }

        Logger.info(`Completed performance review ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: review,
      message: 'Performance review completed successfully'
    });
  } catch (error) {
    Logger.error('Error completing performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete performance review',
      error: error.message
    });
  }
};

// Delete a performance review
exports.deletePerformanceReview = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;

    const review = await PerformanceReview.findOneAndDelete({ _id: id, companyId });

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Performance review not found'
      });
    }

    Logger.info(`Deleted performance review ${id} for company ${companyId}`);

    res.json({
      success: true,
      message: 'Performance review deleted successfully'
    });
  } catch (error) {
    Logger.error('Error deleting performance review:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete performance review',
      error: error.message
    });
  }
};

// Get employees eligible for performance review
exports.getEligibleEmployees = async (req, res) => {
  try {
    const companyId = req.companyId;

    const employees = await Employee.find({ 
      companyId, 
      status: 'active' 
    }).select('firstName lastName email department position hireDate');

    Logger.info(`Retrieved ${employees.length} eligible employees for company ${companyId}`);

    res.json({
      success: true,
      data: employees
    });
  } catch (error) {
      Logger.error('Error fetching eligible employees:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch eligible employees',
      error: error.message
    });
  }
}; 