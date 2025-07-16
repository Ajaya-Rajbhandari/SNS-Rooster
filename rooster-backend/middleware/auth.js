const jwt = require('jsonwebtoken');

const authenticateToken = async (req, res, next) => {
  try {
    console.log('JWT_SECRET used for verification:', process.env.JWT_SECRET);

    // Get token from header
    const authHeader = req.header('Authorization');
    // console.log('BACKEND_AUTH_DEBUG: Raw Authorization header:', authHeader);
    if (!authHeader?.startsWith('Bearer ')) {
      console.log('BACKEND_AUTH_DEBUG: No token provided or incorrect format');
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.replace('Bearer ', '');
    // console.log('BACKEND_AUTH_DEBUG: Token received:', token);

    // Verify token using async/await
    const decoded = await jwt.verify(token, process.env.JWT_SECRET);
    // console.log('BACKEND_AUTH_DEBUG: Decoded token:', decoded);

    if (!decoded || !decoded.userId) {
      console.error('DEBUG: Invalid token payload');
      return res.status(403).json({ error: 'Invalid token payload' });
    }

    req.user = { userId: decoded.userId, role: decoded.role };
    // console.log('DEBUG: req.user after assignment:', req.user);

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token has expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
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