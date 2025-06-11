const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Debug middleware to log all requests
app.use('/api/auth/login', (req, res, next) => {
  console.log('=== LOGIN REQUEST DEBUG ===');
  console.log('Method:', req.method);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('Raw body type:', typeof req.body);
  console.log('Email type:', typeof req.body.email);
  console.log('Password type:', typeof req.body.password);
  console.log('Email value:', req.body.email);
  console.log('Password value:', req.body.password);
  console.log('========================');
  next();
});

// Login route with detailed debugging
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    console.log('\n=== PROCESSING LOGIN ===');
    console.log('Extracted email:', email);
    console.log('Extracted password:', password);
    
    // Find user by email
    console.log('Searching for user with email:', email);
    const user = await User.findOne({ email });
    
    if (!user) {
      console.log('❌ User not found in database');
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    console.log('✅ User found:', user.email);
    console.log('User active:', user.isActive);
    
    // Check if user is active
    if (!user.isActive) {
      console.log('❌ User account is deactivated');
      return res.status(401).json({ message: 'Account is deactivated' });
    }
    
    // Verify password
    console.log('Comparing password...');
    console.log('Stored hash:', user.password);
    const isMatch = await user.comparePassword(password);
    console.log('Password match result:', isMatch);
    
    if (!isMatch) {
      console.log('❌ Password does not match');
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    
    console.log('✅ Login successful!');
    
    // Update last login
    user.lastLogin = new Date();
    await user.save();
    
    // Generate a simple response (no JWT for debugging)
    res.json({
      success: true,
      message: 'Login successful',
      user: {
        email: user.email,
        name: user.name,
        role: user.role
      }
    });
    
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Connect to MongoDB and start server
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    console.log('Connecting to MongoDB:', mongoURI);
    await mongoose.connect(mongoURI);
    console.log('✅ Connected to MongoDB');
    
    const PORT = 5001; // Use different port to avoid conflicts
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Debug server running on http://0.0.0.0:${PORT}`);
      console.log(`Test with: curl -X POST http://192.168.1.67:${PORT}/api/auth/login -H "Content-Type: application/json" -d '{"email":"testuser@example.com","password":"Test@123"}'`);
    });
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

connectDB();