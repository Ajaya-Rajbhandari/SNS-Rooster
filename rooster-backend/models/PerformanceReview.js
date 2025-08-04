const mongoose = require('mongoose');

const performanceReviewSchema = new mongoose.Schema({
  employeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Employee',
    required: true
  },
  employeeName: {
    type: String,
    required: true
  },
  reviewerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reviewerName: {
    type: String,
    required: true
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  reviewPeriod: {
    type: String,
    required: true // e.g., "Q4 2024", "Annual 2024"
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  dueDate: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['draft', 'submitted_for_employee_review', 'employee_review_complete', 'completed', 'overdue'],
    default: 'draft'
  },
  scores: {
    communication: { type: Number, min: 1, max: 5 },
    teamwork: { type: Number, min: 1, max: 5 },
    technical: { type: Number, min: 1, max: 5 },
    leadership: { type: Number, min: 1, max: 5 },
    problemSolving: { type: Number, min: 1, max: 5 },
    initiative: { type: Number, min: 1, max: 5 }
  },
  overallRating: {
    type: Number,
    min: 1,
    max: 5
  },
  comments: {
    type: String
  },
  employeeComments: {
    type: String
  },
  goals: [{
    type: String
  }],
  achievements: [{
    type: String
  }],
  areasOfImprovement: [{
    type: String
  }],
  completedAt: {
    type: Date
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Index for better performance
performanceReviewSchema.index({ companyId: 1, status: 1 });
performanceReviewSchema.index({ employeeId: 1 });
performanceReviewSchema.index({ reviewerId: 1 });

// Virtual for calculating overall rating from scores
performanceReviewSchema.virtual('calculatedRating').get(function() {
  if (!this.scores) return null;
  
  const scoreValues = Object.values(this.scores).filter(score => score !== null && score !== undefined);
  if (scoreValues.length === 0) return null;
  
  const sum = scoreValues.reduce((acc, score) => acc + score, 0);
  return Math.round((sum / scoreValues.length) * 10) / 10; // Round to 1 decimal place
});

// Method to update status based on due date
performanceReviewSchema.methods.updateStatus = function() {
  if (this.status === 'completed') return this.status;
  
  const now = new Date();
  if (now > this.dueDate && this.status !== 'completed') {
    this.status = 'overdue';
  }
  return this.status;
};

// Pre-save middleware to update status
performanceReviewSchema.pre('save', function(next) {
  this.updateStatus();
  next();
});

// Static method to get statistics for a company
performanceReviewSchema.statics.getCompanyStatistics = async function(companyId) {
  try {
    const stats = await this.aggregate([
      { $match: { companyId: new mongoose.Types.ObjectId(companyId) } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          inProgress: {
            $sum: { $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0] }
          },
          overdue: {
            $sum: { $cond: [{ $eq: ['$status', 'overdue'] }, 1, 0] }
          },
          draft: {
            $sum: { $cond: [{ $eq: ['$status', 'draft'] }, 1, 0] }
          },
          averageRating: { $avg: '$overallRating' }
        }
      }
    ]);
    
    return stats.length > 0 ? stats[0] : {
      total: 0,
      completed: 0,
      inProgress: 0,
      overdue: 0,
      draft: 0,
      averageRating: null
    };
  } catch (error) {
    console.error('Error in getCompanyStatistics:', error);
    throw error;
  }
};

module.exports = mongoose.model('PerformanceReview', performanceReviewSchema); 