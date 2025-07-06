const axios = require('axios');

// Test FCM endpoints
async function testFCMEndpoints() {
  const baseUrl = 'http://localhost:5000/api';
  
  console.log('🧪 Testing FCM Setup...\n');

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

  console.log('\n2. FCM endpoints available:');
  console.log('   POST /api/fcm-token - Save FCM token');
  console.log('   GET  /api/fcm-token/:userId - Get FCM token');
  console.log('   DELETE /api/fcm-token/:userId - Delete FCM token');
  console.log('   POST /api/send-notification - Send to user');
  console.log('   POST /api/send-topic-notification - Send to topic');
  console.log('   GET  /api/active-tokens - Get all active tokens (admin)');

  console.log('\n📋 Next Steps:');
  console.log('1. Get Firebase service account key from Firebase Console');
  console.log('2. Save it as serviceAccountKey.json in rooster-backend/');
  console.log('3. Uncomment Firebase Admin SDK code in fcm-controller.js');
  console.log('4. Test with Flutter app');
  console.log('5. Check FCM_SETUP_GUIDE.md for detailed instructions');

  console.log('\n🎯 To test with Flutter app:');
  console.log('1. cd sns_rooster');
  console.log('2. flutter run');
  console.log('3. Log in to the app');
  console.log('4. Check console logs for FCM token');
  console.log('5. Verify token is saved to backend');

  console.log('\n📱 To send test notification:');
  console.log('curl -X POST http://localhost:5000/api/send-notification \\');
  console.log('  -H "Content-Type: application/json" \\');
  console.log('  -H "Authorization: Bearer YOUR_JWT_TOKEN" \\');
  console.log('  -d \'{"userId": "USER_ID", "title": "Test", "body": "Hello!"}\'');
}

testFCMEndpoints().catch(console.error); 