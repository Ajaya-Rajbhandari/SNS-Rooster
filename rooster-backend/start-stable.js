#!/usr/bin/env node

// Simple script to start the server without nodemon
// Use this when you want stable operation without auto-restart

console.log('🚀 Starting SNS Rooster Backend Server (Stable Mode)');
console.log('📝 No auto-restart - server will run until manually stopped');
console.log('⏹️  Press Ctrl+C to stop the server');
console.log('');

// Import and start the server
require('./server.js');

console.log('✅ Server started successfully!');
console.log('🌐 Access the API at: http://192.168.1.119:5000');
console.log('📊 Health check: http://192.168.1.119:5000/health'); 