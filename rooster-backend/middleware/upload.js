const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directories exist
const avatarsDir = path.join(__dirname, '../uploads/avatars');
const documentsDir = path.join(__dirname, '../uploads/documents');
const companyDir = path.join(__dirname, '../uploads/company');
if (!fs.existsSync(avatarsDir)) {
  fs.mkdirSync(avatarsDir, { recursive: true });
}
if (!fs.existsSync(documentsDir)) {
  fs.mkdirSync(documentsDir, { recursive: true });
}
if (!fs.existsSync(companyDir)) {
  fs.mkdirSync(companyDir, { recursive: true });
}

// Multer storage for avatars
const avatarStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, avatarsDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp and original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, 'avatar-' + uniqueSuffix + extension);
  }
});

// Multer storage for documents
const documentStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, documentsDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp and original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, 'document-' + uniqueSuffix + extension);
  }
});

// General multer storage (can be used for any file type)
const generalStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Default to company directory, but can be overridden by route logic
    cb(null, companyDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp and original extension
    const timestamp = Date.now();
    const extension = path.extname(file.originalname);
    cb(null, `company-logo-${timestamp}${extension}`);
  }
});

// File filter to only allow images for avatars
const avatarFileFilter = (req, file, cb) => {
  console.log('Avatar file validation - Original name:', file.originalname);
  console.log('Avatar file validation - Mimetype:', file.mimetype);
  
  const allowedExtensions = /\.(jpeg|jpg|png|gif|webp)$/i;
  const allowedMimetypes = /^image\/(jpeg|jpg|png|gif|webp)$/i;
  
  const extname = allowedExtensions.test(file.originalname.toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  console.log('Avatar extension test result:', extname);
  console.log('Avatar mimetype test result:', mimetype);

  // Accept file if extension is valid (some clients send incorrect mimetypes)
  // or if both extension and mimetype are valid
  if (extname && (mimetype || file.mimetype === 'application/octet-stream')) {
    console.log('Avatar file validation passed');
    return cb(null, true);
  } else {
    console.log('Avatar file validation failed');
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
  }
};

// File filter to allow images and pdf for documents
const documentFileFilter = (req, file, cb) => {
  console.log('Document file validation - Original name:', file.originalname);
  console.log('Document file validation - Mimetype:', file.mimetype);
  
  const allowedExtensions = /\.(jpeg|jpg|png|pdf)$/i;
  const allowedMimetypes = /^(image\/(jpeg|jpg|png)|application\/pdf)$/i;
  
  const extname = allowedExtensions.test(file.originalname.toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  console.log('Document extension test result:', extname);
  console.log('Document mimetype test result:', mimetype);

  // Accept file if extension is valid (some clients send incorrect mimetypes)
  // or if both extension and mimetype are valid
  if (extname && (mimetype || file.mimetype === 'application/octet-stream')) {
    console.log('Document file validation passed');
    return cb(null, true);
  } else {
    console.log('Document file validation failed');
    cb(new Error('Only PDF, JPG, or PNG files are allowed'));
  }
};

// General file filter for images (used for logos, etc.)
const imageFileFilter = (req, file, cb) => {
  console.log('Image file validation - Original name:', file.originalname);
  console.log('Image file validation - Mimetype:', file.mimetype);
  
  const allowedExtensions = /\.(jpeg|jpg|png|gif)$/i;
  const allowedMimetypes = /^image\/(jpeg|jpg|png|gif)$/i;
  
  const extname = allowedExtensions.test(file.originalname.toLowerCase());
  const mimetype = allowedMimetypes.test(file.mimetype);
  
  console.log('Image extension test result:', extname);
  console.log('Image mimetype test result:', mimetype);

  if (extname && (mimetype || file.mimetype === 'application/octet-stream')) {
    console.log('Image file validation passed');
    return cb(null, true);
  } else {
    console.log('Image file validation failed');
    cb(new Error('Only image files are allowed (JPEG, PNG, GIF)'));
  }
};

// General upload middleware (default export)
const upload = multer({
  storage: generalStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: imageFileFilter
});

// Export multiple uploaders and general upload as default
module.exports = upload;

module.exports.avatarUpload = multer({
  storage: avatarStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: avatarFileFilter
});

module.exports.documentUpload = multer({
  storage: documentStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: documentFileFilter
});