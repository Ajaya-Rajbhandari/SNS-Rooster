const fs = require('fs');
const path = require('path');

// Script to convert serviceAccountKey.json to environment variable format
function setupFirebaseEnv() {
  try {
    const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
    
    if (!fs.existsSync(serviceAccountPath)) {
      console.log('❌ serviceAccountKey.json not found in rooster-backend/');
      console.log('Please download it from Firebase Console and place it in the rooster-backend directory');
      return;
    }

    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    const serviceAccountString = JSON.stringify(serviceAccount);
    
    console.log('✅ Firebase service account loaded successfully');
    console.log('\n📋 For your cloud deployment, set this environment variable:');
    console.log('\nFIREBASE_SERVICE_ACCOUNT=' + serviceAccountString);
    
    console.log('\n🔒 Security Notes:');
    console.log('- Never commit serviceAccountKey.json to Git (already in .gitignore)');
    console.log('- Set FIREBASE_SERVICE_ACCOUNT as a secret environment variable in your cloud platform');
    console.log('- For Render: Go to your service → Environment → Add Environment Variable');
    console.log('- For Heroku: heroku config:set FIREBASE_SERVICE_ACCOUNT="..."');
    console.log('- For Railway: Add it in the Variables tab');
    
    console.log('\n🧪 To test locally:');
    console.log('1. Copy the FIREBASE_SERVICE_ACCOUNT value above');
    console.log('2. Create a .env file in rooster-backend/');
    console.log('3. Add: FIREBASE_SERVICE_ACCOUNT="..." (with the copied value)');
    console.log('4. Restart your server');
    
  } catch (error) {
    console.error('❌ Error setting up Firebase environment:', error.message);
  }
}

setupFirebaseEnv(); 