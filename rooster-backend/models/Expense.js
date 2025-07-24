const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
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
  locationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Location'
  },
  category: {
    type: String,
    required: true,
    enum: [
      'travel',
      'meals',
      'office_supplies',
      'equipment',
      'software',
      'training',
      'entertainment',
      'transportation',
      'accommodation',
      'other'
    ]
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'NPR',
    uppercase: true
  },
  date: {
    type: Date,
    required: true,
    default: Date.now
  },
  receipt: {
    filename: String,
    originalName: String,
    mimeType: String,
    size: Number,
    url: String
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'paid'],
    default: 'pending',
    index: true
  },
  approvalWorkflow: {
    submittedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    submittedAt: {
      type: Date,
      default: Date.now
    },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    approvedAt: Date,
    rejectedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    rejectedAt: Date,
    rejectionReason: String,
    paidBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    paidAt: Date
  },
  tags: [{
    type: String,
    trim: true
  }],
  project: {
    type: String,
    trim: true
  },
  client: {
    type: String,
    trim: true
  },
  isReimbursable: {
    type: Boolean,
    default: true
  },
  isBillable: {
    type: Boolean,
    default: false
  },
  notes: {
    type: String,
    trim: true
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
  }]
}, {
  timestamps: true
});

// Indexes for better query performance
expenseSchema.index({ companyId: 1, status: 1 });
expenseSchema.index({ companyId: 1, employeeId: 1 });
expenseSchema.index({ companyId: 1, date: -1 });
expenseSchema.index({ companyId: 1, category: 1 });

// Virtual for formatted amount
expenseSchema.virtual('formattedAmount').get(function() {
  return `${this.currency} ${this.amount.toFixed(2)}`;
});

// Virtual for status color
expenseSchema.virtual('statusColor').get(function() {
  switch (this.status) {
    case 'pending': return 'orange';
    case 'approved': return 'green';
    case 'rejected': return 'red';
    case 'paid': return 'blue';
    default: return 'grey';
  }
});

// Pre-save middleware to validate amount
expenseSchema.pre('save', function(next) {
  if (this.amount <= 0) {
    return next(new Error('Expense amount must be greater than 0'));
  }
  next();
});

// Static method to get expense statistics
expenseSchema.statics.getExpenseStats = async function(companyId, filters = {}) {
  const matchStage = { companyId };
  
  if (filters.startDate) matchStage.date = { $gte: new Date(filters.startDate) };
  if (filters.endDate) {
    if (matchStage.date) {
      matchStage.date.$lte = new Date(filters.endDate);
    } else {
      matchStage.date = { $lte: new Date(filters.endDate) };
    }
  }
  if (filters.status) matchStage.status = filters.status;
  if (filters.category) matchStage.category = filters.category;
  if (filters.employeeId) matchStage.employeeId = filters.employeeId;

  const stats = await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalAmount: { $sum: '$amount' },
        totalCount: { $sum: 1 },
        pendingAmount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'pending'] }, '$amount', 0]
          }
        },
        pendingCount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'pending'] }, 1, 0]
          }
        },
        approvedAmount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'approved'] }, '$amount', 0]
          }
        },
        approvedCount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'approved'] }, 1, 0]
          }
        },
        paidAmount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'paid'] }, '$amount', 0]
          }
        },
        paidCount: {
          $sum: {
            $cond: [{ $eq: ['$status', 'paid'] }, 1, 0]
          }
        }
      }
    }
  ]);

  return stats[0] || {
    totalAmount: 0,
    totalCount: 0,
    pendingAmount: 0,
    pendingCount: 0,
    approvedAmount: 0,
    approvedCount: 0,
    paidAmount: 0,
    paidCount: 0
  };
};

// Static method to get expenses by category
expenseSchema.statics.getExpensesByCategory = async function(companyId, filters = {}) {
  const matchStage = { companyId };
  
  if (filters.startDate) matchStage.date = { $gte: new Date(filters.startDate) };
  if (filters.endDate) {
    if (matchStage.date) {
      matchStage.date.$lte = new Date(filters.endDate);
    } else {
      matchStage.date = { $lte: new Date(filters.endDate) };
    }
  }

  return await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: '$category',
        totalAmount: { $sum: '$amount' },
        count: { $sum: 1 }
      }
    },
    { $sort: { totalAmount: -1 } }
  ]);
};

// Instance method to approve expense
expenseSchema.methods.approve = async function(approvedBy, notes = '') {
  this.status = 'approved';
  this.approvalWorkflow.approvedBy = approvedBy;
  this.approvalWorkflow.approvedAt = new Date();
  this.notes = notes;
  await this.save();
};

// Instance method to reject expense
expenseSchema.methods.reject = async function(rejectedBy, reason) {
  this.status = 'rejected';
  this.approvalWorkflow.rejectedBy = rejectedBy;
  this.approvalWorkflow.rejectedAt = new Date();
  this.approvalWorkflow.rejectionReason = reason;
  await this.save();
};

// Instance method to mark as paid
expenseSchema.methods.markAsPaid = async function(paidBy) {
  this.status = 'paid';
  this.approvalWorkflow.paidBy = paidBy;
  this.approvalWorkflow.paidAt = new Date();
  await this.save();
};

module.exports = mongoose.model('Expense', expenseSchema); 