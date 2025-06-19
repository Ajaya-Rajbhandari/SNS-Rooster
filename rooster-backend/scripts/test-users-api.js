const http = require('http');

// First login to get token
function login() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'admin@snsrooster.com',
      password: 'Admin@123'
    });

    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode === 200 && parsed.token) {
            resolve(parsed.token);
          } else {
            reject(new Error(`Login failed: ${body}`));
          }
        } catch (e) {
          reject(new Error(`Parse error: ${e.message}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.write(data);
    req.end();
  });
}

// Get users with token
function getUsers(token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: '/api/auth/users',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        console.log('Users API Status Code:', res.statusCode);
        console.log('Users API Response:', body);
        try {
          const parsed = JSON.parse(body);
          resolve(parsed);
        } catch (e) {
          reject(new Error(`Parse error: ${e.message}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    req.end();
  });
}

// Main execution
async function testAPI() {
  try {
    console.log('Logging in...');
    const token = await login();
    console.log('Login successful, token received');
    
    console.log('\nFetching users...');
    const users = await getUsers(token);
    console.log('\nUsers data:');
    if (users.users) {
      users.users.forEach(user => {
        console.log(`- Email: ${user.email}, Role: ${user.role}, Name: ${user.name || 'N/A'}`);
      });
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testAPI();