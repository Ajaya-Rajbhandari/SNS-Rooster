const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;
const fs = require('fs');
const path = require('path');

console.log('Service account key exists:', fs.existsSync('serviceAccountKey.json'));

const bucketName = 'sns-rooster-8cca5.firebasestorage.app'; // ✅ CORRECT
const projectId = 'sns-rooster-8cca5'; // Your GCP project ID

const avatarFileFilter = (req, file, cb) => {
  console.log('Avatar upload file:', file.originalname, 'MIME:', file.mimetype);
  const allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml'
  ];
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
  const ext = path.extname(file.originalname).toLowerCase();

  if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed for avatars.'), false);
  }
};

const avatarUpload = multer({
  storage: new MulterGoogleStorage({
    bucket: bucketName,
    projectId: projectId,
    keyFilename: 'serviceAccountKey.json',
    filename: (req, file, cb) => {
      cb(null, `avatars/${Date.now()}-${file.originalname}`);
    },
    acl: 'publicRead',
  }),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: avatarFileFilter
});

module.exports = avatarUpload; 