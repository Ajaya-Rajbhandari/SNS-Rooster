const axios = require('axios');

async function testAttendanceAPI() {
  try {
    // First, login to get a token
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'admin@example.com',
      password: 'admin123'
    });
    
    const token = loginResponse.data.token;
    console.log('Login successful, token received');
    
    // Test the my-attendance endpoint
    const attendanceResponse = await axios.get('http://localhost:3000/api/attendance/my-attendance', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('Attendance API Response Status:', attendanceResponse.status);
    console.log('Attendance API Response Data:', JSON.stringify(attendanceResponse.data, null, 2));
    
    if (attendanceResponse.data.attendance && attendanceResponse.data.attendance.length > 0) {
      console.log('\nFirst attendance record fields:');
      const firstRecord = attendanceResponse.data.attendance[0];
      Object.keys(firstRecord).forEach(key => {
        console.log(`${key}: ${firstRecord[key]} (${typeof firstRecord[key]})`);
      });
    }
    
  } catch (error) {
    console.error('Error testing attendance API:', error.response?.data || error.message);
  }
}

testAttendanceAPI(); 