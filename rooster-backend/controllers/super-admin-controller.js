const Company = require('../models/Company');
const User = require('../models/User');
const SuperAdmin = require('../models/SuperAdmin');
const SubscriptionPlan = require('../models/SubscriptionPlan');
const bcrypt = require('bcrypt');

/**
 * Super Admin Controller
 * Handles all super admin operations
 */
class SuperAdminController {
  // Unlock user account (clear lock and failed attempts)
  static async unlockUserAccount(req, res) {
    try {
      const { userId } = req.params;
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      user.resetPasswordAttempts = 0;
      user.resetPasswordLastAttempt = null;
      user.accountLocked = false;
      await user.save();
      res.json({ success: true, message: 'User account unlocked.' });
    } catch (error) {
      console.error('Error unlocking user account:', error);
      res.status(500).json({ error: 'Failed to unlock user account' });
    }
  }
  
  // ===== COMPANY MANAGEMENT =====
  
  /**
   * Get all companies with pagination and filters
   */
  static async getAllCompanies(req, res) {
    try {
      const { page = 1, limit = 10, status, search, sortBy = 'createdAt', sortOrder = 'desc', includeArchived = false } = req.query;
      
      const filter = {};
      if (status) filter.status = status;
      
      // By default, exclude archived companies unless explicitly requested
      if (!includeArchived || includeArchived === 'false') {
        filter.archived = { $ne: true };
      }
      
      if (search) {
        filter.$or = [
          { name: { $regex: search, $options: 'i' } },
          { domain: { $regex: search, $options: 'i' } },
          { adminEmail: { $regex: search, $options: 'i' } }
        ];
      }
      
      const sort = {};
      sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
      
      const companies = await Company.find(filter)
        .populate('subscriptionPlan', 'name price features')
        .populate('createdBy', 'firstName lastName email')
        .populate('assignedSuperAdmin', 'firstName lastName email')
        .sort(sort)
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .exec();
      
      // Add employee count for each company
      const companiesWithEmployeeCount = await Promise.all(
        companies.map(async (company) => {
          const employeeCount = await User.countDocuments({ 
            companyId: company._id,
            role: { $ne: 'super_admin' }
          });
          
          return {
            ...company.toObject(),
            employeeCount
          };
        })
      );
      
      const total = await Company.countDocuments(filter);
      
      res.json({
        companies: companiesWithEmployeeCount,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
        total
      });
    } catch (error) {
      console.error('Error fetching companies:', error);
      res.status(500).json({ error: 'Failed to fetch companies' });
    }
  }
  
  /**
   * Get archived companies
   */
  static async getArchivedCompanies(req, res) {
    try {
      const { page = 1, limit = 10, search, sortBy = 'archivedAt', sortOrder = 'desc' } = req.query;
      
      const filter = { archived: true };
      
      if (search) {
        filter.$or = [
          { name: { $regex: search, $options: 'i' } },
          { domain: { $regex: search, $options: 'i' } },
          { adminEmail: { $regex: search, $options: 'i' } }
        ];
      }
      
      const sort = {};
      sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
      
      const companies = await Company.find(filter)
        .populate('subscriptionPlan', 'name price features')
        .populate('createdBy', 'firstName lastName email')
        .populate('assignedSuperAdmin', 'firstName lastName email')
        .populate('archivedBy', 'firstName lastName email')
        .sort(sort)
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .exec();
      
      // Add employee count for each company
      const companiesWithEmployeeCount = await Promise.all(
        companies.map(async (company) => {
          const employeeCount = await User.countDocuments({ 
            companyId: company._id,
            role: { $ne: 'super_admin' }
          });
          
          return {
            ...company.toObject(),
            employeeCount
          };
        })
      );
      
      const total = await Company.countDocuments(filter);
      
      res.json({
        companies: companiesWithEmployeeCount,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
        total
      });
    } catch (error) {
      console.error('Error fetching archived companies:', error);
      res.status(500).json({ error: 'Failed to fetch archived companies' });
    }
  }

