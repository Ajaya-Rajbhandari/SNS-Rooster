const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:5000'; // Your backend runs on port 5000
const TEST_EMAIL = 'admin@snsrooster.com'; // Admin email from your scripts
const TEST_PASSWORD = 'Admin@123'; // Admin password from your scripts

let authToken = '';

async function login() {
  try {
    console.log('🔐 Logging in...');
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    });
    
    authToken = response.data.token;
    console.log('✅ Login successful');
    return true;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return false;
  }
}

async function testTimesheetFiltering() {
  console.log('\n📊 Testing Timesheet Filtering...');
  
  const headers = { Authorization: `Bearer ${authToken}` };
  
  try {
    // Test 1: Include admins (default)
    console.log('\n1️⃣ Testing timesheet with includeAdmins=true (default)...');
    const response1 = await axios.get(`${BASE_URL}/api/admin/attendance?includeAdmins=true`, { headers });
    console.log(`   ✅ Found ${response1.data.attendance?.length || 0} attendance records`);
    
    // Test 2: Employees only
    console.log('\n2️⃣ Testing timesheet with includeAdmins=false (employees only)...');
    const response2 = await axios.get(`${BASE_URL}/api/admin/attendance?includeAdmins=false`, { headers });
    console.log(`   ✅ Found ${response2.data.attendance?.length || 0} attendance records (employees only)`);
    
    // Compare results
    const allRecords = response1.data.attendance?.length || 0;
    const employeeRecords = response2.data.attendance?.length || 0;
    
    if (allRecords >= employeeRecords) {
      console.log(`   ✅ Filtering works: ${allRecords} total vs ${employeeRecords} employees only`);
    } else {
      console.log(`   ⚠️  Unexpected: ${allRecords} total vs ${employeeRecords} employees only`);
    }
    
    return true;
  } catch (error) {
    console.error('❌ Timesheet filtering test failed:', error.response?.data || error.message);
    return false;
  }
}

async function testLeaveFiltering() {
  console.log('\n📋 Testing Leave Request Filtering...');
  
  const headers = { Authorization: `Bearer ${authToken}` };
  
  try {
    // Test 1: Include admins (default)
    console.log('\n1️⃣ Testing leave requests with includeAdmins=true (default)...');
    const response1 = await axios.get(`${BASE_URL}/api/leave/leave-requests?includeAdmins=true`, { headers });
    console.log(`   ✅ Found ${response1.data?.length || 0} leave requests`);
    
    // Test 2: Employees only
    console.log('\n2️⃣ Testing leave requests with includeAdmins=false (employees only)...');
    const response2 = await axios.get(`${BASE_URL}/api/leave/leave-requests?includeAdmins=false`, { headers });
    console.log(`   ✅ Found ${response2.data?.length || 0} leave requests (employees only)`);
    
    // Compare results
    const allRequests = response1.data?.length || 0;
    const employeeRequests = response2.data?.length || 0;
    
    if (allRequests >= employeeRequests) {
      console.log(`   ✅ Filtering works: ${allRequests} total vs ${employeeRequests} employees only`);
    } else {
      console.log(`   ⚠️  Unexpected: ${allRequests} total vs ${employeeRequests} employees only`);
    }
    
    return true;
  } catch (error) {
    console.error('❌ Leave filtering test failed:', error.response?.data || error.message);
    return false;
  }
}

async function testUserFilteringUtility() {
  console.log('\n🔧 Testing User Filtering Utility...');
  
  try {
    const { getUserFilter, getPopulationFilter } = require('./rooster-backend/utils/user-filtering.js');
    
    // Test different scenarios
    const tests = [
      { name: 'Timesheet (include admins)', result: getUserFilter('timesheet', { includeAdmins: true }) },
      { name: 'Timesheet (employees only)', result: getUserFilter('timesheet', { onlyEmployees: true }) },
      { name: 'Leave (include admins)', result: getUserFilter('leave', { includeAdmins: true }) },
      { name: 'Analytics (employees only)', result: getUserFilter('analytics', { onlyEmployees: true }) }
    ];
    
    tests.forEach(test => {
      console.log(`   ✅ ${test.name}:`, test.result);
    });
    
    return true;
  } catch (error) {
    console.error('❌ User filtering utility test failed:', error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🚀 Starting Role Filtering Tests...\n');
  
  // Test 1: Login
  const loginSuccess = await login();
  if (!loginSuccess) {
    console.log('\n❌ Cannot proceed without login. Please check credentials.');
    return;
  }
  
  // Test 2: User filtering utility
  await testUserFilteringUtility();
  
  // Test 3: Timesheet filtering
  await testTimesheetFiltering();
  
  // Test 4: Leave filtering
  await testLeaveFiltering();
  
  console.log('\n🎉 All tests completed!');
  console.log('\n📝 Next steps:');
  console.log('   1. Start your Flutter app');
  console.log('   2. Navigate to Admin Timesheet');
  console.log('   3. Test the role filter chips');
  console.log('   4. Navigate to Leave Management');
  console.log('   5. Test the role filter chips there too');
}

// Run tests
runAllTests().catch(console.error); 