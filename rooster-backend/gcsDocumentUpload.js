const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;
const fs = require('fs');
const path = require('path');

console.log('GCS Document Upload - Service account key exists:', fs.existsSync('serviceAccountKey.json'));
console.log('GCS Document Upload - Current directory:', process.cwd());
console.log('GCS Document Upload - Version: 1.1.0 - Fixed file filter and URL construction');

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const projectId = 'sns-rooster-8cca5';

const documentUpload = multer({
  storage: new MulterGoogleStorage({
    bucket: bucketName,
    projectId: projectId,
    keyFilename: 'serviceAccountKey.json',
    filename: (req, file, cb) => {
      cb(null, `documents/${Date.now()}-${file.originalname}`);
    },
    acl: 'publicRead', // or omit for private
  }),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB for documents
  fileFilter: (req, file, cb) => {
    console.log('GCS Document Upload - File filter called for:', file.originalname);
    console.log('GCS Document Upload - File mimetype:', file.mimetype);
    
    // Allow common document types
    const allowedTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif'
    ];
    
    const allowedExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt', '.jpg', '.jpeg', '.png', '.gif'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    console.log('GCS Document Upload - Allowed types:', allowedTypes);
    console.log('GCS Document Upload - Allowed extensions:', allowedExtensions);
    console.log('GCS Document Upload - File extension:', ext);
    console.log('GCS Document Upload - File mimetype in allowed types:', allowedTypes.includes(file.mimetype));
    console.log('GCS Document Upload - File extension in allowed extensions:', allowedExtensions.includes(ext));
    
    if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
      console.log('GCS Document Upload - File accepted');
      cb(null, true);
    } else {
      console.log('GCS Document Upload - File rejected');
      cb(new Error('Invalid file type. Only documents and images are allowed.'), false);
    }
  }
});

module.exports = documentUpload; 