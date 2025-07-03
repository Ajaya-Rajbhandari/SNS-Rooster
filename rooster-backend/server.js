// server.js: The ONLY entry point for the backend server.
// This file imports app.js, connects to MongoDB, and starts the server.
// Always use `node server.js` or `nodemon server.js` to run the backend.

const app = require('./app');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

// Load environment variables
dotenv.config();

console.log('DEBUG: JWT_SECRET value from dotenv:', process.env.JWT_SECRET);

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
mongoose.connect(MONGODB_URI, {
    tlsAllowInvalidCertificates: true, // Add this line for debugging
  })
  .then(() => {
    console.log('Connected to MongoDB');
    
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
        console.log(`Created upload directory: ${dir}`);
      }
    });
  })
  .catch((err) => console.error('MongoDB connection error:', err));

// Start server
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Listen on all network interfaces
const server = app.listen(PORT, HOST, () => {
  console.log(`Server is running on ${HOST}:${PORT}`);
});

console.log('SERVER: Initializing routes');
console.log('SERVER: MongoDB URI:', MONGODB_URI);

// Close MongoDB connection on server close
process.on('SIGINT', async () => {
  await mongoose.connection.close();
  console.log('MongoDB connection closed');
  process.exit(0);
});

process.on('exit', async () => {
  await mongoose.connection.close();
  console.log('MongoDB connection closed');
});

// Initialize background scheduler
require('./scheduler');

module.exports = server;