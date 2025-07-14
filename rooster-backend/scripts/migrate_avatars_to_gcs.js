const fs = require('fs');
const path = require('path');
const { Storage } = require('@google-cloud/storage');
const mongoose = require('mongoose');
require('dotenv').config();

// Initialize Google Cloud Storage
const storage = new Storage({
  keyFilename: path.join(__dirname, '../serviceAccountKey.json'),
  projectId: 'sns-rooster-8cca5'
});

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const bucket = storage.bucket(bucketName);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');

// Import User model
const User = require('../models/User');

async function migrateAvatarsToGCS() {
  try {
    console.log('Starting avatar migration to Google Cloud Storage...');
    
    const avatarsDir = path.join(__dirname, '..', 'uploads', 'avatars');
    
    // Check if avatars directory exists
    if (!fs.existsSync(avatarsDir)) {
      console.log('No avatars directory found. Nothing to migrate.');
      return;
    }
    
    // Get all files in the avatars directory
    const files = fs.readdirSync(avatarsDir);
    console.log(`Found ${files.length} avatar files to migrate.`);
    
    let migratedCount = 0;
    let errorCount = 0;
    
    for (const file of files) {
      try {
        const filePath = path.join(avatarsDir, file);
        const fileStats = fs.statSync(filePath);
        
        // Skip directories
        if (fileStats.isDirectory()) {
          continue;
        }
        
        console.log(`Migrating: ${file}`);
        
        // Upload file to GCS
        const gcsFileName = `avatars/${Date.now()}-${file}`;
        await bucket.upload(filePath, {
          destination: gcsFileName,
          metadata: {
            contentType: getContentType(file),
          },
        });
        
        // Make the file publicly accessible
        await bucket.file(gcsFileName).makePublic();
        
        // Get the public URL
        const publicUrl = `https://storage.googleapis.com/${bucketName}/${gcsFileName}`;
        
        // Find and update users with this avatar
        const updateResult = await User.updateMany(
          {
            $or: [
              { avatar: { $regex: `${file}$` } },
              { profilePicture: { $regex: `${file}$` } }
            ]
          },
          {
            $set: {
              avatar: publicUrl,
              profilePicture: publicUrl
            }
          }
        );
        
        if (updateResult.modifiedCount > 0) {
          console.log(`  ✓ Updated ${updateResult.modifiedCount} user(s) with new GCS URL`);
          migratedCount++;
        } else {
          console.log(`  ⚠ No users found with avatar: ${file}`);
        }
        
      } catch (error) {
        console.error(`  ✗ Error migrating ${file}:`, error.message);
        errorCount++;
      }
    }
    
    console.log('\n=== Migration Summary ===');
    console.log(`Total files processed: ${files.length}`);
    console.log(`Successfully migrated: ${migratedCount}`);
    console.log(`Errors: ${errorCount}`);
    
    if (errorCount === 0) {
      console.log('\n✅ All avatars migrated successfully!');
      console.log('You can now safely delete the local avatars directory.');
    } else {
      console.log('\n⚠ Some files failed to migrate. Check the errors above.');
    }
    
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    mongoose.connection.close();
  }
}

function getContentType(filename) {
  const ext = path.extname(filename).toLowerCase();
  const contentTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp'
  };
  return contentTypes[ext] || 'application/octet-stream';
}

// Run the migration
migrateAvatarsToGCS(); 