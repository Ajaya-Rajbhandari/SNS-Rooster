const http = require('http');

function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({ status: res.statusCode, data: jsonData });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });
    
    req.on('error', (err) => {
      reject(err);
    });
    
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function testBreakTypesEndpoint() {
  try {
    console.log('Testing break-types endpoint...');
    
    // First, login to get a valid token
    console.log('1. Logging in to get token...');
    const loginOptions = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    const loginData = JSON.stringify({
      email: 'employee2@snsrooster.com',
      password: 'Employee@456'
    });
    
    const loginResponse = await makeRequest(loginOptions, loginData);
    console.log('Login response status:', loginResponse.status);
    
    if (loginResponse.status !== 200) {
      console.error('Login failed:', loginResponse.data);
      return;
    }
    
    const token = loginResponse.data.token;
    console.log('Login successful, token received');
    
    // Test the break-types endpoint
    console.log('2. Testing /api/break-types endpoint...');
    const breakTypesOptions = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/break-types',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };
    
    const breakTypesResponse = await makeRequest(breakTypesOptions);
    
    console.log('Break types response:');
    console.log('Status:', breakTypesResponse.status);
    console.log('Data:', JSON.stringify(breakTypesResponse.data, null, 2));
    
  } catch (error) {
    console.error('Error testing endpoint:');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    console.error('Full error:', error);
  }
}

testBreakTypesEndpoint();