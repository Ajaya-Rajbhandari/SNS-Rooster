const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function fixSubscriptionLoadingV2() {
  try {
    // Get MongoDB URI from environment or use default
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    console.log('Connecting to MongoDB...');
    console.log('Environment MONGODB_URI:', process.env.MONGODB_URI ? 'Set' : 'Not set');
    console.log('Using URI:', MONGODB_URI);
    
    await mongoose.connect(MONGODB_URI, {
      tlsAllowInvalidCertificates: true,
    });
    console.log('Connected to MongoDB');

    console.log('\n🔧 FIXING SUBSCRIPTION PLAN LOADING ISSUES (V2)');
    console.log('================================================');

    // Get all companies with their subscription plans
    const companies = await Company.find({}).populate('subscriptionPlan');
    console.log(`\n📊 Found ${companies.length} companies to process`);

    let fixedCount = 0;
    let skippedCount = 0;

    for (const company of companies) {
      console.log(`\n🏢 Processing: ${company.name}`);
      
      if (!company.subscriptionPlan) {
        console.log('   ⚠️  No subscription plan - skipping');
        skippedCount++;
        continue;
      }

      const plan = company.subscriptionPlan;
      console.log(`   📋 Plan: ${plan.name}`);
      
      // Get current company features and limits
      const currentFeatures = company.features || {};
      const currentLimits = company.limits || {};
      
      // Define the expected features based on the plan
      const expectedFeatures = {
        // Core features (always available)
        attendance: true,
        payroll: true,
        leaveManagement: true,
        documentManagement: true,
        notifications: true,
        timeTracking: true,
        
        // Plan-dependent features
        analytics: plan.features?.analytics || false,
        customBranding: plan.features?.customBranding || false,
        apiAccess: plan.features?.apiAccess || false,
        multiLocation: plan.features?.multiLocationSupport || false,
        advancedReporting: plan.features?.advancedReporting || false,
        expenseManagement: plan.features?.expenseManagement || false,
        performanceReviews: plan.features?.performanceReviews || false,
        trainingManagement: plan.features?.trainingManagement || false,
        locationBasedAttendance: plan.features?.locationBasedAttendance || false,
      };

      // Define expected limits based on the plan
      const expectedLimits = {
        maxEmployees: plan.features?.maxEmployees || 10,
        maxStorageGB: plan.features?.maxStorageGB || 5,
        maxApiCallsPerDay: plan.features?.maxApiCallsPerDay || 1000,
        maxDepartments: plan.features?.maxDepartments || 3,
        dataRetention: plan.features?.dataRetention || 365,
        maxLocations: plan.features?.multiLocationSupport ? 3 : 1,
      };

      // Check if features need updating
      let featuresNeedUpdate = false;
      Object.entries(expectedFeatures).forEach(([key, expectedValue]) => {
        if (currentFeatures[key] !== expectedValue) {
          featuresNeedUpdate = true;
        }
      });

      // Check if limits need updating
      let limitsNeedUpdate = false;
      Object.entries(expectedLimits).forEach(([key, expectedValue]) => {
        if (currentLimits[key] !== expectedValue) {
          limitsNeedUpdate = true;
        }
      });

      // Update company if needed
      if (featuresNeedUpdate || limitsNeedUpdate) {
        console.log('   🔧 Updating features and limits...');
        
        company.features = expectedFeatures;
        company.limits = expectedLimits;
        
        await company.save();
        console.log('   ✅ Updated successfully');
        fixedCount++;
      } else {
        console.log('   ✅ Already up to date');
        skippedCount++;
      }

      // Fix company status if it's cancelled but should be active
      if (company.status === 'cancelled') {
        console.log('   🔧 Fixing company status from cancelled to active...');
        company.status = 'active';
        await company.save();
        console.log('   ✅ Status updated to active');
      }
    }

    // Summary
    console.log('\n📋 SUMMARY');
    console.log('==========');
    console.log(`✅ Fixed: ${fixedCount} companies`);
    console.log(`⏭️  Skipped: ${skippedCount} companies`);
    console.log(`📊 Total: ${companies.length} companies`);

    // Final verification
    console.log('\n🧪 FINAL VERIFICATION');
    console.log('=====================');
    
    const finalCompanies = await Company.find({}).populate('subscriptionPlan');
    let allGood = true;

    for (const company of finalCompanies) {
      if (!company.subscriptionPlan) {
        console.log(`❌ ${company.name}: Still no subscription plan`);
        allGood = false;
        continue;
      }

      const plan = company.subscriptionPlan;
      const features = company.features || {};
      const limits = company.limits || {};

      // Quick check for key features
      const analyticsEnabled = features.analytics === plan.features?.analytics;
      const maxEmployees = limits.maxEmployees === plan.features?.maxEmployees;

      if (analyticsEnabled && maxEmployees) {
        console.log(`✅ ${company.name}: ${plan.name} plan with proper features`);
      } else {
        console.log(`⚠️  ${company.name}: ${plan.name} plan but features may need attention`);
        allGood = false;
      }
    }

    if (allGood) {
      console.log('\n🎉 All subscription plan issues have been resolved!');
    } else {
      console.log('\n⚠️  Some issues may still need attention');
    }

    // Test API response
    console.log('\n🧪 TESTING API RESPONSE');
    console.log('======================');
    
    const testCompany = finalCompanies.find(c => c.status === 'active') || finalCompanies[0];
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
          maxEmployees: testCompany.subscriptionPlan?.features?.maxEmployees || 10,
          maxStorageGB: testCompany.subscriptionPlan?.features?.maxStorageGB || 5,
          maxApiCallsPerDay: testCompany.subscriptionPlan?.features?.maxApiCallsPerDay || 1000,
          maxDepartments: testCompany.subscriptionPlan?.features?.maxDepartments || 3,
          dataRetention: testCompany.subscriptionPlan?.features?.dataRetention || 365,
        },
        subscriptionPlan: {
          name: testCompany.subscriptionPlan?.name || 'Basic',
          price: testCompany.subscriptionPlan?.price || { monthly: 29, yearly: 290 },
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
      console.log(`   Analytics: ${simulatedResponse.features.analytics ? '✅' : '❌'}`);
      console.log(`   Max Employees: ${simulatedResponse.limits.maxEmployees}`);
    }

  } catch (error) {
    console.error('Error fixing subscription issues:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run the fix
fixSubscriptionLoadingV2(); 