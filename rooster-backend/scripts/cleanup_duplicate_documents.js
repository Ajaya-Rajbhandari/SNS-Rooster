const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI;

async function cleanupDuplicates() {
  await mongoose.connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');

  const users = await User.find({ 'documents.1': { $exists: true } }); // users with more than 1 document
  let totalCleaned = 0;

  for (const user of users) {
    const docsByType = {};
    for (const doc of user.documents) {
      const normType = (doc.type || '').toLowerCase().trim();
      if (!docsByType[normType]) docsByType[normType] = [];
      docsByType[normType].push(doc);
    }
    let changed = false;
    const newDocs = [];
    for (const [type, docs] of Object.entries(docsByType)) {
      if (docs.length > 1) {
        // Keep only the last one (most recent upload)
        const toKeep = docs[docs.length - 1];
        // Normalize the type field
        toKeep.type = type;
        newDocs.push(toKeep);
        // Delete old files
        for (let i = 0; i < docs.length - 1; i++) {
          const oldDoc = docs[i];
          if (oldDoc.path && oldDoc.path !== toKeep.path) {
            const docPath = path.join(__dirname, '..', oldDoc.path);
            fs.unlink(docPath, (err) => {
              if (err && err.code !== 'ENOENT') console.error('Error deleting duplicate document:', err);
            });
          }
        }
        changed = true;
      } else {
        // Normalize the type field
        docs[0].type = type;
        newDocs.push(docs[0]);
      }
    }
    if (changed) {
      user.documents = newDocs;
      await user.save();
      totalCleaned++;
      console.log(`Cleaned up user ${user.email}`);
    }
  }
  console.log(`Cleanup complete. Users cleaned: ${totalCleaned}`);
  await mongoose.disconnect();
}

cleanupDuplicates().catch(err => {
  console.error('Cleanup error:', err);
  process.exit(1);
}); 