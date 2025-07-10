const axios = require('axios');

// Test FCM token registration
async function testFCMTokenRegistration() {
  const baseUrl = 'http://localhost:5000/api';
  
  console.log('🧪 Testing FCM Token Registration...\n');

  try {
    // Test 1: Check if server is running
    console.log('1. Testing server connectivity...');
    const healthResponse = await axios.get('http://localhost:5000/');
    console.log('✅ Server is running:', healthResponse.data.message);
  } catch (error) {
    console.log('❌ Server is not running. Please start the backend first:');
    console.log('   cd rooster-backend && npm start');
    return;
  }

  console.log('\n2. Testing FCM token registration endpoint...');
  console.log('   POST /api/fcm-token');
  
  // You'll need to replace these with actual values from your app
  const testData = {
    fcmToken: 'test-fcm-token-12345',
    platform: 'android',
    appVersion: '1.0.0',
    deviceModel: 'test-device'
  };
  
  console.log('\n📋 Test Data:');
  console.log(JSON.stringify(testData, null, 2));
  
  console.log('\n⚠️  Note: This test requires a valid JWT token.');
  console.log('   To get a token, log in to the Flutter app and check the console logs.');
  console.log('   Then update the JWT_TOKEN variable in this script.');
  
  // Uncomment and update with actual JWT token to test
  /*
  const JWT_TOKEN = 'your-jwt-token-here';
  
  try {
    const response = await axios.post(`${baseUrl}/fcm-token`, testData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${JWT_TOKEN}`
      }
    });
    
    console.log('✅ FCM token registration successful:');
    console.log('   Status:', response.status);
    console.log('   Response:', response.data);
  } catch (error) {
    console.log('❌ FCM token registration failed:');
    console.log('   Status:', error.response?.status);
    console.log('   Error:', error.response?.data);
  }
  */
  
  console.log('\n📋 Next Steps:');
  console.log('1. Start the backend: cd rooster-backend && npm start');
  console.log('2. Run the Flutter app: cd sns_rooster && flutter run');
  console.log('3. Log in to the app and check console logs for FCM token registration');
  console.log('4. Check backend logs for FCM DEBUG messages');
  console.log('5. Check MongoDB fcmtokens collection for saved tokens');
  
  console.log('\n🔍 To check MongoDB:');
  console.log('   mongo');
  console.log('   use sns-rooster');
  console.log('   db.fcmtokens.find()');
}

testFCMTokenRegistration(); 