const mongoose = require('mongoose');

const performanceReviewTemplateSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  categories: [{
    name: {
      type: String,
      required: true
    },
    description: String,
    weight: {
      type: Number,
      min: 1,
      max: 5,
      default: 1
    },
    criteria: [{
      name: String,
      description: String,
      maxScore: {
        type: Number,
        min: 1,
        max: 5,
        default: 5
      }
    }]
  }],
  goals: [{
    type: String
  }],
  questions: [{
    question: {
      type: String,
      required: true
    },
    type: {
      type: String,
      enum: ['text', 'rating', 'multiple_choice'],
      default: 'text'
    },
    options: [String], // For multiple choice questions
    required: {
      type: Boolean,
      default: false
    }
  }],
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
performanceReviewTemplateSchema.index({ companyId: 1 });
performanceReviewTemplateSchema.index({ isDefault: 1 });

// Static method to get default templates
performanceReviewTemplateSchema.statics.getDefaultTemplates = function() {
  return [
    {
      name: 'Standard Annual Review',
      description: 'Comprehensive annual performance review template',
      isDefault: true,
      categories: [
        {
          name: 'Communication',
          description: 'Ability to communicate effectively',
          weight: 1,
          criteria: [
            { name: 'Verbal Communication', description: 'Clear and effective verbal communication', maxScore: 5 },
            { name: 'Written Communication', description: 'Clear and professional written communication', maxScore: 5 },
            { name: 'Active Listening', description: 'Demonstrates active listening skills', maxScore: 5 }
          ]
        },
        {
          name: 'Teamwork',
          description: 'Collaboration and team contribution',
          weight: 1,
          criteria: [
            { name: 'Collaboration', description: 'Works well with team members', maxScore: 5 },
            { name: 'Support', description: 'Supports and helps colleagues', maxScore: 5 },
            { name: 'Conflict Resolution', description: 'Handles conflicts constructively', maxScore: 5 }
          ]
        },
        {
          name: 'Technical Skills',
          description: 'Job-specific technical competencies',
          weight: 2,
          criteria: [
            { name: 'Technical Knowledge', description: 'Demonstrates strong technical knowledge', maxScore: 5 },
            { name: 'Problem Solving', description: 'Effectively solves technical problems', maxScore: 5 },
            { name: 'Innovation', description: 'Shows innovative thinking', maxScore: 5 }
          ]
        },
        {
          name: 'Leadership',
          description: 'Leadership and initiative',
          weight: 1,
          criteria: [
            { name: 'Initiative', description: 'Takes initiative without being asked', maxScore: 5 },
            { name: 'Decision Making', description: 'Makes sound decisions', maxScore: 5 },
            { name: 'Mentoring', description: 'Helps develop others', maxScore: 5 }
          ]
        }
      ],
      goals: [
        'Improve technical skills in specific areas',
        'Enhance communication with stakeholders',
        'Take on more leadership responsibilities',
        'Contribute to team knowledge sharing'
      ],
      questions: [
        {
          question: 'What are your key achievements this year?',
          type: 'text',
          required: true
        },
        {
          question: 'What challenges did you face and how did you overcome them?',
          type: 'text',
          required: true
        },
        {
          question: 'What are your career goals for the next year?',
          type: 'text',
          required: true
        },
        {
          question: 'How would you rate your overall job satisfaction?',
          type: 'rating',
          required: false
        }
      ]
    },
    {
      name: 'Quarterly Review',
      description: 'Focused quarterly performance check-in',
      isDefault: true,
      categories: [
        {
          name: 'Goal Achievement',
          description: 'Progress on quarterly goals',
          weight: 2,
          criteria: [
            { name: 'Goal Completion', description: 'Achieved set quarterly goals', maxScore: 5 },
            { name: 'Progress', description: 'Made significant progress toward goals', maxScore: 5 }
          ]
        },
        {
          name: 'Performance',
          description: 'Overall performance metrics',
          weight: 1,
          criteria: [
            { name: 'Quality', description: 'Maintains high quality standards', maxScore: 5 },
            { name: 'Efficiency', description: 'Works efficiently and meets deadlines', maxScore: 5 }
          ]
        }
      ],
      goals: [
        'Complete quarterly objectives',
        'Improve specific performance areas',
        'Prepare for next quarter goals'
      ],
      questions: [
        {
          question: 'What progress have you made on your quarterly goals?',
          type: 'text',
          required: true
        },
        {
          question: 'What obstacles are preventing you from achieving your goals?',
          type: 'text',
          required: false
        },
        {
          question: 'What support do you need to succeed?',
          type: 'text',
          required: false
        }
      ]
    }
  ];
};

module.exports = mongoose.model('PerformanceReviewTemplate', performanceReviewTemplateSchema); 