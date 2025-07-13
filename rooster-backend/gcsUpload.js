const multer = require('multer');
const MulterGoogleStorage = require('multer-google-storage').storageEngine;
const fs = require('fs');

console.log('Service account key exists:', fs.existsSync('serviceAccountKey.json'));

const bucketName = 'sns-rooster-8cca5.firebasestorage.app';
const projectId = 'sns-rooster-8cca5'; // Your GCP project ID

const avatarUpload = multer({
  storage: new MulterGoogleStorage({
    bucket: bucketName,
    projectId: projectId,
    keyFilename: 'serviceAccountKey.json',
    filename: (req, file, cb) => {
      cb(null, `avatars/${Date.now()}-${file.originalname}`);
    },
    acl: 'publicRead', // or omit for private
  }),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

module.exports = avatarUpload; 