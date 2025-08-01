const mongoose = require('mongoose');
const dotenv = require('dotenv');
const LeavePolicy = require('../models/LeavePolicy');
const Company = require('../models/Company');

// Load environment variables
dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

async function initializeLeavePolicies() {
  try {
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all companies
    const companies = await Company.find({});
    console.log(`📋 Found ${companies.length} companies`);

    let createdCount = 0;
    let updatedCount = 0;

    for (const company of companies) {
      console.log(`\n🏢 Processing company: ${company.name} (${company._id})`);

      // Check if company already has a default policy
      const existingPolicy = await LeavePolicy.findOne({
        companyId: company._id,
        isDefault: true
      });

      if (existingPolicy) {
        console.log(`   ⚠️  Company already has a default policy: ${existingPolicy.name}`);
        updatedCount++;
        continue;
      }

      // Create default policy for the company
      const defaultPolicy = new LeavePolicy({
        companyId: company._id,
        name: 'Default Policy',
        description: `Default leave policy for ${company.name}`,
        isDefault: true,
        leaveTypes: {
          annualLeave: {
            totalDays: 12,
            description: 'Annual Leave',
            isActive: true
          },
          sickLeave: {
            totalDays: 10,
            description: 'Sick Leave',
            isActive: true
          },
          casualLeave: {
            totalDays: 5,
            description: 'Casual Leave',
            isActive: true
          },
          maternityLeave: {
            totalDays: 90,
            description: 'Maternity Leave',
            isActive: true
          },
          paternityLeave: {
            totalDays: 10,
            description: 'Paternity Leave',
            isActive: true
          },
          unpaidLeave: {
            totalDays: 0,
            description: 'Unpaid Leave',
            isActive: true
          }
        },
        rules: {
          minNoticeDays: 1,
          maxConsecutiveDays: 30,
          allowHalfDays: false,
          allowCancellation: true,
          carryOverBalance: false,
          maxCarryOverDays: 5,
          leaveYearStartMonth: 1,
          leaveYearStartDay: 1
        }
      });

      await defaultPolicy.save();
      console.log(`   ✅ Created default policy: ${defaultPolicy.name}`);
      createdCount++;
    }

    console.log(`\n📊 Summary:`);
    console.log(`   ✅ Created: ${createdCount} policies`);
    console.log(`   ⚠️  Already existed: ${updatedCount} policies`);
    console.log(`   📋 Total processed: ${companies.length} companies`);

  } catch (error) {
    console.error('❌ Error initializing leave policies:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run the script
if (require.main === module) {
  initializeLeavePolicies();
}

module.exports = initializeLeavePolicies; 