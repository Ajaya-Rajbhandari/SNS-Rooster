const axios = require('axios');

const baseURL = 'http://localhost:5000/api';

async function testAttendanceWithStatus() {
  try {
    console.log('Testing attendance with status calculation...');
    
    // First login to get token
    const loginResponse = await axios.post(`${baseURL}/auth/login`, {
      email: 'admin@snsrooster.com',
      password: 'admin123'
    });
    
    if (!loginResponse.data.token) {
      console.error('Failed to get login token');
      return;
    }
    
    const token = loginResponse.data.token;
    console.log('✓ Login successful');
    
    // Get all employees
    const employeesResponse = await axios.get(`${baseURL}/employees`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (employeesResponse.data && employeesResponse.data.length > 0) {
      const employee = employeesResponse.data[0];
      console.log(`✓ Found employee: ${employee.name || employee.firstName}`);
      
      // Get attendance for this employee
      const attendanceResponse = await axios.get(`${baseURL}/attendance/user/${employee.userId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      console.log('✓ Attendance response received');
      console.log('Number of records:', attendanceResponse.data.length);
      
      if (attendanceResponse.data.length > 0) {
        const record = attendanceResponse.data[0];
        console.log('\n--- Sample Attendance Record ---');
        console.log('Date:', record.date);
        console.log('Status:', record.status);
        console.log('Check-in:', record.checkInTime);
        console.log('Check-out:', record.checkOutTime);
        console.log('Breaks:', record.breaks ? record.breaks.length : 0);
      }
    } else {
      console.log('No employees found');
    }
    
  } catch (error) {
    console.error('Error:', error.response?.data?.message || error.message);
  }
}

testAttendanceWithStatus(); 