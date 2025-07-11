const mongoose = require('mongoose');
const Company = require('../models/Company');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Attendance = require('../models/Attendance');
const Payroll = require('../models/Payroll');
const Leave = require('../models/Leave');
const Notification = require('../models/Notification');
const FCMToken = require('../models/FCMToken');
const BreakType = require('../models/BreakType');
const AdminSettings = require('../models/AdminSettings');

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/rooster');
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Create default company
const createDefaultCompany = async () => {
  try {
    // Check if default company already exists
    const existingCompany = await Company.findOne({ domain: 'default' });
    if (existingCompany) {
      console.log('Default company already exists:', existingCompany._id);
      return existingCompany;
    }

    const defaultCompany = new Company({
      name: 'Default Company',
      domain: 'default',
      subdomain: 'default',
      adminEmail: 'admin@default.com',
      status: 'active',
      features: {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: false,
        documentManagement: true,
        notifications: true,
        customBranding: false,
        apiAccess: false,
        multiLocation: false,
        advancedReporting: false,
        timeTracking: true,
        expenseManagement: false,
        performanceReviews: false,
        trainingManagement: false
      },
      limits: {
        maxEmployees: 100,
        maxStorageGB: 10,
        retentionDays: 365,
        maxApiCallsPerDay: 2000,
        maxLocations: 1
      },
      settings: {
        timezone: 'UTC',
        currency: 'USD',
        dateFormat: 'MM/DD/YYYY',
        timeFormat: '12',
        workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        workingHours: {
          start: '09:00',
          end: '17:00'
        },
        attendanceGracePeriod: 15,
        overtimeThreshold: 8,
        leaveApprovalRequired: true,
        autoApproveLeave: false
      },
      branding: {
        primaryColor: '#1976D2',
        secondaryColor: '#424242',
        companyName: 'Default Company'
      }
    });

    await defaultCompany.save();
    console.log('Default company created:', defaultCompany._id);
    return defaultCompany;
  } catch (error) {
    console.error('Error creating default company:', error);
    throw error;
  }
};

// Update existing records with companyId
const updateRecordsWithCompanyId = async (companyId) => {
  try {
    console.log('Starting migration with company ID:', companyId);

    // Update Users
    const userResult = await User.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${userResult.modifiedCount} users`);

    // Update Employees
    const employeeResult = await Employee.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${employeeResult.modifiedCount} employees`);

    // Update Attendance records
    const attendanceResult = await Attendance.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${attendanceResult.modifiedCount} attendance records`);

    // Update Payroll records
    const payrollResult = await Payroll.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${payrollResult.modifiedCount} payroll records`);

    // Update Leave records
    const leaveResult = await Leave.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${leaveResult.modifiedCount} leave records`);

    // Update Notification records
    const notificationResult = await Notification.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${notificationResult.modifiedCount} notification records`);

    // Update FCM Token records
    const fcmTokenResult = await FCMToken.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${fcmTokenResult.modifiedCount} FCM token records`);

    // Update BreakType records
    const breakTypeResult = await BreakType.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${breakTypeResult.modifiedCount} break type records`);

    // Update AdminSettings records
    const adminSettingsResult = await AdminSettings.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`Updated ${adminSettingsResult.modifiedCount} admin settings records`);

    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Error updating records:', error);
    throw error;
  }
};

