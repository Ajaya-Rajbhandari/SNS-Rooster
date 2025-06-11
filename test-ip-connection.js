const http = require('http');

const testConnection = (host, port) => {
  return new Promise((resolve, reject) => {
    console.log(`Testing connection to ${host}:${port}...`);
    
    const postData = JSON.stringify({
      email: 'admin@example.com',
      password: 'admin123'
    });
    
    const options = {
      hostname: host,
      port: port,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 5000
    };
    
    const req = http.request(options, (res) => {
      console.log(`Status: ${res.statusCode}`);
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        console.log('Response:', data);
        resolve({ status: res.statusCode, data });
      });
    });
    
    req.on('error', (err) => {
      console.error(`Error connecting to ${host}:${port}:`, err.message);
      reject(err);
    });
    
    req.on('timeout', () => {
      console.error(`Connection to ${host}:${port} timed out`);
      req.destroy();
      reject(new Error('Connection timeout'));
    });
    
    req.write(postData);
    req.end();
  });
};

// Test both localhost and IP address
async function runTests() {
  try {
    console.log('=== Testing localhost ===');
    await testConnection('localhost', 5000);
  } catch (err) {
    console.log('Localhost test failed:', err.message);
  }
  
  try {
    console.log('\n=== Testing IP address ===');
    await testConnection('192.168.1.67', 5000);
  } catch (err) {
    console.log('IP address test failed:', err.message);
  }
}

runTests();