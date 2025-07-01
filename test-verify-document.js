const axios = require('axios');

const baseURL = 'http://localhost:5000/api/employees';
const adminEmail = 'admin@snsrooster.com';
const adminPassword = 'Admin@123';
const userId = '686375e8826f713343a01997';
const docId = '6863af0457fce4578730f8f4';

async function testVerifyDocument() {
  try {
    // 1. Login as admin
    const loginRes = await axios.post('http://localhost:5000/api/auth/login', {
      email: adminEmail,
      password: adminPassword,
    });
    const token = loginRes.data.token;
    console.log('✓ Admin login successful');

    // 2. Verify the document directly
    const verifyRes = await axios.patch(
      `${baseURL}/users/${userId}/documents/${docId}/verify`,
      { status: 'verified' },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    console.log('✓ Document verification response:', verifyRes.data);
  } catch (err) {
    console.error('Test failed:', err.response?.data || err.message);
  }
}

testVerifyDocument(); 