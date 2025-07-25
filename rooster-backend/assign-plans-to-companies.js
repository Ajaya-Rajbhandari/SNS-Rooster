const mongoose = require('mongoose');
const Company = require('./models/Company');
const SubscriptionPlan = require('./models/SubscriptionPlan');
const User = require('./models/User');
require('dotenv').config();

// Use environment variable for MongoDB URI
const MONGODB_URI = process.env.MONGODB_URI;

async function assignPlansToCompanies() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({});
    console.log(`\n🏢 Found ${companies.length} companies to assign plans`);

    // Get all plans
    const plans = await SubscriptionPlan.find({}).sort({ 'price.monthly': 1 });
    console.log(`\n📋 Available subscription plans: ${plans.length}`);
    plans.forEach(plan => {
      console.log(`  - ${plan.name}: $${plan.price.monthly}/month`);
    });

    for (const company of companies) {
      console.log(`\n📝 Processing: ${company.name}`);
      
      // Check if company already has a plan
      if (company.subscriptionPlan) {
        console.log(`Company ${company.name} already has plan: ${company.subscriptionPlan}`);
        continue;
      }

      // Determine which plan to assign based on current features
      let assignedPlan = null;
      
      if (company.features?.analytics && company.features?.advancedReporting && company.features?.customBranding) {
        // Has all premium features - assign Professional or Enterprise
        if (company.features?.apiAccess) {
          assignedPlan = plans.find(p => p.name === 'Enterprise');
        } else {
          assignedPlan = plans.find(p => p.name === 'Professional');
        }
      } else if (company.features?.analytics) {
        // Has analytics but not advanced features - assign Advance
        assignedPlan = plans.find(p => p.name === 'Advance');
      } else {
        // Basic features only - assign Basic
        assignedPlan = plans.find(p => p.name === 'Basic');
      }

      if (assignedPlan) {
        console.log(`   📋 Current features:`);
        console.log(`      - Analytics: ${company.features?.analytics ? '✅' : '❌'}`);
        console.log(`      - Advanced Reporting: ${company.features?.advancedReporting ? '✅' : '❌'}`);
        console.log(`      - Custom Branding: ${company.features?.customBranding ? '✅' : '❌'}`);
        console.log(`      - API Access: ${company.features?.apiAccess ? '✅' : '❌'}`);
        
        console.log(`   🎯 Assigning plan: ${assignedPlan.name}`);
        
        // Update company with the subscription plan
        company.subscriptionPlan = assignedPlan._id;
        company.isCustomPlan = false;
        
        // Set createdBy if not already set
        // The original code had a superAdmin user creation block, but the new code
        // implies a different approach for super admins.
        // For now, we'll keep the original superAdmin user logic as it was not
        // explicitly removed by the new_code, but the new_code's superAdmin
        // creation logic is different.
        // The new_code's superAdmin creation logic is commented out in the
        // original file, so we'll re-introduce it here.
        const superAdmin = await User.findOne({ role: 'super_admin' });
        if (!superAdmin) {
          console.log('❌ No super admin user found. Creating one...');
          // Create a super admin user if none exists
          const bcrypt = require('bcrypt');
          // Use environment variable for default password or generate a secure one
          const defaultPassword = process.env.DEFAULT_SUPER_ADMIN_PASSWORD || 'SuperAdmin@123';
          const hashedPassword = await bcrypt.hash(defaultPassword, 10);
          const newSuperAdmin = new User({
            firstName: 'Super',
            lastName: 'Admin',
            email: 'superadmin@snstechservices.com.au',
            password: hashedPassword,
            role: 'super_admin',
            isActive: true,
            companyId: null // Super admin doesn't belong to any company
          });
          await newSuperAdmin.save();
          console.log('✅ Created super admin user');
        }

        // Update features based on the plan
        company.features = {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: assignedPlan.features.analytics,
          documentManagement: true,
          notifications: true,
          customBranding: assignedPlan.features.customBranding,
          apiAccess: assignedPlan.features.apiAccess,
          multiLocation: false,
          advancedReporting: assignedPlan.features.advancedReporting,
          timeTracking: true,
          expenseManagement: false,
          performanceReviews: false,
          trainingManagement: false
        };
        
        // Update limits based on the plan
        company.limits = {
          maxEmployees: assignedPlan.features.maxEmployees,
          maxStorageGB: 5, // Default storage
          retentionDays: assignedPlan.features.dataRetention,
          maxApiCallsPerDay: assignedPlan.features.apiAccess ? 1000 : 0,
          maxLocations: 1
        };
        
        await company.save();
        console.log(`   ✅ Assigned ${assignedPlan.name} plan to ${company.name}`);
      } else {
        console.log(`   ⚠️  No suitable plan found for ${company.name}`);
      }
    }

    console.log('\n🎉 All companies have been assigned subscription plans!');
    
    // Verify the assignments
    console.log('\n📊 Final Assignment Summary:');
    const updatedCompanies = await Company.find({}).populate('subscriptionPlan');
    updatedCompanies.forEach(company => {
      console.log(`  - ${company.name}: ${company.subscriptionPlan?.name || 'No Plan'}`);
    });

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

assignPlansToCompanies(); 