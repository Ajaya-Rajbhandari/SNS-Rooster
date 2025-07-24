const mongoose = require('mongoose');
require('dotenv').config();

async function fixEmailIndex() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('users');

    // Get all indexes
    const indexes = await collection.indexes();
    console.log('Current indexes:', indexes.map(idx => idx.name));

    // Find the global email index
    const emailIndex = indexes.find(idx => 
      idx.key && idx.key.email === 1 && Object.keys(idx.key).length === 1
    );

    if (emailIndex) {
      console.log('Found global email index:', emailIndex.name);
      
      // Drop the global email index
      await collection.dropIndex(emailIndex.name);
      console.log('✅ Dropped global email index');
    } else {
      console.log('No global email index found');
    }

    // Check if compound index exists
    const compoundIndex = indexes.find(idx => 
      idx.key && idx.key.companyId === 1 && idx.key.email === 1
    );

    if (!compoundIndex) {
      console.log('Creating compound index for companyId + email...');
      await collection.createIndex(
        { companyId: 1, email: 1 }, 
        { unique: true, name: 'companyId_email_unique' }
      );
      console.log('✅ Created compound index');
    } else {
      console.log('Compound index already exists');
    }

    // Verify the fix by checking if we can create users with same email in different companies
    console.log('\nTesting the fix...');
    
    // Check if there are any users with the problematic email
    const existingUsers = await collection.find({ email: 'icerushhh@gmail.com' }).toArray();
    console.log(`Found ${existingUsers.length} users with email icerushhh@gmail.com:`);
    existingUsers.forEach(user => {
      console.log(`- User ID: ${user._id}, Company ID: ${user.companyId}, Role: ${user.role}`);
    });

    console.log('\n✅ Email index fix completed!');
    console.log('You can now create users with the same email in different companies.');

  } catch (error) {
    console.error('Error fixing email index:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

fixEmailIndex(); 