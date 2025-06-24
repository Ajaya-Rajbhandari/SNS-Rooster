const http = require('http');

function testConnection(host, port) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: host,
      port: port,
      path: '/',
      method: 'GET',
      timeout: 5000
    };

    const req = http.request(options, (res) => {
      console.log(`✅ Connection to ${host}:${port} successful!`);
      console.log(`Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log(`Response: ${data}`);
        resolve(true);
      });
    });

    req.on('error', (err) => {
      console.log(`❌ Connection to ${host}:${port} failed:`);
      console.log(`Error: ${err.message}`);
      reject(err);
    });

    req.on('timeout', () => {
      console.log(`❌ Connection to ${host}:${port} timed out`);
      req.destroy();
      reject(new Error('Connection timeout'));
    });

    req.setTimeout(5000);
    req.end();
  });
}

async function runTests() {
  console.log('=== Network Connection Test ===\n');
  
  // Test localhost
  console.log('Testing localhost...');
  try {
    await testConnection('localhost', 5000);
  } catch (err) {
    console.log('Localhost test failed');
  }
  
  console.log('\n');
  
  // Test 127.0.0.1
  console.log('Testing 127.0.0.1...');
  try {
    await testConnection('127.0.0.1', 5000);
  } catch (err) {
    console.log('127.0.0.1 test failed');
  }
  
  console.log('\n');
  
  // Test actual IP
  console.log('Testing 192.168.1.80...');
  try {
    await testConnection('192.168.1.80', 5000);
  } catch (err) {
    console.log('IP address test failed');
  }
}

runTests();
