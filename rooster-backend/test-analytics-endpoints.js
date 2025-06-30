const axios = require('axios');

const BASE_URL = 'http://192.168.1.68:5000/api';
const USER_ID = '685a8921be22e980a5ba2707';
const TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODVhODkyMWJlMjJlOTgwYTViYTI3MDciLCJlbWFpbCI6InRlc3R1c2VyQGV4YW1wbGUuY29tIiwicm9sZSI6ImVtcGxveWVlIiwiaXNQcm9maWxlQ29tcGxldGUiOmZhbHNlLCJpYXQiOjE3NTEyOTYyMjEsImV4cCI6MTc1MTM4MjYyMX0.sNS9_dVo5IOpDADf2eQIC29PGIDTPmxM5r8pit1cBGo';

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${TOKEN}`
};

async function testAnalyticsEndpoints() {
  console.log('Testing Analytics Endpoints...\n');

  try {
    // Test attendance analytics
    console.log('1. Testing attendance analytics endpoint...');
    const attendanceResponse = await axios.get(
      `${BASE_URL}/employees/analytics/attendance/${USER_ID}`,
      { headers }
    );
    console.log('✅ Attendance analytics response:');
    console.log('Status:', attendanceResponse.status);
    console.log('Data:', JSON.stringify(attendanceResponse.data, null, 2));
    console.log('');

    // Test work hours analytics
    console.log('2. Testing work hours analytics endpoint...');
    const workHoursResponse = await axios.get(
      `${BASE_URL}/employees/analytics/work-hours/${USER_ID}`,
      { headers }
    );
    console.log('✅ Work hours analytics response:');
    console.log('Status:', workHoursResponse.status);
    console.log('Data:', JSON.stringify(workHoursResponse.data, null, 2));
    console.log('');

  } catch (error) {
    console.error('❌ Error testing analytics endpoints:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
      console.error('Headers:', error.response.headers);
    } else {
      console.error('Error message:', error.message);
    }
  }
}

testAnalyticsEndpoints(); 