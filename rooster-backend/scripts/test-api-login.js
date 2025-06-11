async function testApiLogin() {
  try {
    console.log('=== TESTING API LOGIN ENDPOINT ===');
    
    const apiUrl = 'http://192.168.1.67:5000/api/auth/login';
    const testCredentials = {
      email: 'testuser@example.com',
      password: 'Test@123'
    };
    
    console.log('API URL:', apiUrl);
    console.log('Test credentials:', testCredentials);
    console.log('\nMaking API request...');
    
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testCredentials)
    });
    
    const responseData = await response.json();
    
    if (response.ok) {
      console.log('✅ SUCCESS!');
      console.log('Status:', response.status);
      console.log('Response data:', responseData);
    } else {
      console.log('❌ ERROR!');
      console.log('Status:', response.status);
      console.log('Response data:', responseData);
    }
    
  } catch (error) {
    console.log('❌ ERROR!');
    
    if (error.response) {
      // Server responded with error status
      console.log('Status:', error.response.status);
      console.log('Response data:', error.response.data);
      console.log('Response headers:', error.response.headers);
    } else {
      // Something else happened
      console.log('Error message:', error.message);
    }
    
    console.log('Full error:', error);
  }
}

// Also test admin credentials
async function testAdminLogin() {
  try {
    console.log('\n=== TESTING ADMIN LOGIN ===');
    
    const apiUrl = 'http://192.168.1.67:5000/api/auth/login';
    const adminCredentials = {
      email: 'admin@snsrooster.com',
      password: 'Admin@123'
    };
    
    console.log('Admin credentials:', adminCredentials);
    console.log('\nMaking admin API request...');
    
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(adminCredentials)
    });
    
    const responseData = await response.json();
    
    if (response.ok) {
      console.log('✅ ADMIN SUCCESS!');
      console.log('Status:', response.status);
      console.log('Response data:', responseData);
    } else {
      console.log('❌ ADMIN ERROR!');
      console.log('Status:', response.status);
      console.log('Response data:', responseData);
    }
    
  } catch (error) {
    console.log('❌ ADMIN ERROR!');
    console.log('Error message:', error.message);
  }
}

async function runTests() {
  await testApiLogin();
  await testAdminLogin();
}

runTests();