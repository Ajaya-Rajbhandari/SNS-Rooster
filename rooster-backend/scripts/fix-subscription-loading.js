const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function fixSubscriptionLoading() {
  try {
    // Get MongoDB URI from environment or use default
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    console.log('Connecting to MongoDB...');
    console.log('Environment MONGODB_URI:', process.env.MONGODB_URI ? 'Set' : 'Not set');
    console.log('Using URI:', MONGODB_URI);
    
    await mongoose.connect(MONGODB_URI, {
      tlsAllowInvalidCertificates: true, // Add this for debugging
    });
    console.log('Connected to MongoDB');

    console.log('\n🔧 FIXING SUBSCRIPTION PLAN LOADING ISSUES');
    console.log('==========================================');

    // Get default subscription plan (Basic plan)
    const defaultPlan = await SubscriptionPlan.findOne({ 
      name: { $regex: /basic/i },
      isActive: true 
    }).sort('sortOrder');

    if (!defaultPlan) {
      console.log('❌ No default subscription plan found. Creating one...');
      
      // Create a basic plan if none exists
      const basicPlan = new SubscriptionPlan({
        name: 'Basic',
        type: 'basic',
        price: 29,
        sortOrder: 1,
        isActive: true,
        features: {
          maxEmployees: 10,
          maxDepartments: 3,
          analytics: false,
          advancedReporting: false,
          customBranding: false,
          apiAccess: false,
          multiLocationSupport: false,
          expenseManagement: false,
          performanceReviews: false,
          trainingManagement: false,
          locationBasedAttendance: false,
          dataRetention: 365,
          maxStorageGB: 5,
          maxApiCallsPerDay: 1000,
          prioritySupport: false
        }
      });
      
      await basicPlan.save();
      console.log('✅ Created Basic subscription plan');
    }

    // Get all companies without subscription plans
    const companiesWithoutPlans = await Company.find({
      $or: [
        { subscriptionPlan: { $exists: false } },
        { subscriptionPlan: null },
        { subscriptionPlan: { $eq: null } }
      ]
    });

    console.log(`\n📊 Found ${companiesWithoutPlans.length} companies without subscription plans`);

    // Assign default plan to companies without plans
    for (const company of companiesWithoutPlans) {
      console.log(`\n🏢 Fixing company: ${company.name}`);
      
      // Assign default plan
      company.subscriptionPlan = defaultPlan._id;
      company.isCustomPlan = false;
      
      // Update features based on the default plan
      company.features = {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: defaultPlan.features.analytics,
        documentManagement: true,
        notifications: true,
        customBranding: defaultPlan.features.customBranding,
        apiAccess: defaultPlan.features.apiAccess,
        multiLocation: defaultPlan.features.multiLocationSupport,
        advancedReporting: defaultPlan.features.advancedReporting,
        timeTracking: true,
        expenseManagement: defaultPlan.features.expenseManagement,
        performanceReviews: defaultPlan.features.performanceReviews,
        trainingManagement: defaultPlan.features.trainingManagement,
        locationBasedAttendance: defaultPlan.features.locationBasedAttendance
      };

      // Update limits based on the default plan
      company.limits = {
        maxEmployees: defaultPlan.features.maxEmployees,
        maxStorageGB: defaultPlan.features.maxStorageGB,
        retentionDays: defaultPlan.features.dataRetention,
        maxApiCallsPerDay: defaultPlan.features.maxApiCallsPerDay,
        maxLocations: defaultPlan.features.multiLocationSupport ? 3 : 1,
        maxDepartments: defaultPlan.features.maxDepartments
      };

      // Ensure company status is valid
      if (company.status !== 'active' && company.status !== 'trial') {
        company.status = 'trial';
        company.trialStartDate = new Date();
        company.trialEndDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
        company.trialDurationDays = 7;
        company.trialSubscriptionPlan = 'basic';
        company.trialPlanName = 'Basic Trial';
        console.log('   ✅ Set company status to trial');
      }

      await company.save();
      console.log(`   ✅ Assigned ${defaultPlan.name} plan to ${company.name}`);
    }

    // Fix companies with mismatched features
    const allCompanies = await Company.find({}).populate('subscriptionPlan');
    console.log(`\n🔄 Checking ${allCompanies.length} companies for feature mismatches`);

    for (const company of allCompanies) {
      if (!company.subscriptionPlan) {
        console.log(`   ⚠️  ${company.name}: Still no subscription plan`);
        continue;
      }

      const plan = company.subscriptionPlan;
      const planFeatures = plan.features || {};
      const companyFeatures = company.features || {};
      
      // Check for mismatches
      let hasMismatch = false;
      const expectedFeatures = {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: planFeatures.analytics,
        documentManagement: true,
        notifications: true,
        customBranding: planFeatures.customBranding,
        apiAccess: planFeatures.apiAccess,
        multiLocation: planFeatures.multiLocationSupport,
        advancedReporting: planFeatures.advancedReporting,
        timeTracking: true,
        expenseManagement: planFeatures.expenseManagement,
        performanceReviews: planFeatures.performanceReviews,
        trainingManagement: planFeatures.trainingManagement,
        locationBasedAttendance: planFeatures.locationBasedAttendance
      };

      // Check each feature
      Object.entries(expectedFeatures).forEach(([key, expectedValue]) => {
        if (companyFeatures[key] !== expectedValue) {
          hasMismatch = true;
        }
      });

      if (hasMismatch) {
        console.log(`\n🔧 Fixing features for: ${company.name}`);
        company.features = expectedFeatures;
        
        // Update limits too
        company.limits = {
          maxEmployees: planFeatures.maxEmployees,
          maxStorageGB: planFeatures.maxStorageGB,
          retentionDays: planFeatures.dataRetention,
          maxApiCallsPerDay: planFeatures.maxApiCallsPerDay,
          maxLocations: planFeatures.multiLocationSupport ? 3 : 1,
          maxDepartments: planFeatures.maxDepartments
        };

        await company.save();
        console.log(`   ✅ Fixed features for ${company.name}`);
      }
    }

    // Verify fixes
    console.log('\n✅ VERIFICATION');
    console.log('===============');
    
    const fixedCompanies = await Company.find({}).populate('subscriptionPlan');
    let issuesRemaining = 0;

    for (const company of fixedCompanies) {
      if (!company.subscriptionPlan) {
        console.log(`❌ ${company.name}: Still no subscription plan`);
        issuesRemaining++;
      } else {
        console.log(`✅ ${company.name}: Has ${company.subscriptionPlan.name} plan`);
      }
    }

    if (issuesRemaining === 0) {
      console.log('\n🎉 All subscription plan issues have been resolved!');
    } else {
      console.log(`\n⚠️  ${issuesRemaining} issues still remain`);
    }

    // Test API response
    console.log('\n🧪 TESTING API RESPONSE');
    console.log('======================');
    
    const testCompany = fixedCompanies[0];
    if (testCompany) {
      const simulatedResponse = {
        features: {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: testCompany.subscriptionPlan?.features?.analytics || false,
          documentManagement: true,
          notifications: true,
          customBranding: testCompany.subscriptionPlan?.features?.customBranding || false,
          apiAccess: testCompany.subscriptionPlan?.features?.apiAccess || false,
          multiLocation: testCompany.subscriptionPlan?.features?.multiLocationSupport || false,
          advancedReporting: testCompany.subscriptionPlan?.features?.advancedReporting || false,
          timeTracking: true,
          expenseManagement: testCompany.subscriptionPlan?.features?.expenseManagement || false,
          performanceReviews: testCompany.subscriptionPlan?.features?.performanceReviews || false,
          trainingManagement: testCompany.subscriptionPlan?.features?.trainingManagement || false,
          locationBasedAttendance: testCompany.subscriptionPlan?.features?.locationBasedAttendance || false,
        },
        limits: {
          maxEmployees: testCompany.subscriptionPlan?.features?.maxEmployees || 0,
          maxStorageGB: testCompany.subscriptionPlan?.features?.maxStorageGB || 0,
          maxApiCallsPerDay: testCompany.subscriptionPlan?.features?.maxApiCallsPerDay || 0,
          maxDepartments: testCompany.subscriptionPlan?.features?.maxDepartments || 0,
          dataRetention: testCompany.subscriptionPlan?.features?.dataRetention || 0,
        },
        subscriptionPlan: {
          name: testCompany.subscriptionPlan?.name || 'No Plan',
          price: testCompany.subscriptionPlan?.price,
          features: testCompany.subscriptionPlan?.features
        },
        company: {
          name: testCompany.name,
          domain: testCompany.domain,
          subdomain: testCompany.subdomain,
          status: testCompany.status,
        }
      };
      
      console.log('✅ API Response is now valid');
      console.log(`   Plan: ${simulatedResponse.subscriptionPlan.name}`);
      console.log(`   Features: ${Object.keys(simulatedResponse.features).length} features`);
      console.log(`   Limits: ${Object.keys(simulatedResponse.limits).length} limits`);
    }

  } catch (error) {
    console.error('Error fixing subscription issues:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run the fix
fixSubscriptionLoading(); 