// Create default break types for the company
const createDefaultBreakTypes = async (companyId) => {
  try {
    const existingBreakTypes = await BreakType.find({ companyId });
    if (existingBreakTypes.length > 0) {
      console.log('Break types already exist for company');
      return;
    }

    const defaultBreakTypes = [
      {
        companyId,
        name: 'lunch',
        displayName: 'Lunch Break',
        description: 'Standard lunch break',
        color: '#4CAF50',
        icon: 'restaurant',
        minDuration: 30,
        maxDuration: 60,
        dailyLimit: 1,
        weeklyLimit: 5,
        requiresApproval: false,
        isPaid: false,
        isActive: true,
        priority: 1
      },
      {
        companyId,
        name: 'coffee',
        displayName: 'Coffee Break',
        description: 'Short coffee break',
        color: '#FF9800',
        icon: 'free_breakfast',
        minDuration: 5,
        maxDuration: 15,
        dailyLimit: 3,
        weeklyLimit: 15,
        requiresApproval: false,
        isPaid: true,
        isActive: true,
        priority: 2
      },
      {
        companyId,
        name: 'personal',
        displayName: 'Personal Break',
        description: 'Personal time off',
        color: '#9C27B0',
        icon: 'person',
        minDuration: 5,
        maxDuration: 30,
        dailyLimit: 2,
        weeklyLimit: 10,
        requiresApproval: true,
        isPaid: false,
        isActive: true,
        priority: 3
      }
    ];

    await BreakType.insertMany(defaultBreakTypes);
    console.log('Default break types created');
  } catch (error) {
    console.error('Error creating default break types:', error);
    throw error;
  }
};

// Create default admin settings for the company
const createDefaultAdminSettings = async (companyId) => {
  try {
    const existingSettings = await AdminSettings.findOne({ companyId });
    if (existingSettings) {
      console.log('Admin settings already exist for company');
      return;
    }

    const defaultSettings = new AdminSettings({
      companyId,
      educationSectionEnabled: true,
      certificatesSectionEnabled: true,
      notificationsEnabled: true,
      darkModeEnabled: false,
      maxFileUploadSize: 5 * 1024 * 1024, // 5MB
      allowedFileTypes: ['pdf', 'jpg', 'jpeg', 'png'],
      payrollCycle: {
        frequency: 'Monthly',
        cutoffDay: 25,
        payDay: 30,
        payDay1: 15,
        payWeekday: 5,
        payOffset: 0,
        overtimeEnabled: true,
        overtimeMultiplier: 1.5,
        autoGenerate: true,
        notifyCycleClose: true,
        notifyPayslip: true,
        defaultHourlyRate: 0
      },
      taxSettings: {
        enabled: false,
        incomeTaxEnabled: false,
        socialSecurityEnabled: false,
        incomeTaxBrackets: [],
        socialSecurityRate: 0,
        socialSecurityCap: null,
        flatTaxRates: [],
        taxCalculationMethod: 'percentage',
        currency: 'USD',
        currencySymbol: '$'
      },
      companyInfo: {
        name: 'Default Company',
        legalName: '',
        address: '',
        city: '',
        state: '',
        postalCode: '',
        country: 'United States',
        phone: '',
        email: 'admin@default.com',
        website: '',
        registrationNumber: '',
        taxId: '',
        industry: '',
        establishedYear: null,
        employeeCount: '1-10',
        description: ''
      }
    });

    await defaultSettings.save();
    console.log('Default admin settings created');
  } catch (error) {
    console.error('Error creating default admin settings:', error);
    throw error;
  }
};

// Main migration function
const runMigration = async () => {
  try {
    console.log('Starting multi-tenant migration...');
    
    await connectDB();
    
    console.log('Connecting to:', process.env.MONGODB_URI || 'mongodb://localhost:27017/rooster');
    
    // Create default company
    const defaultCompany = await createDefaultCompany();
    
    // Update all existing records with companyId
    await updateRecordsWithCompanyId(defaultCompany._id);
    
    // Create default break types
    await createDefaultBreakTypes(defaultCompany._id);
    
    // Create default admin settings
    await createDefaultAdminSettings(defaultCompany._id);
    
    console.log('Migration completed successfully!');
    console.log('Default company ID:', defaultCompany._id);
    console.log('Default company domain:', defaultCompany.domain);
    
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
};

// Run migration if this script is executed directly
if (require.main === module) {
  runMigration();
}

module.exports = {
  runMigration,
  createDefaultCompany,
  updateRecordsWithCompanyId
}; 