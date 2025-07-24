const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  address: {
    street: {
      type: String,
      required: true,
      trim: true
    },
    city: {
      type: String,
      required: true,
      trim: true
    },
    state: {
      type: String,
      required: true,
      trim: true
    },
    postalCode: {
      type: String,
      required: true,
      trim: true
    },
    country: {
      type: String,
      required: true,
      trim: true
    }
  },
  coordinates: {
    latitude: {
      type: Number,
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180
    }
  },
  contactInfo: {
    phone: {
      type: String,
      trim: true
    },
    email: {
      type: String,
      trim: true,
      lowercase: true
    }
  },
  settings: {
    timezone: {
      type: String,
      default: 'UTC'
    },
    workingHours: {
      start: {
        type: String,
        default: '09:00'
      },
      end: {
        type: String,
        default: '17:00'
      }
    },
    workingDays: [{
      type: String,
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
    }],
    attendanceGracePeriod: {
      type: Number,
      default: 15, // minutes
      min: 0,
      max: 60
    },
    geofenceRadius: {
      type: Number,
      default: 100, // meters
      min: 10,
      max: 1000
    }
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'maintenance', 'deleted'],
    default: 'active'
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  description: {
    type: String,
    trim: true
  },
  capacity: {
    type: Number,
    min: 1,
    default: 50
  },
  currentEmployees: {
    type: Number,
    default: 0,
    min: 0
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  assignedManager: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Ensure only one default location per company
locationSchema.pre('save', async function(next) {
  if (this.isDefault) {
    await this.constructor.updateMany(
      { 
        companyId: this.companyId,
        _id: { $ne: this._id }
      },
      { isDefault: false }
    );
  }
  next();
});

// Update employee count when employees are assigned/unassigned
locationSchema.methods.updateEmployeeCount = async function() {
  const Employee = mongoose.model('Employee');
  const count = await Employee.countDocuments({
    companyId: this.companyId,
    locationId: this._id,
    status: 'active'
  });
  
  this.currentEmployees = count;
  await this.save();
};

// Get location with employee count and active users
locationSchema.statics.getLocationWithEmployeeCount = async function(locationId) {
  const Employee = mongoose.model('Employee');
  const Attendance = mongoose.model('Attendance');
  const location = await this.findById(locationId);
  
  if (location) {
    // Count assigned employees
    const employeeCount = await Employee.countDocuments({
      companyId: location.companyId,
      locationId: location._id,
      isActive: true
    });
    
    // Get today's date at UTC midnight
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0, 0, 0, 0
      )
    );
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(today.getUTCDate() + 1);
    
    // Count active users (employees who are clocked in today at this location)
    const activeUsersCount = await Attendance.countDocuments({
      companyId: location.companyId,
      date: { $gte: today, $lt: tomorrow },
      'locationValidation.locationName': location.name,
      checkOutTime: null // Still clocked in (no checkout time)
    });
    
    location.currentEmployees = employeeCount;
    location.activeUsers = activeUsersCount;
  }
  
  return location;
};

// Get all locations for a company with employee counts and active users
locationSchema.statics.getCompanyLocations = async function(companyId) {
  const Employee = mongoose.model('Employee');
  const Attendance = mongoose.model('Attendance');
  const locations = await this.find({ companyId, status: { $ne: 'deleted' } });
  
  // Get today's date at UTC midnight
  const now = new Date();
  const today = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
      0, 0, 0, 0
    )
  );
  const tomorrow = new Date(today);
  tomorrow.setUTCDate(today.getUTCDate() + 1);
  
  for (const location of locations) {
    // Count assigned employees
    const employeeCount = await Employee.countDocuments({
      companyId: location.companyId,
      locationId: location._id,
      isActive: true
    });
    
    // Count active users (employees who are clocked in today at this location)
    const activeUsersCount = await Attendance.countDocuments({
      companyId: location.companyId,
      date: { $gte: today, $lt: tomorrow },
      'locationValidation.locationName': location.name,
      checkOutTime: null // Still clocked in (no checkout time)
    });
    
    location.currentEmployees = employeeCount;
    location.activeUsers = activeUsersCount;
  }
  
  return locations;
};

module.exports = mongoose.model('Location', locationSchema); 