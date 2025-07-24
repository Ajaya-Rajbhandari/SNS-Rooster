const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function checkUserPassword() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');

    console.log('\n🔍 Checking User Password...\n');

    const loginEmail = 'sns@snstechservices.com.au';
    const attemptedPassword = 'Admin@123';

    // Find the user
    const user = await usersCollection.findOne({ email: loginEmail });
    if (!user) {
      console.log(`❌ User with email ${loginEmail} not found`);
      return;
    }

    console.log(`👤 User Found:`);
    console.log(`   User ID: ${user._id}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Name: ${user.name}`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Company ID: ${user.companyId}`);

    console.log(`\n🔐 Password Analysis:`);
    console.log(`   Attempted Password: ${attemptedPassword}`);
    console.log(`   Stored Hash: ${user.password}`);
    console.log(`   Hash Length: ${user.password?.length || 0}`);

    // Test password match
    const passwordMatch = await bcrypt.compare(attemptedPassword, user.password);
    console.log(`   Password Match: ${passwordMatch ? '✅ YES' : '❌ NO'}`);

    if (!passwordMatch) {
      console.log(`\n🔧 Password Fix Options:`);
      console.log(`1. Reset password to 'Admin@123'`);
      console.log(`2. Check if password should be different`);
      console.log(`3. Generate new password hash`);

      // Try some common password variations
      console.log(`\n🧪 Testing Common Password Variations:`);
      const commonPasswords = [
        'Admin@123',
        'admin@123',
        'Admin123',
        'admin123',
        'Admin@123!',
        'Admin@123#',
        'password',
        '123456',
        'admin',
        'Admin'
      ];

      for (const testPassword of commonPasswords) {
        const match = await bcrypt.compare(testPassword, user.password);
        if (match) {
          console.log(`   ✅ MATCH FOUND: "${testPassword}"`);
          break;
        } else {
          console.log(`   ❌ "${testPassword}" - No match`);
        }
      }

      // Option to reset password
      console.log(`\n🔄 Resetting password to 'Admin@123'...`);
      const saltRounds = 10;
      const newHash = await bcrypt.hash(attemptedPassword, saltRounds);
      
      const updateResult = await usersCollection.updateOne(
        { _id: user._id },
        { $set: { password: newHash } }
      );

      if (updateResult.modifiedCount > 0) {
        console.log(`✅ Password successfully reset to 'Admin@123'`);
        console.log(`   New Hash: ${newHash}`);
        
        // Verify the new password works
        const verifyMatch = await bcrypt.compare(attemptedPassword, newHash);
        console.log(`   Verification: ${verifyMatch ? '✅ Password works' : '❌ Password still broken'}`);
        
        console.log(`\n🎉 Login should now work!`);
        console.log(`   Email: ${loginEmail}`);
        console.log(`   Password: ${attemptedPassword}`);
        console.log(`   Company: SNS Tech Services`);
      } else {
        console.log(`❌ Failed to reset password`);
      }
    } else {
      console.log(`\n✅ Password is correct!`);
      console.log(`   The issue might be elsewhere in the login process`);
    }

  } catch (error) {
    console.error('Error checking user password:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

checkUserPassword(); 