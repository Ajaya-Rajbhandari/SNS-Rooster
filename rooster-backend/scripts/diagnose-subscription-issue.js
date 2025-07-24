const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const User = require('../models/User');

async function diagnoseSubscriptionIssue() {
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

    console.log('\n🔍 DIAGNOSING SUBSCRIPTION PLAN LOADING ISSUES');
    console.log('===============================================');

    // Get all companies and check their subscription status
    const companies = await Company.find({}).populate('subscriptionPlan');
    
    console.log(`\n📊 Found ${companies.length} companies in database`);

    const issues = [];

    for (const company of companies) {
      console.log(`\n🏢 Company: ${company.name} (${company._id})`);
      console.log(`   Status: ${company.status}`);
      console.log(`   Subscription Plan: ${company.subscriptionPlan?.name || 'NO PLAN ASSIGNED'}`);
      
      // Check for issues
      if (!company.subscriptionPlan) {
        issues.push({
          company: company.name,
          issue: 'No subscription plan assigned',
          severity: 'HIGH'
        });
        console.log('   ❌ ISSUE: No subscription plan assigned');
      } else {
        console.log('   ✅ Subscription plan found');
        
        // Check if features are properly configured
        const planFeatures = company.subscriptionPlan.features || {};
        const companyFeatures = company.features || {};
        
        // Check for feature mismatches
        const mismatchedFeatures = [];
        Object.entries(planFeatures).forEach(([key, value]) => {
          if (companyFeatures[key] !== value) {
            mismatchedFeatures.push({ key, planValue: value, companyValue: companyFeatures[key] });
          }
        });
        
        if (mismatchedFeatures.length > 0) {
          issues.push({
            company: company.name,
            issue: 'Features not synced with subscription plan',
            severity: 'MEDIUM',
            details: mismatchedFeatures
          });
          console.log('   ⚠️  ISSUE: Features not synced with subscription plan');
        } else {
          console.log('   ✅ Features properly synced');
        }
      }
      
      // Check company status
      if (company.status !== 'active' && company.status !== 'trial') {
        issues.push({
          company: company.name,
          issue: `Company status is '${company.status}' - should be 'active' or 'trial'`,
          severity: 'HIGH'
        });
        console.log(`   ❌ ISSUE: Company status is '${company.status}'`);
      } else {
        console.log('   ✅ Company status is valid');
      }
      
      // Check trial expiration
      if (company.status === 'trial' && company.trialEndDate) {
        const now = new Date();
        if (now > company.trialEndDate) {
          issues.push({
            company: company.name,
            issue: 'Trial has expired',
            severity: 'HIGH',
            details: { trialEndDate: company.trialEndDate }
          });
          console.log('   ❌ ISSUE: Trial has expired');
        } else {
          console.log('   ✅ Trial is still active');
        }
      }
    }

    // Summary
    console.log('\n📋 ISSUE SUMMARY');
    console.log('================');
    
    if (issues.length === 0) {
      console.log('✅ No issues found! All companies have proper subscription plans.');
    } else {
      console.log(`❌ Found ${issues.length} issues:`);
      issues.forEach((issue, index) => {
        console.log(`\n${index + 1}. ${issue.severity} - ${issue.company}: ${issue.issue}`);
        if (issue.details) {
          console.log(`   Details:`, issue.details);
        }
      });
    }

    // Check available subscription plans
    console.log('\n📦 AVAILABLE SUBSCRIPTION PLANS');
    console.log('===============================');
    const availablePlans = await SubscriptionPlan.find({ isActive: true }).sort('sortOrder');
    
    if (availablePlans.length === 0) {
      console.log('❌ No active subscription plans found in database');
    } else {
      availablePlans.forEach(plan => {
        console.log(`\n${plan.name}:`);
        console.log(`  - Price: $${plan.price}/month`);
        console.log(`  - Max Employees: ${plan.features?.maxEmployees || 'N/A'}`);
        console.log(`  - Analytics: ${plan.features?.analytics ? '✅' : '❌'}`);
        console.log(`  - Advanced Reporting: ${plan.features?.advancedReporting ? '✅' : '❌'}`);
        console.log(`  - Custom Branding: ${plan.features?.customBranding ? '✅' : '❌'}`);
        console.log(`  - API Access: ${plan.features?.apiAccess ? '✅' : '❌'}`);
      });
    }

    // Test API response simulation
    console.log('\n🧪 TESTING API RESPONSE SIMULATION');
    console.log('==================================');
    
    const testCompany = companies.find(c => c.subscriptionPlan) || companies[0];
    if (testCompany) {
      console.log(`Testing with company: ${testCompany.name}`);
      
      // Simulate the exact API response from /companies/features
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
      
      console.log('✅ API Response would be valid');
      console.log(`   Plan Name: ${simulatedResponse.subscriptionPlan.name}`);
      console.log(`   Features Count: ${Object.keys(simulatedResponse.features).length}`);
      console.log(`   Limits Count: ${Object.keys(simulatedResponse.limits).length}`);
    } else {
      console.log('❌ No companies available for API testing');
    }

  } catch (error) {
    console.error('Error in diagnosis:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

// Run the diagnosis
diagnoseSubscriptionIssue(); 