const http = require('http');

// Test connection to 10.0.2.2 (Android emulator's host machine)
const loginData = JSON.stringify({
  email: 'admin@snsrooster.com',
  password: 'Admin@123'
});

const options = {
  hostname: '10.0.2.2',
  port: 5000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(loginData)
  }
};

console.log('Testing connection to 10.0.2.2:5000...');

const req = http.request(options, (res) => {
  console.log('Status:', res.statusCode);
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Response:', data);
  });
});

req.on('error', (err) => {
  console.log('Error connecting to 10.0.2.2:5000:', err.message);
  console.log('This suggests the backend server is not accessible from the Android emulator network.');
});

req.write(loginData);
req.end();