  /**
   * Create a new company
   */
  static async createCompany(req, res) {
    try {
      const {
        name,
        domain,
        subdomain,
        adminEmail,
        adminPassword,
        adminFirstName,
        adminLastName,
        contactPhone,
        address,
        subscriptionPlanId,
        notes,
        // Custom plan fields
        isCustomPlan,
        customFeatures,
        customLimits
      } = req.body;

      console.log('Creating company with data:', {
        name,
        domain,
        subdomain,
        adminEmail,
        subscriptionPlanId,
        isCustomPlan,
        customFeatures,
        customLimits
      });

      // Validate required fields
      if (!name || !domain || !subdomain || !adminEmail || !adminPassword) {
        return res.status(400).json({
          error: 'Missing required fields',
          message: 'Name, domain, subdomain, adminEmail, and adminPassword are required'
        });
      }

      // Check if domain or subdomain already exists
      const existingCompany = await Company.findOne({
        $or: [
          { domain: domain.toLowerCase() },
          { subdomain: subdomain.toLowerCase() }
        ]
      });

      if (existingCompany) {
        return res.status(400).json({
          error: 'Domain or subdomain already exists',
          message: 'Please choose a different domain or subdomain'
        });
      }

      // Check if admin email already exists
      const existingUser = await User.findOne({ email: adminEmail.toLowerCase() });
      if (existingUser) {
        return res.status(400).json({
          error: 'Admin email already exists',
          message: 'Please choose a different admin email'
        });
      }

      let subscriptionPlan = null;
      let companyFeatures = {};
      let companyLimits = {};

      // Handle custom plan
      if (isCustomPlan && customFeatures && customLimits) {
        console.log('Creating company with custom plan');
        
        // Use custom features and limits
        companyFeatures = {
          attendance: customFeatures.attendance ?? true,
          payroll: customFeatures.payroll ?? true,
          leaveManagement: customFeatures.leaveManagement ?? true,
          analytics: customFeatures.analytics ?? false,
          documentManagement: customFeatures.documentManagement ?? true,
          notifications: customFeatures.notifications ?? true,
          customBranding: customFeatures.customBranding ?? false,
          apiAccess: customFeatures.apiAccess ?? false,
          multiLocation: customFeatures.multiLocation ?? false,
          advancedReporting: customFeatures.advancedReporting ?? false,
          timeTracking: customFeatures.timeTracking ?? true,
          expenseManagement: customFeatures.expenseManagement ?? false,
          performanceReviews: customFeatures.performanceReviews ?? false,
          trainingManagement: customFeatures.trainingManagement ?? false
        };

        companyLimits = {
          maxEmployees: customLimits.maxEmployees ?? 10,
          maxStorageGB: customLimits.maxStorageGB ?? 5,
          retentionDays: 365,
          maxApiCallsPerDay: customLimits.maxApiCallsPerDay ?? 1000,
          maxLocations: customLimits.maxLocations ?? 1
        };

        // Create a temporary subscription plan reference (null for custom plans)
        subscriptionPlan = null;
      } else {
        // Handle predefined subscription plan
        if (!subscriptionPlanId) {
          return res.status(400).json({
            error: 'Subscription plan is required',
            message: 'Please select a subscription plan or create a custom plan'
          });
        }

        subscriptionPlan = await SubscriptionPlan.findById(subscriptionPlanId);
        if (!subscriptionPlan) {
          return res.status(400).json({
            error: 'Invalid subscription plan',
            message: 'The specified subscription plan does not exist'
          });
        }

        // Use subscription plan features and limits
        companyFeatures = {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: subscriptionPlan.features.analytics,
          documentManagement: true,
          notifications: true,
          customBranding: subscriptionPlan.features.customBranding,
          apiAccess: subscriptionPlan.features.apiAccess,
          multiLocation: false,
          advancedReporting: subscriptionPlan.features.advancedReporting,
          timeTracking: true,
          expenseManagement: false,
          performanceReviews: false,
          trainingManagement: false
        };

        companyLimits = {
          maxEmployees: subscriptionPlan.features.maxEmployees,
          maxStorageGB: 5,
          retentionDays: subscriptionPlan.features.dataRetention,
          maxApiCallsPerDay: subscriptionPlan.features.apiAccess ? 1000 : 0,
          maxLocations: 1
        };
      }
      
      // Create company
      const company = new Company({
        name,
        domain,
        subdomain,
        adminEmail,
        contactPhone,
        address,
        subscriptionPlan: subscriptionPlan?._id || null, // null for custom plans
        createdBy: req.user.userId,
        assignedSuperAdmin: req.user.userId,
        notes,
        features: companyFeatures,
        limits: companyLimits,
        status: 'active', // Explicitly set to active
        // Add custom plan flag
        isCustomPlan: isCustomPlan || false,
        customPlanData: isCustomPlan ? {
          features: customFeatures,
          limits: customLimits
        } : null
      });
      
      await company.save();
      
      // Create admin user
      const adminUser = new User({
        companyId: company._id,
        email: adminEmail,
        password: adminPassword,
        firstName: adminFirstName || 'Admin',
        lastName: adminLastName || 'User',
        role: 'admin',
        isEmailVerified: true,
        isActive: true
      });
      
      await adminUser.save();
      
      // Initialize AdminSettings with company information
      const AdminSettings = require('../models/AdminSettings');
      const companyInfo = {
        name: company.name,
        legalName: company.name,
        address: company.address?.street || '',
        city: company.address?.city || '',
        state: company.address?.state || '',
        postalCode: company.address?.postalCode || '',
        country: company.address?.country || 'Nepal',
        phone: company.contactPhone || company.phone || '',
        email: company.adminEmail || company.email || '',
        website: company.website || '',
        description: company.description || '',
        industry: company.industry || '',
        employeeCount: '1-10' // Default for new companies
      };
      
      await AdminSettings.updateSettings({ companyInfo }, company._id);
      console.log('AdminSettings initialized with company info for:', company.name);
      
      // Populate company data for response
      await company.populate('subscriptionPlan', 'name price features');
      
      console.log('Company created successfully:', company._id);
      
      res.status(201).json({
        success: true,
        message: 'Company created successfully',
        company: {
          _id: company._id,
          name: company.name,
          domain: company.domain,
          subdomain: company.subdomain,
          adminEmail: company.adminEmail,
          subscriptionPlan: company.subscriptionPlan,
          isCustomPlan: company.isCustomPlan,
          features: company.features,
          limits: company.limits,
          status: company.status
        }
      });
      
    } catch (error) {
      console.error('Error creating company:', error);
      res.status(500).json({
        error: 'Failed to create company',
        message: error.message
      });
    }
  }
  
