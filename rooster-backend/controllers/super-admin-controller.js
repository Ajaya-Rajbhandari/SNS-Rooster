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
      const { page = 1, limit = 10, status, search, sortBy = 'createdAt', sortOrder = 'desc' } = req.query;
      
      const filter = {};
      if (status) filter.status = status;
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
}

module.exports = SuperAdminController; 