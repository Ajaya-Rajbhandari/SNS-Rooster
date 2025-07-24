const mongoose = require('mongoose');

const performanceReviewSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  employeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Employee',
    required: true,
    index: true
  },
  reviewerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reviewType: {
    type: String,
    enum: ['annual', 'quarterly', 'monthly', 'probation', 'project', 'custom'],
    required: true
  },
  reviewPeriod: {
    startDate: {
      type: Date,
      required: true
    },
    endDate: {
      type: Date,
      required: true
    }
  },
  status: {
    type: String,
    enum: ['draft', 'in_progress', 'completed', 'approved', 'archived'],
    default: 'draft',
    index: true
  },
  overallRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  ratings: {
    jobKnowledge: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    qualityOfWork: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    productivity: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    communication: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    teamwork: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    problemSolving: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    initiative: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    attendance: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    leadership: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    },
    adaptability: {
      rating: { type: Number, min: 1, max: 5 },
      comments: String
    }
  },
  goals: [{
    title: {
      type: String,
      required: true,
      trim: true
    },
    description: String,
    targetDate: Date,
    status: {
      type: String,
      enum: ['not_started', 'in_progress', 'completed', 'overdue'],
      default: 'not_started'
    },
    progress: {
      type: Number,
      min: 0,
      max: 100,
      default: 0
    },
    comments: String
  }],
  achievements: [{
    title: {
      type: String,
      required: true,
      trim: true
    },
    description: String,
    impact: String,
    date: {
      type: Date,
      default: Date.now
    }
  }],
  areasForImprovement: [{
    area: {
      type: String,
      required: true,
      trim: true
    },
    description: String,
    actionPlan: String,
    targetDate: Date
  }],
  strengths: [{
    type: String,
    trim: true
  }],
  weaknesses: [{
    type: String,
    trim: true
  }],
  summary: {
    type: String,
    trim: true
  },
  recommendations: {
    type: String,
    trim: true
  },
  nextReviewDate: {
    type: Date
  },
  workflow: {
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
    submittedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    submittedAt: Date,
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    approvedAt: Date,
    acknowledgedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    acknowledgedAt: Date
  },
  attachments: [{
    filename: String,
    originalName: String,
    mimeType: String,
    size: Number,
    url: String,
    uploadedAt: {
      type: Date,
      default: Date.now
    }
  }],
  isConfidential: {
    type: Boolean,
    default: true
  },
  tags: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// Indexes for better query performance
performanceReviewSchema.index({ companyId: 1, status: 1 });
performanceReviewSchema.index({ companyId: 1, employeeId: 1 });
performanceReviewSchema.index({ companyId: 1, 'reviewPeriod.startDate': -1 });
performanceReviewSchema.index({ companyId: 1, reviewType: 1 });

// Virtual for review period duration
performanceReviewSchema.virtual('duration').get(function() {
  const start = this.reviewPeriod.startDate;
  const end = this.reviewPeriod.endDate;
  if (start && end) {
    const diffTime = Math.abs(end - start);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }
  return 0;
});

// Virtual for average rating
performanceReviewSchema.virtual('averageRating').get(function() {
  const ratings = Object.values(this.ratings || {});
  const validRatings = ratings.filter(r => r.rating && r.rating > 0);
  
  if (validRatings.length === 0) return null;
  
  const sum = validRatings.reduce((acc, r) => acc + r.rating, 0);
  return Math.round((sum / validRatings.length) * 10) / 10;
});

// Virtual for rating level
performanceReviewSchema.virtual('ratingLevel').get(function() {
  const rating = this.overallRating || this.averageRating;
  if (!rating) return 'Not Rated';
  
  if (rating >= 4.5) return 'Outstanding';
  if (rating >= 4.0) return 'Excellent';
  if (rating >= 3.5) return 'Good';
  if (rating >= 3.0) return 'Satisfactory';
  if (rating >= 2.0) return 'Needs Improvement';
  return 'Unsatisfactory';
});

// Pre-save middleware to calculate overall rating
performanceReviewSchema.pre('save', function(next) {
  if (!this.overallRating) {
    this.overallRating = this.averageRating;
  }
  next();
});

// Static method to get performance statistics
performanceReviewSchema.statics.getPerformanceStats = async function(companyId, filters = {}) {
  const matchStage = { companyId };
  
  if (filters.startDate) matchStage['reviewPeriod.startDate'] = { $gte: new Date(filters.startDate) };
  if (filters.endDate) {
    if (matchStage['reviewPeriod.startDate']) {
      matchStage['reviewPeriod.startDate'].$lte = new Date(filters.endDate);
    } else {
      matchStage['reviewPeriod.startDate'] = { $lte: new Date(filters.endDate) };
    }
  }
  if (filters.status) matchStage.status = filters.status;
  if (filters.reviewType) matchStage.reviewType = filters.reviewType;

  const stats = await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalReviews: { $sum: 1 },
        averageRating: { $avg: '$overallRating' },
        completedReviews: {
          $sum: {
            $cond: [{ $eq: ['$status', 'completed'] }, 1, 0]
          }
        },
        pendingReviews: {
          $sum: {
            $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0]
          }
        },
        draftReviews: {
          $sum: {
            $cond: [{ $eq: ['$status', 'draft'] }, 1, 0]
          }
        }
      }
    }
  ]);

  return stats[0] || {
    totalReviews: 0,
    averageRating: 0,
    completedReviews: 0,
    pendingReviews: 0,
    draftReviews: 0
  };
};

// Instance method to submit review
performanceReviewSchema.methods.submit = async function(submittedBy) {
  this.status = 'in_progress';
  this.workflow.submittedBy = submittedBy;
  this.workflow.submittedAt = new Date();
  await this.save();
};

// Instance method to complete review
performanceReviewSchema.methods.complete = async function() {
  this.status = 'completed';
  await this.save();
};

// Instance method to approve review
performanceReviewSchema.methods.approve = async function(approvedBy) {
  this.status = 'approved';
  this.workflow.approvedBy = approvedBy;
  this.workflow.approvedAt = new Date();
  await this.save();
};

// Instance method to acknowledge review
performanceReviewSchema.methods.acknowledge = async function(acknowledgedBy) {
  this.workflow.acknowledgedBy = acknowledgedBy;
  this.workflow.acknowledgedAt = new Date();
  await this.save();
};

module.exports = mongoose.model('PerformanceReview', performanceReviewSchema); 