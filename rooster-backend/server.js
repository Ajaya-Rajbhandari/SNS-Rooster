// server.js: The ONLY entry point for the backend server.
// This file imports app.js, connects to MongoDB, and starts the server.
// Always use `node server.js` or `nodemon server.js` to run the backend.

const dotenv = require('dotenv');

// Load environment variables FIRST, before any other imports
dotenv.config();

// Import logger
const { Logger, console } = require('./config/logger');

const app = require('./app');
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

// Environment logging (only in development)
console.debug('JWT_SECRET configured:', !!process.env.JWT_SECRET);
console.debug('EMAIL_PROVIDER:', process.env.EMAIL_PROVIDER);
console.debug('RESEND_API_KEY configured:', !!process.env.RESEND_API_KEY);

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
mongoose.connect(MONGODB_URI, {
    tlsAllowInvalidCertificates: true, // Add this line for debugging
  })
  .then(() => {
    Logger.info('Connected to MongoDB');
    
    // Ensure upload directories exist
    const uploadDirs = [
      'uploads/avatars',
      'uploads/documents', 
      'uploads/company'
    ];
    
    uploadDirs.forEach(dir => {
      const fullPath = path.join(__dirname, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        console.debug(`Created upload directory: ${dir}`);
      }
    });
  })
  .catch((err) => Logger.error('MongoDB connection error:', err));

// Start server
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces
const server = app.listen(PORT, HOST, () => {
  Logger.info(`Server is running on ${HOST}:${PORT}`);
});

console.debug('SERVER: Initializing routes');
console.debug('SERVER: MongoDB URI:', MONGODB_URI);

// Close MongoDB connection on server close
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  Logger.info('MongoDB connection closed');
  process.exit(0);
});

process.on('exit', async () => {
  await mongoose.connection.close();
  Logger.info('MongoDB connection closed');
});

// Initialize background scheduler
require('./scheduler');

module.exports = server;