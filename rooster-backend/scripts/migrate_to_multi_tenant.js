const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const User = require('../models/User');
const Employee = require('../models/Employee');
const Attendance = require('../models/Attendance');
const Payroll = require('../models/Payroll');
const Leave = require('../models/Leave');
const BreakType = require('../models/BreakType');

async function migrateToMultiTenant() {
  try {
    console.log('🚀 Starting multi-tenant migration...');
    
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Check if default company already exists
    let defaultCompany = await Company.findOne({ domain: 'default' });
    
    if (!defaultCompany) {
      console.log('📝 Creating default company...');
      
      // Create default company for existing data
      defaultCompany = await Company.create({
        name: 'Default Company',
        domain: 'default',
        subdomain: 'default',
        adminEmail: 'admin@default.com',
        status: 'active',
        subscriptionPlan: 'enterprise', // Give full access to existing data
        features: {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: true,
          documentManagement: true,
          notifications: true,
          customBranding: true,
          apiAccess: true,
          multiLocation: true,
          advancedReporting: true,
          timeTracking: true,
          expenseManagement: true,
          performanceReviews: true,
          trainingManagement: true
        },
        limits: {
          maxEmployees: 1000,
          maxStorageGB: 100,
          retentionDays: 365,
          maxApiCallsPerDay: 10000,
          maxLocations: 10
        }
      });
      
      console.log('✅ Default company created:', defaultCompany._id);
    } else {
      console.log('✅ Default company already exists:', defaultCompany._id);
    }
    
    const companyId = defaultCompany._id;
    
    // Update Users
    console.log('👥 Updating Users...');
    const userResult = await User.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${userResult.modifiedCount} users`);
    
    // Update Employees
    console.log('👨‍💼 Updating Employees...');
    const employeeResult = await Employee.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${employeeResult.modifiedCount} employees`);
    
    // Update Attendance records
    console.log('⏰ Updating Attendance records...');
    const attendanceResult = await Attendance.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${attendanceResult.modifiedCount} attendance records`);
    
    // Update Payroll records
    console.log('💰 Updating Payroll records...');
    const payrollResult = await Payroll.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${payrollResult.modifiedCount} payroll records`);
    
    // Update Leave records
    console.log('🏖️ Updating Leave records...');
    const leaveResult = await Leave.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${leaveResult.modifiedCount} leave records`);
    
    // Update BreakTypes
    console.log('☕ Updating BreakTypes...');
    const breakTypeResult = await BreakType.updateMany(
      { companyId: { $exists: false } },
      { $set: { companyId: companyId } }
    );
    console.log(`✅ Updated ${breakTypeResult.modifiedCount} break types`);
    
    // Create default break types if none exist
    const existingBreakTypes = await BreakType.countDocuments({ companyId: companyId });
    if (existingBreakTypes === 0) {
      console.log('☕ Creating default break types...');
      await BreakType.insertMany([
        {
          companyId: companyId,
          name: 'Lunch Break',
          displayName: 'Lunch Break',
          description: 'Standard lunch break',
          color: '#4CAF50',
          icon: 'restaurant',
          minDuration: 30,
          maxDuration: 60,
          dailyLimit: 1,
          priority: 1
        },
        {
          companyId: companyId,
          name: 'Coffee Break',
          displayName: 'Coffee Break',
          description: 'Short coffee break',
          color: '#FF9800',
          icon: 'coffee',
          minDuration: 5,
          maxDuration: 15,
          dailyLimit: 3,
          priority: 2
        },
        {
          companyId: companyId,
          name: 'Personal Break',
          displayName: 'Personal Break',
          description: 'Personal time off',
          color: '#9C27B0',
          icon: 'person',
          minDuration: 5,
          maxDuration: 30,
          dailyLimit: 2,
          priority: 3
        }
      ]);
      console.log('✅ Default break types created');
    }
    
    console.log('🎉 Migration completed successfully!');
    console.log('📊 Summary:');
    console.log(`   - Default Company ID: ${companyId}`);
    console.log(`   - Users updated: ${userResult.modifiedCount}`);
    console.log(`   - Employees updated: ${employeeResult.modifiedCount}`);
    console.log(`   - Attendance records updated: ${attendanceResult.modifiedCount}`);
    console.log(`   - Payroll records updated: ${payrollResult.modifiedCount}`);
    console.log(`   - Leave records updated: ${leaveResult.modifiedCount}`);
    console.log(`   - Break types updated: ${breakTypeResult.modifiedCount}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run migration if this script is executed directly
if (require.main === module) {
  migrateToMultiTenant();
}

module.exports = migrateToMultiTenant; 