// startup-health-check.js
// This script ensures the health check endpoint is available immediately

const express = require('express');
const app = express();

// Immediate health check endpoint (no dependencies)
app.get('/api/monitoring/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    message: 'Server is starting up',
    startup: true
  });
});

// Root health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    message: 'Server is starting up'
  });
});

// Basic route
app.get('/', (req, res) => {
  res.json({ 
    message: 'SNS Rooster API - Starting up',
    status: 'initializing',
    timestamp: new Date().toISOString()
  });
});

// Start server immediately
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`🚀 Startup health check server running on ${HOST}:${PORT}`);
  console.log(`✅ Health check available at: http://${HOST}:${PORT}/api/monitoring/health`);
  console.log(`✅ Root health check at: http://${HOST}:${PORT}/health`);
});

// Export for potential use
module.exports = app; 