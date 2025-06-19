const jwt = require('jsonwebtoken');

const payload = {
  userId: '6849bc08d1865706c9eda8a6',
  email: 'testuser@example.com',
  role: 'employee',
};

const secret = 'aea3e03ce15df12d702bee0753ac6ee924ca1dccab84bea440aa01452f754ae4';

const token = jwt.sign(payload, secret, { expiresIn: '24h' });
console.log('Generated Test Token:', token);