  /**
   * Update company details
   */
  static async updateCompany(req, res) {
    try {
      const { companyId } = req.params;
      const updateData = req.body;
      
      console.log('Updating company:', companyId, 'with data:', updateData);
      
      const company = await Company.findById(companyId);
      if (!company) {
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      // If updating subscription plan, validate and update related fields
      if (updateData.subscriptionPlan) {
        console.log('Updating subscription plan to:', updateData.subscriptionPlan);
        
        // Validate the subscription plan exists
        const subscriptionPlan = await SubscriptionPlan.findById(updateData.subscriptionPlan);
        if (!subscriptionPlan) {
          return res.status(400).json({
            error: 'Invalid subscription plan',
            message: 'The specified subscription plan does not exist'
          });
        }
        
        // Update company features and limits based on the new plan
        company.features = {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: subscriptionPlan.features.analytics,
          documentManagement: true,
          notifications: true,
          customBranding: subscriptionPlan.features.customBranding,
          apiAccess: subscriptionPlan.features.apiAccess,
          multiLocation: false,
          advancedReporting: subscriptionPlan.features.advancedReporting,
          timeTracking: true,
          expenseManagement: false,
          performanceReviews: false,
          trainingManagement: false
        };
        
        company.limits = {
          maxEmployees: subscriptionPlan.features.maxEmployees,
          maxStorageGB: 5,
          retentionDays: subscriptionPlan.features.dataRetention,
          maxApiCallsPerDay: subscriptionPlan.features.apiAccess ? 1000 : 0,
          maxLocations: 1
        };
        
        console.log('Updated company features:', company.features);
        console.log('Updated company limits:', company.limits);
      }
      
      // Update other fields, but preserve required fields
      const fieldsToUpdate = { ...updateData };
      
      // Preserve required fields that shouldn't be overwritten
      delete fieldsToUpdate.createdBy;
      delete fieldsToUpdate.assignedSuperAdmin;
      
      Object.assign(company, fieldsToUpdate);
      
      console.log('Saving company with data:', {
        subscriptionPlan: company.subscriptionPlan,
        features: company.features,
        limits: company.limits
      });
      
      await company.save();
      
      await company.populate('subscriptionPlan', 'name price features');
      
      res.json({
        message: 'Company updated successfully',
        company
      });
    } catch (error) {
      console.error('Error updating company:', error);
      
      // Handle validation errors specifically
      if (error.name === 'ValidationError') {
        const validationErrors = Object.keys(error.errors).map(key => ({
          field: key,
          message: error.errors[key].message
        }));
        
        return res.status(400).json({
          error: 'Validation failed',
          message: 'Company data validation failed',
          details: validationErrors
        });
      }
      
      res.status(500).json({ 
        error: 'Failed to update company',
        details: error.message 
      });
    }
  }
  
  /**
   * Delete company (soft delete)
   */
  static async deleteCompany(req, res) {
    try {
      const { companyId } = req.params;
      
      console.log('Attempting to delete company:', companyId);
      
      const company = await Company.findByIdAndUpdate(
        companyId,
        { status: 'cancelled' },
        { new: true, runValidators: false }
      );
      
      if (!company) {
        console.log('Company not found:', companyId);
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      console.log('Found company:', company.name, 'Current status:', company.status);
      
      console.log('Company status updated to cancelled');
      
      res.json({
        message: 'Company deleted successfully',
        companyId: company._id
      });
    } catch (error) {
      console.error('Error deleting company:', error);
      res.status(500).json({ 
        error: 'Failed to delete company',
        details: error.message 
      });
    }
  }
  
  /**
   * Archive company (soft delete with data preservation)
   */
  static async archiveCompany(req, res) {
    try {
      const { companyId } = req.params;
      const { reason } = req.body;
      
      console.log('Attempting to archive company:', companyId);
      
      const company = await Company.findById(companyId);
      
      if (!company) {
        console.log('Company not found:', companyId);
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      if (company.archived) {
        return res.status(400).json({
          error: 'Company already archived',
          message: 'This company is already archived'
        });
      }
      
      // Archive the company (preserve all data)
      const archivedCompany = await Company.findByIdAndUpdate(
        companyId,
        {
          status: 'archived',
          archived: true,
          archivedAt: new Date(),
          archivedBy: req.user._id,
          archiveReason: reason || 'Archived by super admin'
        },
        { new: true, runValidators: false }
      );
      
      console.log('Company archived:', archivedCompany.name);
      
      res.json({
        message: 'Company archived successfully',
        companyId: archivedCompany._id,
        companyName: archivedCompany.name,
        archivedAt: archivedCompany.archivedAt
      });
    } catch (error) {
      console.error('Error archiving company:', error);
      res.status(500).json({ 
        error: 'Failed to archive company',
        details: error.message 
      });
    }
  }

  /**
   * Restore archived company
   */
  static async restoreCompany(req, res) {
    try {
      const { companyId } = req.params;
      
      console.log('Attempting to restore company:', companyId);
      
      const company = await Company.findById(companyId);
      
      if (!company) {
        console.log('Company not found:', companyId);
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      if (!company.archived) {
        return res.status(400).json({
          error: 'Company not archived',
          message: 'This company is not archived'
        });
      }
      
      // Restore the company
      const restoredCompany = await Company.findByIdAndUpdate(
        companyId,
        {
          status: 'active',
          archived: false,
          archivedAt: null,
          archivedBy: null,
          archiveReason: null
        },
        { new: true, runValidators: false }
      );
      
      console.log('Company restored:', restoredCompany.name);
      
      res.json({
        message: 'Company restored successfully',
        companyId: restoredCompany._id,
        companyName: restoredCompany.name
      });
    } catch (error) {
      console.error('Error restoring company:', error);
      res.status(500).json({ 
        error: 'Failed to restore company',
        details: error.message 
      });
    }
  }

  /**
   * Hard delete archived company
   */
  static async hardDeleteArchivedCompany(req, res) {
    try {
      const { companyId } = req.params;
      
      console.log('Attempting to hard delete archived company:', companyId);
      
      const company = await Company.findById(companyId);
      
      if (!company) {
        console.log('Company not found:', companyId);
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      if (!company.archived) {
        return res.status(400).json({
          error: 'Company not archived',
          message: 'Only archived companies can be permanently deleted'
        });
      }
      
      // Check if company has any users
      const userCount = await User.countDocuments({ companyId });
      if (userCount > 0) {
        return res.status(400).json({
          error: 'Cannot delete company with existing users',
          message: `Company has ${userCount} users. Please transfer or delete users first.`
        });
      }
      
      // Hard delete the archived company
      const deletedCompany = await Company.findByIdAndDelete(companyId);
      
      console.log('Archived company hard deleted:', deletedCompany.name);
      
      res.json({
        message: 'Company permanently deleted',
        companyId: deletedCompany._id,
        companyName: deletedCompany.name
      });
    } catch (error) {
      console.error('Error hard deleting archived company:', error);
      res.status(500).json({ 
        error: 'Failed to delete company',
        details: error.message 
      });
    }
  }

  /**
   * Hard delete company (for development/testing purposes)
   */
  static async hardDeleteCompany(req, res) {
    try {
      const { companyId } = req.params;
      
      console.log('Attempting to hard delete company:', companyId);
      
      // Check if company has any users
      const userCount = await User.countDocuments({ companyId });
      if (userCount > 0) {
        return res.status(400).json({
          error: 'Cannot delete company with existing users',
          message: `Company has ${userCount} users. Please transfer or delete users first.`
        });
      }
      
      // Hard delete the company
      const deletedCompany = await Company.findByIdAndDelete(companyId);
      
      if (!deletedCompany) {
        console.log('Company not found:', companyId);
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }
      
      console.log('Company hard deleted:', deletedCompany.name);
      
      res.json({
        message: 'Company permanently deleted',
        companyId: deletedCompany._id,
        companyName: deletedCompany.name
      });
    } catch (error) {
      console.error('Error hard deleting company:', error);
      res.status(500).json({ 
        error: 'Failed to delete company',
        details: error.message 
      });
    }
  }

  /**
   * Change company subscription plan
   */
  static async changeCompanySubscriptionPlan(req, res) {
    try {
      const { companyId } = req.params;
      const { 
        isCustomPlan, 
        subscriptionPlanId, 
        customFeatures, 
        customLimits 
      } = req.body;

      console.log('Changing subscription plan for company:', companyId, {
        isCustomPlan,
        subscriptionPlanId,
        customFeatures,
        customLimits
      });

      const company = await Company.findById(companyId);
      if (!company) {
        return res.status(404).json({
          error: 'Company not found',
          message: 'The specified company does not exist'
        });
      }

      let newFeatures = {};
      let newLimits = {};

      // Handle custom plan
      if (isCustomPlan && customFeatures && customLimits) {
        console.log('Setting custom plan for company');
        
        newFeatures = {
          attendance: customFeatures.attendance ?? true,
          payroll: customFeatures.payroll ?? true,
          leaveManagement: customFeatures.leaveManagement ?? true,
          analytics: customFeatures.analytics ?? false,
          documentManagement: customFeatures.documentManagement ?? true,
          notifications: customFeatures.notifications ?? true,
          customBranding: customFeatures.customBranding ?? false,
          apiAccess: customFeatures.apiAccess ?? false,
          multiLocation: customFeatures.multiLocation ?? false,
          advancedReporting: customFeatures.advancedReporting ?? false,
          timeTracking: customFeatures.timeTracking ?? true,
          expenseManagement: customFeatures.expenseManagement ?? false,
          performanceReviews: customFeatures.performanceReviews ?? false,
          trainingManagement: customFeatures.trainingManagement ?? false
        };

        newLimits = {
          maxEmployees: customLimits.maxEmployees ?? 10,
          maxStorageGB: customLimits.maxStorageGB ?? 5,
          retentionDays: 365,
          maxApiCallsPerDay: customLimits.maxApiCallsPerDay ?? 1000,
          maxLocations: customLimits.maxLocations ?? 1
        };

        // Update company with custom plan
        company.subscriptionPlan = null; // null for custom plans
        company.isCustomPlan = true;
        company.customPlanData = {
          features: customFeatures,
          limits: customLimits
        };
      } else {
        // Handle predefined subscription plan
        if (!subscriptionPlanId) {
          return res.status(400).json({
            error: 'Subscription plan is required',
            message: 'Please select a subscription plan or create a custom plan'
          });
        }

        const subscriptionPlan = await SubscriptionPlan.findById(subscriptionPlanId);
        if (!subscriptionPlan) {
          return res.status(400).json({
            error: 'Invalid subscription plan',
            message: 'The specified subscription plan does not exist'
          });
        }

        console.log('Setting predefined plan:', subscriptionPlan.name);

        newFeatures = {
          attendance: true,
          payroll: true,
          leaveManagement: true,
          analytics: subscriptionPlan.features.analytics,
          documentManagement: true,
          notifications: true,
          customBranding: subscriptionPlan.features.customBranding,
          apiAccess: subscriptionPlan.features.apiAccess,
          multiLocation: false,
          advancedReporting: subscriptionPlan.features.advancedReporting,
          timeTracking: true,
          expenseManagement: false,
          performanceReviews: false,
          trainingManagement: false
        };

        newLimits = {
          maxEmployees: subscriptionPlan.features.maxEmployees,
          maxStorageGB: 5,
          retentionDays: subscriptionPlan.features.dataRetention,
          maxApiCallsPerDay: subscriptionPlan.features.apiAccess ? 1000 : 0,
          maxLocations: 1
        };

        // Update company with predefined plan
        company.subscriptionPlan = subscriptionPlanId;
        company.isCustomPlan = false;
        company.customPlanData = null;
      }

      // Update company features and limits
      company.features = newFeatures;
      company.limits = newLimits;

      await company.save();
      await company.populate('subscriptionPlan', 'name price features');

      console.log('Company subscription plan updated successfully');

      res.json({
        success: true,
        message: 'Company subscription plan updated successfully',
        company: {
          _id: company._id,
          name: company.name,
          subscriptionPlan: company.subscriptionPlan,
          isCustomPlan: company.isCustomPlan,
          features: company.features,
          limits: company.limits
        }
      });

    } catch (error) {
      console.error('Error changing company subscription plan:', error);
      res.status(500).json({
        error: 'Failed to change company subscription plan',
        message: error.message
      });
    }
  }
  
  // ===== SUBSCRIPTION MANAGEMENT =====
  
  /**
   * Get all subscription plans
   */
  static async getSubscriptionPlans(req, res) {
    try {
      const plans = await SubscriptionPlan.find({ isActive: true }).sort('sortOrder');
      res.json({ plans });
    } catch (error) {
      console.error('Error fetching subscription plans:', error);
      res.status(500).json({ error: 'Failed to fetch subscription plans' });
    }
  }
  
  /**
   * Create subscription plan
   */
  static async createSubscriptionPlan(req, res) {
    try {
      const planData = req.body;
      
      const plan = new SubscriptionPlan(planData);
      await plan.save();
      
      res.status(201).json({
        message: 'Subscription plan created successfully',
        plan
      });
    } catch (error) {
      console.error('Error creating subscription plan:', error);
      res.status(500).json({ error: 'Failed to create subscription plan' });
    }
  }
  
  /**
   * Update subscription plan
   */
  static async updateSubscriptionPlan(req, res) {
    try {
      const { planId } = req.params;
      const updateData = req.body;
      
      const plan = await SubscriptionPlan.findByIdAndUpdate(
        planId,
        updateData,
        { new: true }
      );
      
      if (!plan) {
        return res.status(404).json({
          error: 'Subscription plan not found',
          message: 'The specified subscription plan does not exist'
        });
      }
      
      res.json({
        message: 'Subscription plan updated successfully',
        plan
      });
    } catch (error) {
      console.error('Error updating subscription plan:', error);
      res.status(500).json({ error: 'Failed to update subscription plan' });
    }
  }
  
  // ===== SYSTEM ANALYTICS =====
  
  /**
   * Get system overview
   */
  static async getSystemOverview(req, res) {
    try {
      const [
        totalCompanies,
        activeCompanies,
        totalUsers,
        totalEmployees,
        subscriptionPlans
      ] = await Promise.all([
        Company.countDocuments(),
        Company.countDocuments({ status: 'active' }),
        User.countDocuments(),
        User.countDocuments({ role: 'employee' }),
        SubscriptionPlan.countDocuments({ isActive: true })
      ]);
      
      res.json({
        overview: {
          totalCompanies,
          activeCompanies,
          totalUsers,
          totalEmployees,
          subscriptionPlans
        }
      });
    } catch (error) {
      console.error('Error fetching system overview:', error);
      res.status(500).json({ error: 'Failed to fetch system overview' });
    }
  }

  /**
   * Get dashboard stats (formatted for admin portal)
   */
  static async getDashboardStats(req, res) {
    try {
      const [
        totalCompanies,
        activeCompanies,
        totalUsers,
        totalEmployees,
        totalPlans,
        monthlyRevenue
      ] = await Promise.all([
        Company.countDocuments(),
        Company.countDocuments({ status: 'active' }),
        User.countDocuments(),
        User.countDocuments({ role: 'employee' }),
        SubscriptionPlan.countDocuments({ isActive: true }),
        // Calculate monthly revenue (placeholder for now)
        Promise.resolve(0)
      ]);
      
      res.json({
        totalCompanies,
        totalUsers,
        totalPlans,
        monthlyRevenue,
        activeCompanies,
        totalEmployees
      });
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
      res.status(500).json({ error: 'Failed to fetch dashboard stats' });
    }
  }

  /**
   * Get comprehensive analytics data
   */
  static async getAnalytics(req, res) {
    try {
      const { timeRange = '30d' } = req.query;
      
      // Calculate date range
      const now = new Date();
      let startDate;
      switch (timeRange) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        case '1y':
          startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      // Get overview data
      const [
        totalCompanies,
        activeCompanies,
        totalUsers,
        totalEmployees,
        subscriptionPlans
      ] = await Promise.all([
        Company.countDocuments(),
        Company.countDocuments({ status: 'active' }),
        User.countDocuments(),
        User.countDocuments({ role: 'employee' }),
        SubscriptionPlan.find({ isActive: true })
      ]);

      // Calculate growth rates (mock data for now)
      const monthlyGrowth = 12.5;
      const userGrowth = 8.3;
      const totalRevenue = 125000; // Mock revenue data

      // Generate revenue data (mock data)
      const revenueData = [];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
      let baseRevenue = 85000;
      let baseSubscriptions = 32;
      
      months.forEach((month, index) => {
        const growth = 1 + (index * 0.05);
        revenueData.push({
          month,
          revenue: Math.round(baseRevenue * growth),
          subscriptions: Math.round(baseSubscriptions + (index * 2))
        });
      });

      // Generate company growth data
      const companyGrowth = [];
      let baseCompanies = 28;
      months.forEach((month, index) => {
        companyGrowth.push({
          month,
          newCompanies: Math.floor(Math.random() * 5) + 5,
          activeCompanies: baseCompanies + (index * 2)
        });
      });

      // Generate user activity data (last 7 days)
      const userActivity = [];
      const last7Days = [];
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
        last7Days.push(date.toISOString().split('T')[0]);
      }
      
      let baseUsers = 1150;
      last7Days.forEach((date, index) => {
        userActivity.push({
          date,
          activeUsers: baseUsers + (index * 15),
          newUsers: Math.floor(Math.random() * 20) + 40
        });
      });

      // Get subscription distribution
      const subscriptionDistribution = [];
      const planCounts = await Company.aggregate([
        {
          $lookup: {
            from: 'subscriptionplans',
            localField: 'subscriptionPlan',
            foreignField: '_id',
            as: 'plan'
          }
        },
        {
          $group: {
            _id: '$plan.name',
            count: { $sum: 1 }
          }
        }
      ]);

      // If no real data, use mock data
      if (planCounts.length === 0) {
        subscriptionDistribution.push(
          { plan: 'Basic', companies: 15, percentage: 33.3 },
          { plan: 'Professional', companies: 18, percentage: 40.0 },
          { plan: 'Enterprise', companies: 8, percentage: 17.8 },
          { plan: 'Custom', companies: 4, percentage: 8.9 }
        );
      } else {
        const total = planCounts.reduce((sum, plan) => sum + plan.count, 0);
        planCounts.forEach(plan => {
          subscriptionDistribution.push({
            plan: plan._id[0] || 'Unknown',
            companies: plan.count,
            percentage: Math.round((plan.count / total) * 100)
          });
        });
      }

      // Get top companies
      const topCompanies = await Company.aggregate([
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: 'companyId',
            as: 'users'
          }
        },
        {
          $project: {
            name: 1,
            status: 1,
            userCount: { $size: '$users' },
            revenue: { $multiply: [{ $size: '$users' }, 500] } // Mock revenue calculation
          }
        },
        {
          $sort: { userCount: -1 }
        },
        {
          $limit: 5
        }
      ]);

      // Format top companies data
      const formattedTopCompanies = topCompanies.map(company => ({
        name: company.name,
        users: company.userCount,
        revenue: company.revenue,
        status: company.status
      }));

      // If no real data, use mock data
      const finalTopCompanies = formattedTopCompanies.length > 0 ? formattedTopCompanies : [
        { name: 'TechCorp Solutions', users: 156, revenue: 25000, status: 'active' },
        { name: 'Global Industries', users: 142, revenue: 22000, status: 'active' },
        { name: 'InnovateTech', users: 128, revenue: 20000, status: 'active' },
        { name: 'Digital Dynamics', users: 115, revenue: 18000, status: 'active' },
        { name: 'Future Systems', users: 98, revenue: 15000, status: 'active' }
      ];

      res.json({
        overview: {
          totalCompanies,
          activeCompanies,
          totalUsers,
          totalRevenue,
          monthlyGrowth,
          userGrowth
        },
        revenueData,
        companyGrowth,
        userActivity,
        subscriptionDistribution,
        topCompanies: finalTopCompanies
      });

    } catch (error) {
      console.error('Error fetching analytics data:', error);
      res.status(500).json({ error: 'Failed to fetch analytics data' });
    }
  }

  /**
   * Get advanced user activity analytics
   */
  static async getUserActivityAnalytics(req, res) {
    try {
      const { timeRange = '30d', companyId } = req.query;
      
      // Calculate date range
      const now = new Date();
      let startDate;
      switch (timeRange) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      // Build query
      const query = { createdAt: { $gte: startDate } };
      if (companyId) {
        query.companyId = companyId;
      }

      // Get user activity data
      const userActivity = await User.aggregate([
        { $match: query },
        {
          $group: {
            _id: {
              $dateToString: { format: "%Y-%m-%d", date: "$createdAt" }
            },
            newUsers: { $sum: 1 },
            activeUsers: { $sum: { $cond: [{ $eq: ["$isActive", true] }, 1, 0] } },
            adminUsers: { $sum: { $cond: [{ $eq: ["$role", "admin"] }, 1, 0] } },
            employeeUsers: { $sum: { $cond: [{ $eq: ["$role", "employee"] }, 1, 0] } }
          }
        },
        { $sort: { _id: 1 } }
      ]);

      // Get role distribution
      const roleDistribution = await User.aggregate([
        { $match: query },
        {
          $group: {
            _id: "$role",
            count: { $sum: 1 }
          }
        }
      ]);

      // Get company-wise user distribution
      const companyUserDistribution = await User.aggregate([
        { $match: query },
        {
          $lookup: {
            from: 'companies',
            localField: 'companyId',
            foreignField: '_id',
            as: 'company'
          }
        },
        {
          $group: {
            _id: '$company.name',
            userCount: { $sum: 1 },
            adminCount: { $sum: { $cond: [{ $eq: ["$role", "admin"] }, 1, 0] } },
            employeeCount: { $sum: { $cond: [{ $eq: ["$role", "employee"] }, 1, 0] } }
          }
        },
        { $sort: { userCount: -1 } },
        { $limit: 10 }
      ]);

      // Generate mock login activity (in real app, this would come from login logs)
      const loginActivity = [];
      const days = Math.ceil((now - startDate) / (1000 * 60 * 60 * 24));
      for (let i = 0; i < days; i++) {
        const date = new Date(startDate.getTime() + i * 24 * 60 * 60 * 1000);
        loginActivity.push({
          date: date.toISOString().split('T')[0],
          logins: Math.floor(Math.random() * 200) + 100,
          uniqueUsers: Math.floor(Math.random() * 50) + 30
        });
      }

      res.json({
        userActivity,
        roleDistribution,
        companyUserDistribution,
        loginActivity,
        timeRange
      });

    } catch (error) {
      console.error('Error fetching user activity analytics:', error);
      res.status(500).json({ error: 'Failed to fetch user activity analytics' });
    }
  }

  /**
   * Get company performance metrics
   */
  static async getCompanyPerformanceMetrics(req, res) {
    try {
      const { timeRange = '30d' } = req.query;
      
      // Calculate date range
      const now = new Date();
      let startDate;
      switch (timeRange) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      // Get company performance data
      const companyPerformance = await Company.aggregate([
        {
          $lookup: {
            from: 'users',
            localField: '_id',
            foreignField: 'companyId',
            as: 'users'
          }
        },
        {
          $project: {
            name: 1,
            status: 1,
            createdAt: 1,
            subscriptionPlan: 1,
            userCount: { $size: '$users' },
            adminCount: {
              $size: {
                $filter: {
                  input: '$users',
                  cond: { $eq: ['$$this.role', 'admin'] }
                }
              }
            },
            employeeCount: {
              $size: {
                $filter: {
                  input: '$users',
                  cond: { $eq: ['$$this.role', 'employee'] }
                }
              }
            },
            activeUsers: {
              $size: {
                $filter: {
                  input: '$users',
                  cond: { $eq: ['$$this.isActive', true] }
                }
              }
            }
          }
        },
        {
          $match: {
            createdAt: { $gte: startDate }
          }
        },
        {
          $sort: { userCount: -1 }
        }
      ]);

      // Calculate performance metrics
      const performanceMetrics = {
        totalCompanies: companyPerformance.length,
        averageUsersPerCompany: companyPerformance.length > 0 
          ? Math.round(companyPerformance.reduce((sum, company) => sum + company.userCount, 0) / companyPerformance.length)
          : 0,
        topPerformingCompanies: companyPerformance.slice(0, 5),
        companyGrowthRate: 15.2, // Mock data
        averageEmployeeUtilization: 78.5, // Mock data
        subscriptionPlanDistribution: await Company.aggregate([
          {
            $lookup: {
              from: 'subscriptionplans',
              localField: 'subscriptionPlan',
              foreignField: '_id',
              as: 'plan'
            }
          },
          {
            $group: {
              _id: { $arrayElemAt: ['$plan.name', 0] },
              count: { $sum: 1 }
            }
          },
          {
            $match: {
              _id: { $ne: null }
            }
          }
        ])
      };

      res.json({
        companyPerformance,
        performanceMetrics,
        timeRange
      });

    } catch (error) {
      console.error('Error fetching company performance metrics:', error);
      res.status(500).json({ error: 'Failed to fetch company performance metrics' });
    }
  }

  /**
   * Generate custom report
   */
  static async generateCustomReport(req, res) {
    try {
      const { 
        reportType, 
        timeRange = '30d', 
        companyId, 
        format = 'json',
        includeInactive = false 
      } = req.body;

      // Calculate date range
      const now = new Date();
      let startDate;
      switch (timeRange) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      let reportData = {};

      switch (reportType) {
        case 'user_activity':
          reportData = await SuperAdminController.generateUserActivityReport(startDate, companyId, includeInactive);
          break;
        case 'company_performance':
          reportData = await SuperAdminController.generateCompanyPerformanceReport(startDate, includeInactive);
          break;
        case 'subscription_analysis':
          reportData = await SuperAdminController.generateSubscriptionAnalysisReport(startDate);
          break;
        case 'system_overview':
          reportData = await SuperAdminController.generateSystemOverviewReport(startDate);
          break;
        default:
          return res.status(400).json({ error: 'Invalid report type' });
      }

      // Add metadata
      reportData.metadata = {
        generatedAt: new Date().toISOString(),
        reportType,
        timeRange,
        companyId: companyId || 'all',
        format
      };

      if (format === 'csv') {
        // Convert to CSV format
        const csvData = SuperAdminController.convertToCSV(reportData);
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="${reportType}_${timeRange}_${new Date().toISOString().split('T')[0]}.csv"`);
        return res.send(csvData);
      }

      res.json(reportData);

    } catch (error) {
      console.error('Error generating custom report:', error);
      res.status(500).json({ error: 'Failed to generate custom report' });
    }
  }

  /**
   * Helper method to convert data to CSV
   */
  static convertToCSV(data) {
    // Simple CSV conversion - in production, use a proper CSV library
    if (data.rows && Array.isArray(data.rows)) {
      const headers = Object.keys(data.rows[0] || {});
      const csvRows = [headers.join(',')];
      
      data.rows.forEach(row => {
        const values = headers.map(header => {
          const value = row[header];
          return typeof value === 'string' && value.includes(',') ? `"${value}"` : value;
        });
        csvRows.push(values.join(','));
      });
      
      return csvRows.join('\n');
    }
    return JSON.stringify(data);
  }

  /**
   * Helper methods for report generation
   */
  static async generateUserActivityReport(startDate, companyId, includeInactive) {
    const query = { createdAt: { $gte: startDate } };
    if (companyId) query.companyId = companyId;
    if (!includeInactive) query.isActive = true;

    const users = await User.find(query).populate('companyId', 'name');
    
    return {
      title: 'User Activity Report',
      rows: users.map(user => ({
        name: `${user.firstName} ${user.lastName}`,
        email: user.email,
        role: user.role,
        company: user.companyId?.name || 'No Company',
        status: user.isActive ? 'Active' : 'Inactive',
        createdAt: user.createdAt.toISOString().split('T')[0]
      }))
    };
  }

  static async generateCompanyPerformanceReport(startDate, includeInactive) {
    const query = { createdAt: { $gte: startDate } };
    if (!includeInactive) query.status = 'active';

    const companies = await Company.find(query);
    
    return {
      title: 'Company Performance Report',
      rows: companies.map(company => ({
        name: company.name,
        domain: company.domain,
        status: company.status,
        createdAt: company.createdAt.toISOString().split('T')[0],
        subscriptionPlan: company.subscriptionPlan?.name || 'No Plan'
      }))
    };
  }

  static async generateSubscriptionAnalysisReport(startDate) {
    const companies = await Company.find({ createdAt: { $gte: startDate } })
      .populate('subscriptionPlan', 'name price');
    
    return {
      title: 'Subscription Analysis Report',
      rows: companies.map(company => ({
        company: company.name,
        plan: company.subscriptionPlan?.name || 'No Plan',
        price: company.subscriptionPlan?.price?.monthly || 0,
        status: company.status,
        createdAt: company.createdAt.toISOString().split('T')[0]
      }))
    };
  }

  static async generateSystemOverviewReport(startDate) {
    const [totalCompanies, totalUsers, activeCompanies, activeUsers] = await Promise.all([
      Company.countDocuments({ createdAt: { $gte: startDate } }),
      User.countDocuments({ createdAt: { $gte: startDate } }),
      Company.countDocuments({ createdAt: { $gte: startDate }, status: 'active' }),
      User.countDocuments({ createdAt: { $gte: startDate }, isActive: true })
    ]);
    
    return {
      title: 'System Overview Report',
      rows: [
        { metric: 'Total Companies', value: totalCompanies },
        { metric: 'Active Companies', value: activeCompanies },
        { metric: 'Total Users', value: totalUsers },
        { metric: 'Active Users', value: activeUsers },
        { metric: 'Report Period', value: `${startDate.toISOString().split('T')[0]} to ${new Date().toISOString().split('T')[0]}` }
      ]
    };
  }

  /**
   * Get system settings
   */
  static async getSettings(req, res) {
    try {
      // In a real application, you'd store settings in a database
      // For now, we'll return default settings
      const settings = {
        platform: {
          siteName: 'SNS Rooster',
          siteUrl: 'https://snstechservices.com.au',
          supportEmail: 'support@snstechservices.com.au',
          maxFileSize: 10,
          allowedFileTypes: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
          maintenanceMode: false,
          debugMode: false
        },
        security: {
          passwordMinLength: 8,
          requireSpecialChars: true,
          requireNumbers: true,
          requireUppercase: true,
          sessionTimeout: 30,
          maxLoginAttempts: 5,
          enableTwoFactor: false,
          ipWhitelist: []
        },
        notifications: {
          emailEnabled: true,
          smsEnabled: false,
          pushEnabled: true,
          emailProvider: 'smtp',
          smsProvider: 'twilio',
          defaultFromEmail: 'noreply@snstechservices.com.au',
          alertThreshold: 10
        },
        backup: {
          autoBackup: true,
          backupFrequency: 'daily',
          retentionDays: 30,
          backupLocation: 'local',
          lastBackup: new Date().toISOString(),
          nextBackup: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        },
        payment: {
          stripeEnabled: true,
          paypalEnabled: false,
          defaultCurrency: 'USD',
          taxRate: 10.0,
          invoicePrefix: 'SNS'
        }
      };

      res.json(settings);
    } catch (error) {
      console.error('Error fetching settings:', error);
      res.status(500).json({ error: 'Failed to fetch settings' });
    }
  }

  /**
   * Update system settings
   */
  static async updateSettings(req, res) {
    try {
      const newSettings = req.body;
      
      // Validate settings structure
      const requiredSections = ['platform', 'security', 'notifications', 'backup', 'payment'];
      for (const section of requiredSections) {
        if (!newSettings[section]) {
          return res.status(400).json({
            error: 'Invalid settings structure',
            message: `Missing ${section} section`
          });
        }
      }

      // In a real application, you'd save settings to a database
      // For now, we'll just log the changes
      console.log('Settings updated:', JSON.stringify(newSettings, null, 2));

      // Log the settings change for audit
      console.log(`Settings updated by super admin: ${req.user.email} at ${new Date().toISOString()}`);

      res.json({
        success: true,
        message: 'Settings updated successfully'
      });
    } catch (error) {
      console.error('Error updating settings:', error);
      res.status(500).json({ error: 'Failed to update settings' });
    }
  }

  // ===== USER MANAGEMENT =====

  /**
   * Create a new user
   */
  static async createUser(req, res) {
    try {
      const {
        firstName,
        lastName,
        email,
        companyId,
        role,
        department,
        position,
        password
      } = req.body;

      // Validate required fields
      if (!firstName || !lastName || !email || !role) {
        return res.status(400).json({ error: 'First name, last name, email, and role are required' });
      }

      // Check if email already exists
      const existingUser = await User.findOne({ email: email.toLowerCase() });
      if (existingUser) {
        return res.status(400).json({ error: 'Email already exists' });
      }

      // Validate company exists if provided
      if (companyId) {
        const company = await Company.findById(companyId);
        if (!company) {
          return res.status(400).json({ error: 'Company not found' });
        }
      }

      // Validate role
      const validRoles = ['employee', 'admin', 'super_admin'];
      if (!validRoles.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
      }

      // Generate password if not provided
      let userPassword = password;
      if (!userPassword) {
        userPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).toUpperCase().slice(-4) + '1!';
      }

      // Create user (password will be hashed by pre-save middleware)
      const userData = {
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.toLowerCase().trim(),
        password: userPassword, // Don't hash here - let the model handle it
        role,
        isActive: true,
        department: department?.trim(),
        position: position?.trim()
      };

      // Add companyId if provided and role is not super_admin
      if (companyId && role !== 'super_admin') {
        userData.companyId = companyId;
      }

      const newUser = new User(userData);
      await newUser.save();

      // Populate company info for response
      await newUser.populate('companyId', 'name domain');

      res.status(201).json({
        success: true,
        message: 'User created successfully',
        user: {
          ...newUser.toObject(),
          password: undefined // Don't send password in response
        },
        generatedPassword: !password ? userPassword : undefined // Only send if auto-generated
      });
    } catch (error) {
      console.error('Error creating user:', error);
      res.status(500).json({ error: 'Failed to create user' });
    }
  }

  /**
   * Get all users with pagination and filters
   */
  static async getAllUsers(req, res) {
    try {
      const { page = 1, limit = 10, role, companyId, search, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
      
      const filter = {};
      if (role) filter.role = role;
      if (companyId) filter.companyId = companyId;
      if (search) {
        filter.$or = [
          { firstName: { $regex: search, $options: 'i' } },
          { lastName: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } }
        ];
      }
      
      const sort = {};
      sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
      
      const users = await User.find(filter)
        .populate('companyId', 'name domain')
        .select('-password')
        .sort(sort)
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .exec();
      
      const total = await User.countDocuments(filter);
      
      res.json({
        users: users,
        totalPages: Math.ceil(total / limit),
        currentPage: parseInt(page),
        total: total
      });
    } catch (error) {
      console.error('Error fetching users:', error);
      res.status(500).json({ error: 'Failed to fetch users' });
    }
  }

  /**
   * Update user
   */
  static async updateUser(req, res) {
    try {
      const { userId } = req.params;
      const updateData = req.body;
      
      // Remove sensitive fields that shouldn't be updated directly
      delete updateData.password;
      delete updateData.email; // Email should be updated through a separate process
      
      const user = await User.findByIdAndUpdate(
        userId,
        updateData,
        { new: true, runValidators: true }
      ).select('-password');
      
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      res.json({
        success: true,
        message: 'User updated successfully',
        user: user
      });
    } catch (error) {
      console.error('Error updating user:', error);
      res.status(500).json({ error: 'Failed to update user' });
    }
  }

  /**
   * Delete user
   */
  static async deleteUser(req, res) {
    try {
      const { userId } = req.params;
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      // Prevent deletion of super admin users
      if (user.role === 'super_admin') {
        return res.status(403).json({ error: 'Cannot delete super admin users' });
      }
      
      await User.findByIdAndDelete(userId);
      
      res.json({
        success: true,
        message: 'User deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting user:', error);
      res.status(500).json({ error: 'Failed to delete user' });
    }
  }

  /**
   * Reset user password
   */
  static async resetUserPassword(req, res) {
    try {
      const { userId } = req.params;
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      // Generate a random password
      const newPassword = Math.random().toString(36).slice(-8) + Math.random().toString(36).toUpperCase().slice(-4) + '1!';
      
      // Hash the new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      // Update user password
      user.password = hashedPassword;
      user.resetPasswordAttempts = 0;
      user.resetPasswordLastAttempt = null;
      await user.save();
      
      // In a real application, you would send this password via email
      // For now, we'll return it in the response (not recommended for production)
      
      res.json({
        success: true,
        message: 'Password reset successfully',
        newPassword: newPassword // Remove this in production and send via email instead
      });
    } catch (error) {
      console.error('Error resetting user password:', error);
      res.status(500).json({ error: 'Failed to reset password' });
    }
  }

  /**
   * Change user password (with custom password)
   */
  static async changeUserPassword(req, res) {
    try {
      const { userId } = req.params;
      const { newPassword } = req.body;
      
      if (!newPassword) {
        return res.status(400).json({ error: 'New password is required' });
      }
      
      if (newPassword.length < 8) {
        return res.status(400).json({ error: 'Password must be at least 8 characters long' });
      }
      
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      
      // Hash the new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      // Update user password
      user.password = hashedPassword;
      user.resetPasswordAttempts = 0;
      user.resetPasswordLastAttempt = null;
      user.passwordChangedAt = new Date();
      await user.save();
      
      // Log password change for security
      console.log(`Password changed for user: ${user.email} (${user.role}) by super admin at ${new Date().toISOString()}`);
      
      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error) {
      console.error('Error changing user password:', error);
      res.status(500).json({ error: 'Failed to change password' });
    }
  }
}

module.exports = SuperAdminController; 