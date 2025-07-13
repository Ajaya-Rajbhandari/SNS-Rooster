const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;

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
    // Allow common document types
    const allowedTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
      'image/jpeg',
      'image/jpeg',
      'image/png',
      'image/gif'
    ];
    
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only documents and images are allowed.'), false);
    }
  }
});

module.exports = documentUpload; 