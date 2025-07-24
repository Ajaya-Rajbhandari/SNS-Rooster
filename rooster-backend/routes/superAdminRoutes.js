const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { requireSuperAdmin, requirePermission } = require('../middleware/superAdmin');
const SuperAdminController = require('../controllers/super-admin-controller');

// All routes require super admin authentication
router.use(authenticateToken);
router.use(requireSuperAdmin);

// ===== COMPANY MANAGEMENT =====

// Get all companies with pagination and filters
router.get('/companies', 
  requirePermission('manageCompanies'), 
  SuperAdminController.getAllCompanies
);

// Create new company
router.post('/companies', 
  requirePermission('manageCompanies'), 
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

module.exports = router; 