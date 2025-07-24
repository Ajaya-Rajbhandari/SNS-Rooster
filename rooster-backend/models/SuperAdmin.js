const mongoose = require('mongoose');

const superAdminSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  permissions: {
    manageCompanies: {
      type: Boolean,
      default: true
    },
    manageSubscriptions: {
      type: Boolean,
      default: true
    },
    manageFeatures: {
      type: Boolean,
      default: true
    },
    manageUsers: {
      type: Boolean,
      default: true
    },
    viewAnalytics: {
      type: Boolean,
      default: true
    },
    manageBilling: {
      type: Boolean,
      default: true
    },
    systemSettings: {
      type: Boolean,
      default: true
    }
  },
  lastActivity: {
    type: Date,
    default: Date.now
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Update last activity on any operation
superAdminSchema.pre('save', function(next) {
  this.lastActivity = new Date();
  next();
});

// Static method to check if user is super admin
superAdminSchema.statics.isSuperAdmin = async function(userId) {
  const superAdmin = await this.findOne({ userId, isActive: true });
  return superAdmin !== null;
};

// Static method to get super admin permissions
superAdminSchema.statics.getPermissions = async function(userId) {
  const superAdmin = await this.findOne({ userId, isActive: true });
  return superAdmin ? superAdmin.permissions : null;
};

module.exports = mongoose.model('SuperAdmin', superAdminSchema); 