#!/usr/bin/env node

/**
 * Migration script to add usage tracking fields to existing companies
 * This script initializes usage data for all existing companies
 */

const mongoose = require('mongoose');
const Company = require('../models/Company');
const User = require('../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function migrateUsageTracking() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    console.log('\n🔄 Starting usage tracking migration...');

    // Get all companies
    const companies = await Company.find({});
    console.log(`📊 Found ${companies.length} companies to migrate`);

    let migratedCount = 0;
    let errorCount = 0;

    for (const company of companies) {
      try {
        console.log(`\n�� Processing company: ${company.name} (${company.domain})`);

        // Calculate current employee count
        const employeeCount = await User.countDocuments({
          companyId: company._id,
          role: { $ne: 'super_admin' }
        });

        console.log(`   �� Current employees: ${employeeCount}`);

        // Calculate current storage usage (placeholder - will be implemented later)
        const storageGB = 0; // TODO: Implement actual storage calculation

        // Initialize usage data
        const updateData = {
          usage: {
            currentEmployeeCount: employeeCount,
            currentStorageGB: storageGB,
            currentApiCallsToday: 0,
            lastUsageUpdate: new Date(),
            lastApiCallReset: new Date(),
            dailyUsage: {
              employeeCount: employeeCount,
              storageGB: storageGB,
              apiCalls: 0,
              date: new Date()
            }
          }
        };

        // Update company with usage data
        await Company.findByIdAndUpdate(company._id, updateData, { new: true });
        
        console.log(`   ✅ Updated usage data for ${company.name}`);
        migratedCount++;

      } catch (error) {
        console.error(`   ❌ Error processing ${company.name}:`, error.message);
        errorCount++;
      }
    }

    console.log('\n�� Migration Summary:');
    console.log(`   ✅ Successfully migrated: ${migratedCount} companies`);
    console.log(`   ❌ Errors: ${errorCount} companies`);
    console.log(`   📊 Total processed: ${companies.length} companies`);

    if (errorCount > 0) {
      console.log('\n⚠️  Some companies had errors during migration. Please review the logs above.');
    } else {
      console.log('\n🎉 Migration completed successfully!');
    }

    // Create indexes for performance
    console.log('\n🔧 Creating usage tracking indexes...');
    
    try {
      await Company.collection.createIndex({ 'usage.currentEmployeeCount': 1 });
      await Company.collection.createIndex({ 'usage.currentStorageGB': 1 });
      await Company.collection.createIndex({ 'usage.currentApiCallsToday': 1 });
      await Company.collection.createIndex({ 'usage.lastUsageUpdate': 1 });
      await Company.collection.createIndex({ 'usage.lastApiCallReset': 1 });
      
      console.log('✅ Usage tracking indexes created successfully');
    } catch (indexError) {
      console.log('⚠️  Some indexes may already exist:', indexError.message);
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

// Run migration if called directly
if (require.main === module) {
  migrateUsageTracking()
    .then(() => {
      console.log('\n🚀 Migration script completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n💥 Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = migrateUsageTracking; 