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

// MongoDB Connection with proper configuration
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';

// Configure mongoose connection options
const mongooseOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 30000, // 30 seconds for server selection
  socketTimeoutMS: 45000, // 45 seconds for socket operations
  connectTimeoutMS: 30000, // 30 seconds for initial connection
  maxPoolSize: 10, // Maximum number of connections in the pool
  minPoolSize: 1, // Minimum number of connections in the pool
  maxIdleTimeMS: 30000, // Close connections after 30 seconds of inactivity
  retryWrites: true,
  w: 'majority',
  // Remove tlsAllowInvalidCertificates for production
  // tlsAllowInvalidCertificates: true, // Only for debugging SSL issues
};

console.debug('SERVER: Connecting to MongoDB with options:', {
  serverSelectionTimeoutMS: mongooseOptions.serverSelectionTimeoutMS,
  socketTimeoutMS: mongooseOptions.socketTimeoutMS,
  maxPoolSize: mongooseOptions.maxPoolSize
});

mongoose.connect(MONGODB_URI, mongooseOptions)
  .then(() => {
    Logger.info('Connected to MongoDB successfully');
    console.log('✅ MongoDB connection established');
    
    // Log connection status
    console.debug('MongoDB connection state:', mongoose.connection.readyState);
    
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
  .catch((err) => {
    Logger.error('MongoDB connection error:', err);
    console.error('❌ Failed to connect to MongoDB:', err.message);
    
    // Don't exit immediately, let the server start but log the error
    console.error('Server will start but database operations will fail');
  });

// Add connection event listeners for better monitoring
mongoose.connection.on('connected', () => {
  console.log('✅ Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Mongoose connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('⚠️ Mongoose disconnected from MongoDB');
});

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
  console.log('Shutting down server...');
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