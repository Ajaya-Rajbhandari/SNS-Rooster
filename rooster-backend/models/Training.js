const mongoose = require('mongoose');

const trainingSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
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
  category: {
    type: String,
    required: true,
    enum: [
      'technical',
      'soft_skills',
      'compliance',
      'safety',
      'leadership',
      'product',
      'process',
      'certification',
      'onboarding',
      'other'
    ]
  },
  type: {
    type: String,
    enum: ['online', 'in_person', 'hybrid', 'self_paced', 'workshop', 'seminar'],
    required: true
  },
  format: {
    type: String,
    enum: ['video', 'document', 'interactive', 'assessment', 'mentoring', 'coaching'],
    required: true
  },
  duration: {
    hours: {
      type: Number,
      min: 0,
      default: 0
    },
    minutes: {
      type: Number,
      min: 0,
      max: 59,
      default: 0
    }
  },
  schedule: {
    startDate: {
      type: Date,
      required: true
    },
    endDate: {
      type: Date,
      required: true
    },
    sessions: [{
      date: Date,
      startTime: String,
      endTime: String,
      location: String,
      instructor: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      maxParticipants: Number,
      currentParticipants: {
        type: Number,
        default: 0
      }
    }]
  },
  instructor: {
    name: {
      type: String,
      trim: true
    },
    email: {
      type: String,
      trim: true,
      lowercase: true
    },
    phone: String,
    bio: String,
    external: {
      type: Boolean,
      default: false
    }
  },
  location: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Location'
  },
  virtualMeeting: {
    platform: String,
    url: String,
    meetingId: String,
    password: String
  },
  prerequisites: [{
    type: String,
    trim: true
  }],
  learningObjectives: [{
    type: String,
    trim: true
  }],
  materials: [{
    title: {
      type: String,
      required: true,
      trim: true
    },
    type: {
      type: String,
      enum: ['document', 'video', 'link', 'file'],
      required: true
    },
    url: String,
    filename: String,
    originalName: String,
    mimeType: String,
    size: Number,
    description: String
  }],
  assessment: {
    required: {
      type: Boolean,
      default: false
    },
    passingScore: {
      type: Number,
      min: 0,
      max: 100,
      default: 70
    },
    attempts: {
      type: Number,
      min: 1,
      default: 3
    },
    questions: [{
      question: {
        type: String,
        required: true
      },
      type: {
        type: String,
        enum: ['multiple_choice', 'true_false', 'short_answer', 'essay'],
        required: true
      },
      options: [String],
      correctAnswer: String,
      points: {
        type: Number,
        min: 1,
        default: 1
      }
    }]
  },
  status: {
    type: String,
    enum: ['draft', 'published', 'in_progress', 'completed', 'cancelled', 'archived'],
    default: 'draft',
    index: true
  },
  enrollment: {
    maxParticipants: {
      type: Number,
      min: 1,
      default: 50
    },
    currentParticipants: {
      type: Number,
      default: 0,
      min: 0
    },
    waitlistEnabled: {
      type: Boolean,
      default: false
    },
    autoApprove: {
      type: Boolean,
      default: true
    },
    enrollmentDeadline: Date
  },
  cost: {
    perParticipant: {
      type: Number,
      min: 0,
      default: 0
    },
    currency: {
      type: String,
      default: 'NPR',
      uppercase: true
    },
    budget: {
      type: Number,
      min: 0
    }
  },
  tags: [{
    type: String,
    trim: true
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  assignedTo: [{
    employeeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Employee'
    },
    status: {
      type: String,
      enum: ['assigned', 'enrolled', 'in_progress', 'completed', 'failed', 'dropped'],
      default: 'assigned'
    },
    enrolledAt: Date,
    completedAt: Date,
    score: {
      type: Number,
      min: 0,
      max: 100
    },
    certificate: {
      filename: String,
      url: String,
      issuedAt: Date
    },
    feedback: {
      rating: {
        type: Number,
        min: 1,
        max: 5
      },
      comments: String,
      submittedAt: Date
    }
  }],
  notifications: {
    reminderDays: [{
      type: Number,
      min: 1,
      max: 30
    }],
    completionNotification: {
      type: Boolean,
      default: true
    },
    certificateNotification: {
      type: Boolean,
      default: true
    }
  }
}, {
  timestamps: true
});

// Indexes for better query performance
trainingSchema.index({ companyId: 1, status: 1 });
trainingSchema.index({ companyId: 1, category: 1 });
trainingSchema.index({ companyId: 1, 'schedule.startDate': -1 });
trainingSchema.index({ companyId: 1, type: 1 });

