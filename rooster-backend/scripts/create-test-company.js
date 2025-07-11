require('dotenv').config();
const mongoose = require('mongoose');
const Company = require('../models/Company');
const AdminSettings = require('../models/AdminSettings');
const BreakType = require('../models/BreakType');

// Always use sns-rooster for local development
const LOCAL_DB_URI = 'mongodb://localhost:27017/sns-rooster';
const DB_URI = process.env.MONGODB_URI && !process.env.MONGODB_URI.includes('localhost')
  ? process.env.MONGODB_URI
  : LOCAL_DB_URI;

async function createTestCompany() {
  try {
    console.log('Connecting to:', DB_URI);
    await mongoose.connect(DB_URI);
    console.log('Connected to MongoDB');

    // Check if company already exists
    const existingCompany = await Company.findOne({ domain: 'snsrooster.com' });
    if (existingCompany) {
      console.log('Company with domain snsrooster.com already exists');
      console.log('Company ID:', existingCompany._id);
      console.log('Company Name:', existingCompany.name);
      console.log('Status:', existingCompany.status);
      process.exit(0);
    }

    // Create test company
    const testCompany = new Company({
      name: 'SNS Rooster Test Company',
      domain: 'snsrooster.com',
      subdomain: 'snsrooster',
      adminEmail: 'admin@snsrooster.com',
      contactPhone: '+1-555-0123',
      address: {
        street: '123 Test Street',
        city: 'Test City',
        state: 'Test State',
        postalCode: '12345',
        country: 'United States'
      },
      subscriptionPlan: 'professional',
      billingCycle: 'monthly',
      nextBillingDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
      trialEndDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 14 days trial
      features: {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: true,
        documentManagement: true,
        notifications: true,
        customBranding: true,
        apiAccess: true,
        multiLocation: false,
        advancedReporting: true,
        timeTracking: true,
        expenseManagement: false,
        performanceReviews: false,
        trainingManagement: false
      },
      limits: {
        maxEmployees: 200,
        maxStorageGB: 20,
        retentionDays: 730,
        maxApiCallsPerDay: 5000,
        maxLocations: 2
      },
      settings: {
        timezone: 'America/New_York',
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
        companyName: 'SNS Rooster Test Company',
        tagline: 'Innovative Workforce Management'
      },
      integrations: {
        slack: {
          enabled: false,
          webhook: '',
          channel: ''
        },
        email: {
          provider: 'resend',
          apiKey: process.env.RESEND_API_KEY || '',
          fromEmail: 'noreply@snsrooster.com'
        },
        calendar: {
          type: 'none',
          credentials: {}
        }
      },
      status: 'trial'
    });

    await testCompany.save();
    console.log('✅ Test company created successfully!');
    console.log('Company ID:', testCompany._id);
    console.log('Company Name:', testCompany.name);
    console.log('Domain:', testCompany.domain);
    console.log('Subdomain:', testCompany.subdomain);
    console.log('Admin Email:', testCompany.adminEmail);
    console.log('Status:', testCompany.status);
    console.log('Subscription Plan:', testCompany.subscriptionPlan);
    console.log('Trial End Date:', testCompany.trialEndDate);

    // Create default admin settings for the company
    console.log('\n📋 Creating default admin settings...');
    
    // Check if admin settings already exist for this company
    const existingAdminSettings = await AdminSettings.findOne({ companyId: testCompany._id });
    if (existingAdminSettings) {
      console.log('✅ Admin settings already exist for this company');
    } else {
      const adminSettings = new AdminSettings({
        companyId: testCompany._id,
        educationSectionEnabled: true,
        certificatesSectionEnabled: true,
        notificationsEnabled: true,
        darkModeEnabled: false,
        maxFileUploadSize: 10 * 1024 * 1024, // 10MB
        allowedFileTypes: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
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
          defaultHourlyRate: 15.00
        },
        companyInfo: {
          name: 'SNS Rooster Test Company',
          legalName: 'SNS Rooster Test Company LLC',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          postalCode: '12345',
          country: 'United States',
          phone: '+1-555-0123',
          email: 'admin@snsrooster.com',
          website: 'https://snsrooster.com',
          taxId: '12-3456789',
          registrationNumber: 'TEST123456',
          logoUrl: '',
          description: 'A test company for SNS Rooster application',
          industry: 'Technology',
          establishedYear: 2024,
          employeeCount: '11-50'
        },
        requiredProfileFields: [
          'firstName',
          'lastName',
          'email',
          'phone',
          'address',
          'emergencyContact',
          'emergencyPhone',
          'emergencyRelationship'
        ]
      });

      await adminSettings.save();
      console.log('✅ Admin settings created successfully!');
    }

    // Create default break types for the company
    console.log('\n☕ Creating default break types...');
    
    // Check if break types already exist for this company
    const existingBreakTypes = await BreakType.find({ companyId: testCompany._id });
    if (existingBreakTypes.length > 0) {
      console.log(`✅ ${existingBreakTypes.length} break types already exist for this company`);
    } else {
      const defaultBreakTypes = [
        {
          companyId: testCompany._id,
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
          companyId: testCompany._id,
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
          companyId: testCompany._id,
          name: 'personal',
          displayName: 'Personal Break',
          description: 'Personal time off',
          color: '#9C27B0',
          icon: 'person',
          minDuration: 5,
          maxDuration: 30,
          dailyLimit: 2,
          weeklyLimit: 10,
          requiresApproval: false,
          isPaid: false,
          isActive: true,
          priority: 3
        },
        {
          companyId: testCompany._id,
          name: 'meeting',
          displayName: 'Meeting Break',
          description: 'Break for meetings',
          color: '#2196F3',
          icon: 'meeting_room',
          minDuration: 15,
          maxDuration: 120,
          dailyLimit: 5,
          weeklyLimit: 20,
          requiresApproval: true,
          isPaid: true,
          isActive: true,
          priority: 4
        }
      ];

      for (const breakTypeData of defaultBreakTypes) {
        try {
          const breakType = new BreakType(breakTypeData);
          await breakType.save();
        } catch (error) {
          if (error.code === 11000) {
            console.log(`⚠️ Break type '${breakTypeData.name}' already exists, skipping...`);
          } else {
            throw error;
          }
        }
      }
      console.log('✅ Default break types created successfully!');
    }

    console.log('\n🎉 Test company setup completed successfully!');
    console.log('\n📝 Summary:');
    console.log('- Company created with domain: snsrooster.com');
    console.log('- Admin settings configured');
    console.log('- Default break types created');
    console.log('- Company is in trial status');
    console.log('\n🔗 You can now test the application with this company context');

  } catch (error) {
    console.error('❌ Error creating test company:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

createTestCompany(); 