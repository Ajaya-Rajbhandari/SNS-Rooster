const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { requireSuperAdmin, requirePermission } = require('../middleware/superAdmin');
const SuperAdminController = require('../controllers/super-admin-controller');

// Security middleware
const {
  superAdminLimiter,
  validateCompanyCreation,
  handleValidationErrors
} = require('../middleware/security');

// All routes require super admin authentication and rate limiting
router.use(authenticateToken);
router.use(requireSuperAdmin);
router.use(superAdminLimiter);

// ===== COMPANY MANAGEMENT =====

// Get all companies with pagination and filters
router.get('/companies', 
  requirePermission('manageCompanies'), 
  SuperAdminController.getAllCompanies
);

// Create new company
router.post('/companies', 
  requirePermission('manageCompanies'), 
  validateCompanyCreation,
  handleValidationErrors,
  SuperAdminController.createCompany
);

// Update company
router.put('/companies/:companyId', 
  requirePermission('manageCompanies'), 
  SuperAdminController.updateCompany
);

// Change company subscription plan
router.put('/companies/:companyId/subscription-plan', 
  requirePermission('manageCompanies'), 
  SuperAdminController.changeCompanySubscriptionPlan
);

// Delete company (soft delete)
router.delete('/companies/:companyId', 
  requirePermission('manageCompanies'), 
  SuperAdminController.deleteCompany
);

// Hard delete company (for development/testing)
router.delete('/companies/:companyId/hard', 
  requirePermission('manageCompanies'), 
  SuperAdminController.hardDeleteCompany
);

// ===== SUBSCRIPTION MANAGEMENT =====

// Get all subscription plans
router.get('/subscription-plans', 
  requirePermission('manageSubscriptions'), 
  SuperAdminController.getSubscriptionPlans
);

// Create subscription plan
router.post('/subscription-plans', 
  requirePermission('manageSubscriptions'), 
  SuperAdminController.createSubscriptionPlan
);

// Update subscription plan
router.put('/subscription-plans/:planId', 
  requirePermission('manageSubscriptions'), 
  SuperAdminController.updateSubscriptionPlan
);

// ===== USER MANAGEMENT =====

// Get all users with pagination and filters
router.get('/users', 
  requirePermission('manageUsers'), 
  SuperAdminController.getAllUsers
);

// Create new user
router.post('/users', 
  requirePermission('manageUsers'), 
  SuperAdminController.createUser
);

// Update user
router.put('/users/:userId', 
  requirePermission('manageUsers'), 
  SuperAdminController.updateUser
);

// Delete user
router.delete('/users/:userId', 
  requirePermission('manageUsers'), 
  SuperAdminController.deleteUser
);

// Reset user password
router.post('/users/:userId/reset-password', 
  requirePermission('manageUsers'), 
  SuperAdminController.resetUserPassword
);

// Change user password (with custom password)
router.post('/users/:userId/change-password', 
  requirePermission('manageUsers'), 
  SuperAdminController.changeUserPassword
);

// Unlock user account (clear lock and failed attempts)
router.post('/users/:userId/unlock', 
  requirePermission('manageUsers'), 
  SuperAdminController.unlockUserAccount
);

// ===== SYSTEM ANALYTICS =====

// Get system overview
router.get('/system/overview', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.getSystemOverview
);

// Get dashboard stats (alias for system overview)
router.get('/dashboard/stats', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.getDashboardStats
);

// Get comprehensive analytics data
router.get('/analytics', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.getAnalytics
);

// Get advanced user activity analytics
router.get('/analytics/user-activity', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.getUserActivityAnalytics
);

// Get company performance metrics
router.get('/analytics/company-performance', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.getCompanyPerformanceMetrics
);

// Generate custom reports
router.post('/analytics/reports', 
  requirePermission('viewAnalytics'), 
  SuperAdminController.generateCustomReport
);

// ===== SYSTEM SETTINGS =====

// Get system settings
router.get('/settings', 
  requirePermission('systemSettings'), 
  SuperAdminController.getSettings
);

// Update system settings
router.put('/settings', 
  requirePermission('systemSettings'), 
  SuperAdminController.updateSettings
);

module.exports = router; 