// Virtual for total duration in minutes
trainingSchema.virtual('totalDurationMinutes').get(function() {
  return (this.duration.hours * 60) + this.duration.minutes;
});

// Virtual for formatted duration
trainingSchema.virtual('formattedDuration').get(function() {
  const hours = this.duration.hours;
  const minutes = this.duration.minutes;
  
  if (hours > 0 && minutes > 0) {
    return `${hours}h ${minutes}m`;
  } else if (hours > 0) {
    return `${hours}h`;
  } else if (minutes > 0) {
    return `${minutes}m`;
  }
  return 'Not specified';
});

// Virtual for enrollment status
trainingSchema.virtual('enrollmentStatus').get(function() {
  if (this.enrollment.currentParticipants >= this.enrollment.maxParticipants) {
    return 'full';
  } else if (this.enrollment.currentParticipants >= this.enrollment.maxParticipants * 0.8) {
    return 'almost_full';
  } else {
    return 'available';
  }
});

// Virtual for training progress
trainingSchema.virtual('progress').get(function() {
  const now = new Date();
  const start = this.schedule.startDate;
  const end = this.schedule.endDate;
  
  if (now < start) return 0;
  if (now > end) return 100;
  
  const total = end - start;
  const elapsed = now - start;
  return Math.round((elapsed / total) * 100);
});

// Pre-save middleware to validate dates
trainingSchema.pre('save', function(next) {
  if (this.schedule.startDate >= this.schedule.endDate) {
    return next(new Error('End date must be after start date'));
  }
  next();
});

// Static method to get training statistics
trainingSchema.statics.getTrainingStats = async function(companyId, filters = {}) {
  const matchStage = { companyId };
  
  if (filters.startDate) matchStage['schedule.startDate'] = { $gte: new Date(filters.startDate) };
  if (filters.endDate) {
    if (matchStage['schedule.startDate']) {
      matchStage['schedule.startDate'].$lte = new Date(filters.endDate);
    } else {
      matchStage['schedule.startDate'] = { $lte: new Date(filters.endDate) };
    }
  }
  if (filters.status) matchStage.status = filters.status;
  if (filters.category) matchStage.category = filters.category;

  const stats = await this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalTrainings: { $sum: 1 },
        totalParticipants: { $sum: '$enrollment.currentParticipants' },
        completedTrainings: {
          $sum: {
            $cond: [{ $eq: ['$status', 'completed'] }, 1, 0]
          }
        },
        activeTrainings: {
          $sum: {
            $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0]
          }
        },
        upcomingTrainings: {
          $sum: {
            $cond: [{ $eq: ['$status', 'published'] }, 1, 0]
          }
        },
        totalCost: { $sum: '$cost.perParticipant' }
      }
    }
  ]);

  return stats[0] || {
    totalTrainings: 0,
    totalParticipants: 0,
    completedTrainings: 0,
    activeTrainings: 0,
    upcomingTrainings: 0,
    totalCost: 0
  };
};

// Instance method to enroll employee
trainingSchema.methods.enrollEmployee = async function(employeeId) {
  const existingEnrollment = this.assignedTo.find(
    enrollment => enrollment.employeeId.toString() === employeeId.toString()
  );
  
  if (existingEnrollment) {
    throw new Error('Employee is already enrolled in this training');
  }
  
  if (this.enrollment.currentParticipants >= this.enrollment.maxParticipants) {
    throw new Error('Training is full');
  }
  
  this.assignedTo.push({
    employeeId: employeeId,
    status: 'enrolled',
    enrolledAt: new Date()
  });
  
  this.enrollment.currentParticipants += 1;
  await this.save();
};

// Instance method to complete training for employee
trainingSchema.methods.completeForEmployee = async function(employeeId, score = null) {
  const enrollment = this.assignedTo.find(
    enrollment => enrollment.employeeId.toString() === employeeId.toString()
  );
  
  if (!enrollment) {
    throw new Error('Employee is not enrolled in this training');
  }
  
  enrollment.status = 'completed';
  enrollment.completedAt = new Date();
  if (score !== null) {
    enrollment.score = score;
  }
  
  await this.save();
};

// Instance method to publish training
trainingSchema.methods.publish = async function() {
  this.status = 'published';
  await this.save();
};

// Instance method to start training
trainingSchema.methods.start = async function() {
  this.status = 'in_progress';
  await this.save();
};

// Instance method to complete training
trainingSchema.methods.complete = async function() {
  this.status = 'completed';
  await this.save();
};

module.exports = mongoose.model('Training', trainingSchema); 