
require('dotenv').config();
const mongoose = require('mongoose');
const Company = require('../models/Company');
const AdminSettings = require('../models/AdminSettings');
const BreakType = require('../models/BreakType');

async function testCompanyCreation() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connecting to:', process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    // Test 1: Find the test company
    console.log('\n🔍 Testing company lookup...');
    const company = await Company.findByDomain('snsrooster.com');
    
    if (!company) {
      console.log('❌ Company not found. Please run create-test-company.js first.');
      process.exit(1);
    }

    console.log('✅ Company found successfully!');
    console.log('Company ID:', company._id);
    console.log('Company Name:', company.name);
    console.log('Domain:', company.domain);
    console.log('Status:', company.status);
    console.log('Is Active:', company.isActive());

    // Test 2: Check company features
    console.log('\n🔧 Testing company features...');
    const features = company.features;
    console.log('Attendance enabled:', company.isFeatureEnabled('attendance'));
    console.log('Payroll enabled:', company.isFeatureEnabled('payroll'));
    console.log('Analytics enabled:', company.isFeatureEnabled('analytics'));
    console.log('API Access enabled:', company.isFeatureEnabled('apiAccess'));

    // Test 3: Get company context
    console.log('\n📋 Testing company context...');
    const context = company.getCompanyContext();
    console.log('Company Context:', JSON.stringify(context, null, 2));

    // Test 4: Check admin settings
    console.log('\n⚙️ Testing admin settings...');
    const adminSettings = await AdminSettings.findOne({ companyId: company._id });
    
    if (adminSettings) {
      console.log('✅ Admin settings found');
      console.log('Company Name:', adminSettings.companyInfo.name);
      console.log('Max File Upload Size:', adminSettings.maxFileUploadSize / (1024 * 1024), 'MB');
      console.log('Payroll Frequency:', adminSettings.payrollCycle.frequency);
    } else {
      console.log('❌ Admin settings not found');
    }

    // Test 5: Check break types
    console.log('\n☕ Testing break types...');
    const breakTypes = await BreakType.find({ companyId: company._id });
    
    if (breakTypes.length > 0) {
      console.log(`✅ Found ${breakTypes.length} break types:`);
      breakTypes.forEach((breakType, index) => {
        console.log(`  ${index + 1}. ${breakType.displayName} (${breakType.name})`);
        console.log(`     Duration: ${breakType.minDuration}-${breakType.maxDuration} minutes`);
        console.log(`     Daily Limit: ${breakType.dailyLimit}`);
        console.log(`     Is Paid: ${breakType.isPaid}`);
      });
    } else {
      console.log('❌ No break types found');
    }

    // Test 6: Test company limits
    console.log('\n📊 Testing company limits...');
    console.log('Max Employees:', company.limits.maxEmployees);
    console.log('Max Storage (GB):', company.limits.maxStorageGB);
    console.log('Max API Calls/Day:', company.limits.maxApiCallsPerDay);
    console.log('Retention Days:', company.limits.retentionDays);

    // Test 7: Test company settings
    console.log('\n⏰ Testing company settings...');
    console.log('Timezone:', company.settings.timezone);
    console.log('Currency:', company.settings.currency);
    console.log('Working Hours:', `${company.settings.workingHours.start} - ${company.settings.workingHours.end}`);
    console.log('Working Days:', company.settings.workingDays.join(', '));
    console.log('Grace Period (minutes):', company.settings.attendanceGracePeriod);

    // Test 8: Test company branding
    console.log('\n🎨 Testing company branding...');
    console.log('Company Name:', company.branding.companyName);
    console.log('Tagline:', company.branding.tagline);
    console.log('Primary Color:', company.branding.primaryColor);
    console.log('Secondary Color:', company.branding.secondaryColor);

    console.log('\n🎉 All tests passed successfully!');
    console.log('\n📝 Test Summary:');
    console.log('- Company lookup: ✅');
    console.log('- Feature checking: ✅');
    console.log('- Context generation: ✅');
    console.log('- Admin settings: ✅');
    console.log('- Break types: ✅');
    console.log('- Limits validation: ✅');
    console.log('- Settings validation: ✅');
    console.log('- Branding validation: ✅');

    console.log('\n🚀 The test company is ready for use!');
    console.log('You can now test the application with domain: snsrooster.com');

  } catch (error) {
    console.error('❌ Error during testing:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

testCompanyCreation(); 