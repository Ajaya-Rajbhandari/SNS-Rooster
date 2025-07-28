const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { requireSuperAdmin, requirePermission } = require('../middleware/superAdmin');
const BillingController = require('../controllers/billing-controller');

// Security middleware
const {
  superAdminLimiter,
  handleValidationErrors
} = require('../middleware/security');

// All routes require super admin authentication and rate limiting
router.use(authenticateToken);
router.use(requireSuperAdmin);
router.use(superAdminLimiter);

// ===== BILLING ENDPOINTS =====

// Get all payments
router.get('/payments', 
  requirePermission('manageBilling'), 
  BillingController.getPayments
);

// Get all invoices
router.get('/invoices', 
  requirePermission('manageBilling'), 
  BillingController.getInvoices
);

// Get all subscriptions
router.get('/subscriptions', 
  requirePermission('manageBilling'), 
  BillingController.getSubscriptions
);

// Get billing statistics
router.get('/stats', 
  requirePermission('manageBilling'), 
  BillingController.getBillingStats
);

// Generate invoice for a company
router.post('/invoices/generate', 
  requirePermission('manageBilling'), 
  BillingController.generateInvoice
);

// Send invoice
router.post('/invoices/:invoiceId/send', 
  requirePermission('manageBilling'), 
  BillingController.sendInvoice
);

// Download invoice
router.get('/invoices/:invoiceId/download', 
  requirePermission('manageBilling'), 
  BillingController.downloadInvoice
);

module.exports = router; 