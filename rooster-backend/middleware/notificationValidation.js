const { body, validationResult } = require('express-validator');

// Validation rules for notifications
const notificationValidationRules = () => {
  return [
    body('title').notEmpty().withMessage('Title is required'),
    body('message').notEmpty().withMessage('Message is required'),
    body('userId').notEmpty().withMessage('User ID is required'),
    body('type').notEmpty().withMessage('Notification type is required'),
    body('data').optional().isObject().withMessage('Data must be an object if provided'),
  ];
};

// Middleware to check validation results
const validateNotification = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    console.error('Notification validation failed:', errors.array());
    return res.status(400).json({ 
      error: 'Notification validation failed',
      details: errors.array()
    });
  }
  next();
};

module.exports = {
  notificationValidationRules,
  validateNotification
};