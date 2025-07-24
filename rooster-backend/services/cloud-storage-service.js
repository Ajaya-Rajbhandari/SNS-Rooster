const { Storage } = require('@google-cloud/storage');
const path = require('path');
const fs = require('fs');

class CloudStorageService {
  constructor() {
    this.storage = null;
    this.bucketName = 'sns-rooster-8cca5.appspot.com';
    this.projectId = 'sns-rooster-8cca5';
    
    // Initialize storage based on environment
    this.initializeStorage();
  }

  initializeStorage() {
    try {
      if (process.env.NODE_ENV === 'production') {
        // Production: Use service account key from environment
        if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
          this.storage = new Storage({
            projectId: this.projectId,
            keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
          });
          console.log('Cloud Storage initialized for production');
        } else {
          console.log('No Google Application Credentials found - using local storage for production');
          this.storage = null;
        }
      } else {
        // Development: Use local service account key if available
        const keyPath = path.join(__dirname, '../serviceAccountKey.json');
        if (fs.existsSync(keyPath)) {
          this.storage = new Storage({
            projectId: this.projectId,
            keyFilename: keyPath,
          });
          console.log('Cloud Storage initialized for development with service account');
        } else {
          console.log('No service account key found - using local storage for development');
          this.storage = null;
        }
      }
    } catch (error) {
      console.error('Failed to initialize cloud storage:', error);
      this.storage = null;
    }
  }

  async uploadFile(file, folder = 'company') {
    try {
      // If no cloud storage available, fall back to local storage
      if (!this.storage) {
        console.log('Cloud storage not available, using local storage');
        return this.uploadToLocalStorage(file, folder);
      }

      console.log('Uploading to cloud storage...');
      
      const bucket = this.storage.bucket(this.bucketName);
      const fileName = `${folder}/${Date.now()}_${file.originalname}`;
      const fileBuffer = fs.readFileSync(file.path);

      const fileUpload = bucket.file(fileName);
      
      await fileUpload.save(fileBuffer, {
        metadata: {
          contentType: file.mimetype,
        },
        public: true, // Make the file publicly accessible
      });

      const publicUrl = `https://storage.googleapis.com/${this.bucketName}/${fileName}`;
      console.log('File uploaded to cloud storage:', publicUrl);
      
      return publicUrl;
    } catch (error) {
      console.error('Cloud storage upload failed:', error);
      
      // Fall back to local storage if cloud storage fails
      console.log('Falling back to local storage...');
      return this.uploadToLocalStorage(file, folder);
    }
  }

  uploadToLocalStorage(file, folder = 'company') {
    const uploadsDir = path.join(__dirname, `../uploads/${folder}`);
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const fileName = `${Date.now()}_${file.originalname}`;
    const localPath = path.join(uploadsDir, fileName);
    
    // Copy the uploaded file to local storage
    fs.copyFileSync(file.path, localPath);
    
    // Create a URL that points to our local file
    const logoUrl = `/uploads/${folder}/${fileName}`;
    console.log('File uploaded to local storage:', logoUrl);
    
    return logoUrl;
  }

  async deleteFile(fileUrl) {
    try {
      if (!this.storage) {
        console.log('Cloud storage not available, skipping delete');
        return;
      }

      // Extract file path from URL
      const url = new URL(fileUrl);
      const filePath = url.pathname.replace(`/${this.bucketName}/`, '');
      
      const bucket = this.storage.bucket(this.bucketName);
      const file = bucket.file(filePath);
      
      await file.delete();
      console.log('File deleted from cloud storage:', filePath);
    } catch (error) {
      console.error('Failed to delete file from cloud storage:', error);
    }
  }

  getFileUrl(filePath) {
    if (filePath.startsWith('http')) {
      return filePath; // Already a full URL
    }
    
    if (process.env.NODE_ENV === 'production') {
      return `https://storage.googleapis.com/${this.bucketName}/${filePath}`;
    } else {
      // For development, construct local URL
      const baseUrl = process.env.BASE_URL || 'http://localhost:5000';
      return `${baseUrl}${filePath}`;
    }
  }
}

module.exports = new CloudStorageService(); 