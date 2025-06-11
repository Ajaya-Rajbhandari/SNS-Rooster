const http = require('http');

// First, let's login to get a valid token
const loginData = JSON.stringify({
  email: 'admin@snsrooster.com',
  password: 'Admin@123'
});

const loginOptions = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(loginData)
  }
};

const loginReq = http.request(loginOptions, (res) => {
  console.log('Login Status:', res.statusCode);
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    try {
      const loginResponse = JSON.parse(data);
      console.log('Login successful, token received');
      
      if (loginResponse.token) {
        // Now test the users endpoint with correct path
        testUsersEndpoint(loginResponse.token);
      } else {
        console.log('No token received');
      }
    } catch (err) {
      console.log('Error parsing login response:', err.message);
    }
  });
});

loginReq.on('error', (err) => {
  console.log('Login Error:', err.message);
});

loginReq.write(loginData);
loginReq.end();

function testUsersEndpoint(token) {
  const usersOptions = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/auth/users', // Corrected path
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  };

  const usersReq = http.request(usersOptions, (res) => {
    console.log('Users API Status:', res.statusCode);
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    res.on('end', () => {
      try {
        const usersResponse = JSON.parse(data);
        console.log('Users API Response:', JSON.stringify(usersResponse, null, 2));
      } catch (err) {
        console.log('Users API Raw Response:', data);
      }
    });
  });

  usersReq.on('error', (err) => {
    console.log('Users API Error:', err.message);
  });

  usersReq.end();
}