const fs = require('fs');
const path = require('path');
const { Storage } = require('@google-cloud/storage');
const mongoose = require('mongoose');
require('dotenv').config();

// Initialize Google Cloud Storage
const storage = new Storage({
  keyFilename: 'serviceAccountKey.json',
  projectId: 'sns-rooster-8cca5'
});

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const bucket = storage.bucket(bucketName);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns_rooster');

// Import models that might have document references
const User = require('../models/User');
const Employee = require('../models/Employee');

async function migrateDocumentsToGCS() {
  try {
    console.log('Starting document migration to Google Cloud Storage...');
    
    const documentsDir = path.join(__dirname, '..', 'uploads', 'documents');
    
    // Check if documents directory exists
    if (!fs.existsSync(documentsDir)) {
      console.log('No documents directory found. Nothing to migrate.');
      return;
    }
    
    // Get all files in the documents directory
    const files = fs.readdirSync(documentsDir);
    console.log(`Found ${files.length} document files to migrate.`);
    
    let migratedCount = 0;
    let errorCount = 0;
    
    for (const file of files) {
      try {
        const filePath = path.join(documentsDir, file);
        const fileStats = fs.statSync(filePath);
        
        // Skip directories
        if (fileStats.isDirectory()) {
          continue;
        }
        
        console.log(`Migrating: ${file}`);
        
        // Upload file to GCS
        const gcsFileName = `documents/${Date.now()}-${file}`;
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
        
        // Find and update any records that reference this document
        const oldPath = `/uploads/documents/${file}`;
        
        // Update User documents
        const userUpdateResult = await User.updateMany(
          {
            $or: [
              { documents: { $elemMatch: { path: oldPath } } },
              { 'documents.path': oldPath }
            ]
          },
          {
            $set: {
              'documents.$.path': publicUrl
            }
          }
        );
        
        // Update Employee documents
        const employeeUpdateResult = await Employee.updateMany(
          {
            $or: [
              { documents: { $elemMatch: { path: oldPath } } },
              { 'documents.path': oldPath }
            ]
          },
          {
            $set: {
              'documents.$.path': publicUrl
            }
          }
        );
        
        const totalUpdated = userUpdateResult.modifiedCount + employeeUpdateResult.modifiedCount;
        
        if (totalUpdated > 0) {
          console.log(`  ✓ Updated ${totalUpdated} record(s) with new GCS URL`);
          migratedCount++;
        } else {
          console.log(`  ⚠ No records found with document: ${file}`);
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
      console.log('\n✅ All documents migrated successfully!');
      console.log('You can now safely delete the local documents directory.');
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
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.txt': 'text/plain',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif'
  };
  return contentTypes[ext] || 'application/octet-stream';
}

// Run the migration
migrateDocumentsToGCS(); 