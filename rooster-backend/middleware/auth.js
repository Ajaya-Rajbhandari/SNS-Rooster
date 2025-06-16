const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token, authorization denied' });
    }

    const token = authHeader.replace('Bearer ', '');

    console.log('AUTH MIDDLEWARE: Authorization header:', authHeader);
    console.log('AUTH MIDDLEWARE: Extracted token:', token);

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    console.log('AUTH MIDDLEWARE: Decoded token:', decoded);

    // Validate token payload
    if (!decoded || !decoded.userId) {
      console.error('AUTH MIDDLEWARE: Invalid token payload:', decoded);
      return res.status(401).json({ message: 'Invalid token payload' });
    }

    // Add user info to request
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token has expired' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token' });
    }
    console.error('AUTH MIDDLEWARE: Error during token verification:', error);
    console.error('Auth middleware error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = auth;