const mongoose = require('mongoose');
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');
require('dotenv').config();

async function migrateFeatureChanges() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('🔧 Migrating companies to new feature distribution...');

    // Get all active companies
    const companies = await Company.find({ status: 'active' }).populate('subscriptionPlan');
    console.log(`Found ${companies.length} active companies to migrate`);

    let migratedCount = 0;
    let errorCount = 0;

    for (const company of companies) {
      try {
        console.log(`\n📋 Processing company: ${company.name} (${company.domain})`);
        
        const subscriptionPlan = company.subscriptionPlan;
        const planName = subscriptionPlan?.name?.toLowerCase() || 'basic';
        
        console.log(`   Current plan: ${planName}`);

        // Update company features based on new distribution
        const newFeatures = {
          ...company.features,
          // Update payroll and document management based on plan
          payroll: planName !== 'basic',
          documentManagement: planName !== 'basic'
        };

        // Update company
        await Company.findByIdAndUpdate(company._id, {
          features: newFeatures
        });

        console.log(`   ✅ Updated features for ${company.name}:`);
        console.log(`      - Payroll: ${newFeatures.payroll ? '✅' : '❌'}`);
        console.log(`      - Document Management: ${newFeatures.documentManagement ? '✅' : '❌'}`);

        migratedCount++;

      } catch (error) {
        console.error(`   ❌ Error processing ${company.name}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   ✅ Successfully migrated: ${migratedCount} companies`);
    console.log(`   ❌ Errors: ${errorCount} companies`);
    console.log(`   📊 Total processed: ${companies.length} companies`);

    if (errorCount > 0) {
      console.log('\n⚠️  Some companies had errors during migration. Please review the logs above.');
    } else {
      console.log('\n🎉 Migration completed successfully!');
    }

    console.log('\n📋 New Feature Distribution:');
    console.log('  Basic Plan: Payroll ❌, Document Management ❌');
    console.log('  Advance Plan: Payroll ✅, Document Management ✅');
    console.log('  Professional Plan: Payroll ✅, Document Management ✅');
    console.log('  Enterprise Plan: Payroll ✅, Document Management ✅');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

migrateFeatureChanges(); 