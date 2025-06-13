async function testEmployee2Login() {
  try {
    console.log('Testing Employee2 login...');
    
    const response = await fetch('http://192.168.1.67:5000/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        email: 'employee2@snsrooster.com',
        password: 'Employee@456'
      })
    });

    const data = await response.json();

    if (response.ok) {
      console.log('Login successful!');
      console.log('Status:', response.status);
      console.log('Token:', data.token ? 'Present' : 'Missing');
      console.log('User:', data.user);
    } else {
      console.error('Login failed!');
      console.error('Status:', response.status);
      console.error('Message:', data.message);
      console.error('Full response:', data);
    }
    
  } catch (error) {
    console.error('Network error:', error.message);
  }
}

testEmployee2Login();