const axios = require('axios');

const BASE_URL = 'http://localhost:5000';
const TEST_EMAIL = 'admin@snsrooster.com';
const TEST_PASSWORD = 'Admin@123';

async function testLeaveEndpoint() {
  try {
    console.log('🔐 Logging in...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    });
    
    const token = loginResponse.data.token;
    console.log('✅ Login successful');
    
    console.log('\n📋 Testing leave requests endpoint...');
    const headers = { Authorization: `Bearer ${token}` };
    
    // Test the leave requests endpoint
    const response = await axios.get(`${BASE_URL}/api/leave/leave-requests`, { headers });
    console.log('✅ Leave requests response:', response.data);
    console.log(`   Found ${response.data?.length || 0} leave requests`);
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testLeaveEndpoint(); 