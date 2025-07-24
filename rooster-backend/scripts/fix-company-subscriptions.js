const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function fixCompanySubscriptions() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Get all subscription plans
    const plans = await SubscriptionPlan.find({ isActive: true }).sort('sortOrder');
    console.log(`Found ${plans.length} subscription plans:`, plans.map(p => p.name));

    if (plans.length === 0) {
      console.log('No subscription plans found. Please create plans first.');
      return;
    }

    // Get default plan (first one or one marked as default)
    const defaultPlan = plans.find(p => p.isDefault) || plans[0];
    console.log(`Using default plan: ${defaultPlan.name}`);

    // Get all companies without subscription plans
    const companiesWithoutPlans = await Company.find({ 
      $or: [
        { subscriptionPlan: { $exists: false } },
        { subscriptionPlan: null }
      ]
    });

    console.log(`Found ${companiesWithoutPlans.length} companies without subscription plans`);

    // Assign default plan to companies without plans
    for (const company of companiesWithoutPlans) {
      console.log(`Assigning plan "${defaultPlan.name}" to company "${company.name}"`);
      
      company.subscriptionPlan = defaultPlan._id;
      
      // Update company features and limits based on the plan
      company.features = {
        attendance: true,
        payroll: true,
        leaveManagement: true,
        analytics: defaultPlan.features.analytics,
        documentManagement: true,
        notifications: true,
        customBranding: defaultPlan.features.customBranding,
        apiAccess: defaultPlan.features.apiAccess,
        multiLocation: false,
        advancedReporting: defaultPlan.features.advancedReporting,
        timeTracking: true,
        expenseManagement: false,
        performanceReviews: false,
        trainingManagement: false
      };

      company.limits = {
        maxEmployees: defaultPlan.features.maxEmployees,
        maxStorageGB: 5,
        retentionDays: defaultPlan.features.dataRetention,
        maxApiCallsPerDay: defaultPlan.features.apiAccess ? 1000 : 0,
        maxLocations: 1
      };

      // Set createdBy if missing (use the first super admin user)
      if (!company.createdBy) {
        const superAdmin = await mongoose.model('User').findOne({ role: 'super_admin' });
        if (superAdmin) {
          company.createdBy = superAdmin._id;
        }
      }

      await company.save({ validateBeforeSave: false });
      console.log(`✅ Updated company: ${company.name}`);
    }

    // Also check companies with invalid subscription plan references
    const companiesWithInvalidPlans = await Company.find({
      subscriptionPlan: { $exists: true, $ne: null }
    }).populate('subscriptionPlan');

    console.log(`\nChecking ${companiesWithInvalidPlans.length} companies with subscription plans:`);
    
    for (const company of companiesWithInvalidPlans) {
      if (!company.subscriptionPlan) {
        console.log(`⚠️  Company "${company.name}" has invalid subscription plan reference`);
        console.log(`   Assigning default plan "${defaultPlan.name}"`);
        
        company.subscriptionPlan = defaultPlan._id;
        await company.save({ validateBeforeSave: false });
        console.log(`✅ Fixed company: ${company.name}`);
      } else {
        console.log(`✅ Company "${company.name}" has valid plan: "${company.subscriptionPlan.name}"`);
      }
    }

    console.log('\n🎉 Company subscription plan fix completed!');
    
    // Show summary
    const totalCompanies = await Company.countDocuments();
    const companiesWithPlans = await Company.countDocuments({ 
      subscriptionPlan: { $exists: true, $ne: null } 
    });
    
    console.log(`\nSummary:`);
    console.log(`- Total companies: ${totalCompanies}`);
    console.log(`- Companies with plans: ${companiesWithPlans}`);
    console.log(`- Companies without plans: ${totalCompanies - companiesWithPlans}`);

  } catch (error) {
    console.error('❌ Error fixing company subscriptions:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

fixCompanySubscriptions(); 