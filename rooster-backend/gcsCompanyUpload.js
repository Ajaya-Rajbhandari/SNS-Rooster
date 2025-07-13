const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const projectId = 'sns-rooster-8cca5';

const companyUpload = multer({
  storage: new MulterGoogleStorage({
    bucket: bucketName,
    projectId: projectId,
    keyFilename: 'serviceAccountKey.json',
    filename: (req, file, cb) => {
      cb(null, `company/${Date.now()}-${file.originalname}`);
    },
    acl: 'publicRead', // or omit for private
  }),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB for company files
  fileFilter: (req, file, cb) => {
    // Allow common image types for company logos
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif'
    ];
    
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG and GIF are allowed.'), false);
    }
  }
});

module.exports = companyUpload; 