const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;
const path = require('path');

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const projectId = 'sns-rooster-8cca5';

const companyFileFilter = (req, file, cb) => {
  console.log('Company logo upload file:', file.originalname, 'MIME:', file.mimetype);
  const allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif'
  ];
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
  const ext = path.extname(file.originalname).toLowerCase();

  if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
    console.log('Company logo file validation passed');
    cb(null, true);
  } else {
    console.log('Company logo file validation failed');
    cb(new Error('Only image files are allowed for company logos (JPEG, PNG, GIF).'), false);
  }
};

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
  fileFilter: companyFileFilter
});

module.exports = companyUpload; 