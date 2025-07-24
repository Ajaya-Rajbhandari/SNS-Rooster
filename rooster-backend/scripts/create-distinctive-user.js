const axios = require('axios');

const BASE_URL = 'http://localhost:5000';
const SUPER_ADMIN_EMAIL = 'superadmin@snstechservices.com.au';
const SUPER_ADMIN_PASSWORD = 'SuperAdmin@123';

async function createDistinctiveUser() {
  try {
    console.log('🧪 Creating Distinctive Test User\n');

    // Step 1: Login as super admin
    console.log('1. Logging in as super admin...');
    const adminLoginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: SUPER_ADMIN_EMAIL,
      password: SUPER_ADMIN_PASSWORD
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Super admin login successful\n');

    // Step 2: Get companies
    console.log('2. Fetching companies...');
    const companiesResponse = await axios.get(`${BASE_URL}/api/super-admin/companies`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    const companies = companiesResponse.data.companies;
    const testCompany = companies[0];
    console.log(`✅ Using company: ${testCompany.name}\n`);

    // Step 3: Create a very distinctive test user
    console.log('3. Creating distinctive test user...');
    const testEmail = `testuser${Date.now()}@example.com`;
    const simplePassword = 'Test123!';
    
    const createUserResponse = await axios.post(`${BASE_URL}/api/super-admin/users`, {
      firstName: 'TEST_USER',
      lastName: 'DEMO_ACCOUNT',
      email: testEmail,
      role: 'employee',
      companyId: testCompany._id,
      department: 'Testing Department',
      position: 'Test Position'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    console.log(`✅ Distinctive user created successfully!`);
    console.log(`📧 Email: ${testEmail}`);
    console.log(`🔑 Password: ${simplePassword}`);
    console.log(`👤 Name: ${createUserResponse.data.user.firstName} ${createUserResponse.data.user.lastName}`);
    console.log(`🏢 Company: ${createUserResponse.data.user.companyId?.name}`);
    console.log(`🎭 Role: ${createUserResponse.data.user.role}\n`);

    // Step 4: Test login immediately
    console.log('4. Testing login with distinctive user...');
    const userLoginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: testEmail,
      password: simplePassword
    });

    console.log('✅ Login successful!');
    console.log(`🎉 Welcome ${userLoginResponse.data.user.firstName} ${userLoginResponse.data.user.lastName}`);
    console.log(`👤 Role: ${userLoginResponse.data.user.role}`);
    console.log(`🏢 Company: ${userLoginResponse.data.user.companyId?.name}`);
    console.log(`🆔 User ID: ${userLoginResponse.data.user._id}`);

    console.log('\n🎉 DISTINCTIVE USER READY FOR TESTING!');
    console.log('=========================================');
    console.log('📋 FLUTTER APP TEST CREDENTIALS:');
    console.log(`📧 Email: ${testEmail}`);
    console.log(`🔑 Password: ${simplePassword}`);
    console.log(`👤 Expected Name: TEST_USER DEMO_ACCOUNT`);
    console.log(`🏢 Company: ${testCompany.name}`);
    console.log(`🎭 Role: Employee`);
    console.log('\n💡 This user has a very distinctive name that should be easy to identify!');
    console.log('\n📱 FLUTTER APP TESTING STEPS:');
    console.log('1. Make sure you\'re logged out of the Flutter app');
    console.log('2. Go to Login screen');
    console.log('3. Enter the email and password above');
    console.log('4. Click Login');
    console.log('5. You should see "Welcome Back, TEST_USER DEMO_ACCOUNT"');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.error || error.message);
  }
}

console.log('🧪 CREATING DISTINCTIVE TEST USER');
console.log('==================================');
console.log('This will create a user with a very distinctive name');
console.log('to help identify if the login is working correctly.');
console.log('\n');

createDistinctiveUser(); 