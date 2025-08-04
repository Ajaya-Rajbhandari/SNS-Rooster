const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authenticateToken = async (req, res, next) => {
  try {
    // Remove JWT secret logging for security
    // console.log('JWT_SECRET used for verification:', process.env.JWT_SECRET);

    // Get token from header
    const authHeader = req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      console.log('BACKEND_AUTH_DEBUG: No token provided or incorrect format');
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Verify token using async/await
    console.log('DEBUG: Attempting to verify token:', token.substring(0, 50) + '...');
    const decoded = await jwt.verify(token, process.env.JWT_SECRET);
    console.log('DEBUG: Token decoded successfully:', { userId: decoded.userId, iat: decoded.iat, exp: decoded.exp });
    if (!decoded || !decoded.userId) {
      console.error('DEBUG: Invalid token payload');
      return res.status(403).json({ error: 'Invalid token payload' });
    }

    // Add timeout to database query to prevent hanging
    const user = await Promise.race([
      User.findById(decoded.userId).select('+companyId').maxTimeMS(5000),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Database query timeout')), 5000)
      )
    ]);

    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    req.user = { 
      userId: decoded.userId, 
      role: decoded.role,
      companyId: user.companyId ? user.companyId.toString() : null
    };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token has expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }
    if (error.message === 'Database query timeout') {
      console.error('Database timeout in auth middleware');
      return res.status(503).json({ message: 'Database temporarily unavailable' });
    }
    if (error.name === 'MongooseError' && error.message.includes('buffering timed out')) {
      console.error('MongoDB buffering timeout in auth middleware');
      return res.status(503).json({ message: 'Database connection timeout' });
    }
    console.error('Auth middleware error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Simple role authorization middleware
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    next();
  };
};

module.exports = {
  authenticateToken,
  authorizeRoles
};