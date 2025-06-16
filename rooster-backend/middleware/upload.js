const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../uploads/avatars');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp and original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, 'avatar-' + uniqueSuffix + extension);
  }
});

// File filter to only allow images
const fileFilter = (req, file, cb) => {
  console.log('File validation - Original name:', file.originalname);
  console.log('File validation - Mimetype:', file.mimetype);
  
  const allowedExtensions = /\.(jpeg|jpg|png|gif|webp)$/i;
  const allowedMimetypes = /^image\/(jpeg|jpg|png|gif|webp)$/i;
  
  const extname = allowedExtensions.test(file.originalname.toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  console.log('Extension test result:', extname);
  console.log('Mimetype test result:', mimetype);

  // Accept file if extension is valid (some clients send incorrect mimetypes)
  // or if both extension and mimetype are valid
  if (extname && (mimetype || file.mimetype === 'application/octet-stream')) {
    console.log('File validation passed');
    return cb(null, true);
  } else {
    console.log('File validation failed');
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
  }
};

// Configure multer
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: fileFilter
});

module.exports = upload;