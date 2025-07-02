const mongoose = require('mongoose');

async function checkDatabase() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns_rooster');
    console.log('Connected to database: sns_rooster');
    
    // List all collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('\nCollections in database:');
    for (const collection of collections) {
      console.log(`  - ${collection.name}`);
    }
    
    // Check each collection for documents
    for (const collection of collections) {
      const count = await mongoose.connection.db.collection(collection.name).countDocuments();
      console.log(`  ${collection.name}: ${count} documents`);
    }
    
    // Try to connect to a different database name
    console.log('\nTrying alternative database names...');
    const alternativeNames = ['sns_rooster', 'sns-rooster', 'rooster', 'test', 'admin'];
    
    for (const dbName of alternativeNames) {
      try {
        const testConnection = await mongoose.createConnection(`mongodb://localhost:27017/${dbName}`);
        const collections = await testConnection.db.listCollections().toArray();
        const totalDocs = collections.reduce(async (acc, col) => {
          const count = await testConnection.db.collection(col.name).countDocuments();
          return acc + count;
        }, 0);
        
        console.log(`  ${dbName}: ${collections.length} collections, ${await totalDocs} total documents`);
        await testConnection.close();
      } catch (err) {
        console.log(`  ${dbName}: Connection failed`);
      }
    }
    
    mongoose.connection.close();
    console.log('\nDatabase connection closed');
    
  } catch (error) {
    console.error('Error:', error);
    mongoose.connection.close();
  }
}

checkDatabase(); 