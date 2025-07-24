const Company = require('../models/Company');
const User = require('../models/User');
const Notification = require('../models/Notification');

class TrialService {
  /**
   * Check and update trial status for all companies
   */
  static async checkTrialStatus() {
    try {
      const trialCompanies = await Company.find({ 
        status: 'trial',
        trialExpired: false 
      });

      const now = new Date();
      const expiredCompanies = [];

      for (const company of trialCompanies) {
        if (company.trialEndDate && now > company.trialEndDate) {
          // Mark trial as expired
          company.trialExpired = true;
          company.trialExpiredDate = now;
          await company.save();

          expiredCompanies.push(company);
          
          // Create notification for company admin
          await this.createTrialExpiredNotification(company);
        }
      }

      return {
        checked: trialCompanies.length,
        expired: expiredCompanies.length,
        expiredCompanies: expiredCompanies.map(c => ({
          id: c._id,
          name: c.name,
          domain: c.domain,
          trialEndDate: c.trialEndDate
        }))
      };
    } catch (error) {
      console.error('Error checking trial status:', error);
      throw error;
    }
  }

  /**
   * Create notification for trial expiration
   */
  static async createTrialExpiredNotification(company) {
    try {
      // Find company admin
      const admin = await User.findOne({ 
        companyId: company._id, 
        role: 'admin' 
      });

      if (admin) {
        const notification = new Notification({
          userId: admin._id,
          companyId: company._id,
          type: 'trial_expired',
          title: 'Trial Period Expired',
          message: `Your company trial period has expired. Please contact your administrator to activate your account.`,
          priority: 'high',
          isRead: false,
          metadata: {
            companyId: company._id,
            companyName: company.name,
            trialEndDate: company.trialEndDate
          }
        });

        await notification.save();
        console.log(`Trial expired notification created for company: ${company.name}`);
      }
    } catch (error) {
      console.error('Error creating trial expired notification:', error);
    }
  }

  /**
   * Activate a company (convert from trial to active)
   */
  static async activateCompany(companyId, activatedBy) {
    try {
      const company = await Company.findById(companyId);
      
      if (!company) {
        throw new Error('Company not found');
      }

      if (company.status !== 'trial') {
        throw new Error('Company is not in trial status');
      }

      // Update company status
      company.status = 'active';
      company.trialExpired = false;
      company.trialExpiredDate = null;
      company.updatedAt = new Date();

      await company.save();

      // Create activation notification
      await this.createActivationNotification(company, activatedBy);

      console.log(`Company activated: ${company.name} (${company._id})`);
      
      return {
        success: true,
        company: {
          id: company._id,
          name: company.name,
          status: company.status,
          activatedAt: company.updatedAt
        }
      };
    } catch (error) {
      console.error('Error activating company:', error);
      throw error;
    }
  }

  /**
   * Create notification for company activation
   */
  static async createActivationNotification(company, activatedBy) {
    try {
      // Find company admin
      const admin = await User.findOne({ 
        companyId: company._id, 
        role: 'admin' 
      });

      if (admin) {
        const notification = new Notification({
          userId: admin._id,
          companyId: company._id,
          type: 'company_activated',
          title: 'Company Activated',
          message: `Your company account has been activated successfully. You now have full access to all features.`,
          priority: 'normal',
          isRead: false,
          metadata: {
            companyId: company._id,
            companyName: company.name,
            activatedBy: activatedBy,
            activatedAt: new Date()
          }
        });

        await notification.save();
        console.log(`Activation notification created for company: ${company.name}`);
      }
    } catch (error) {
      console.error('Error creating activation notification:', error);
    }
  }

  /**
   * Extend trial period for a company
   */
  static async extendTrial(companyId, additionalDays, extendedBy) {
    try {
      const company = await Company.findById(companyId);
      
      if (!company) {
        throw new Error('Company not found');
      }

      if (company.status !== 'trial') {
        throw new Error('Company is not in trial status');
      }

      // Calculate new trial end date
      const newTrialEndDate = new Date(company.trialEndDate);
      newTrialEndDate.setDate(newTrialEndDate.getDate() + additionalDays);

      // Update trial end date
      company.trialEndDate = newTrialEndDate;
      company.trialDurationDays += additionalDays;
      company.trialExpired = false;
      company.trialExpiredDate = null;
      company.updatedAt = new Date();

      await company.save();

      // Create extension notification
      await this.createTrialExtensionNotification(company, additionalDays, extendedBy);

      console.log(`Trial extended for company: ${company.name} (${company._id}) by ${additionalDays} days`);
      
      return {
        success: true,
        company: {
          id: company._id,
          name: company.name,
          newTrialEndDate: company.trialEndDate,
          totalTrialDays: company.trialDurationDays
        }
      };
    } catch (error) {
      console.error('Error extending trial:', error);
      throw error;
    }
  }

  /**
   * Create notification for trial extension
   */
  static async createTrialExtensionNotification(company, additionalDays, extendedBy) {
    try {
      // Find company admin
      const admin = await User.findOne({ 
        companyId: company._id, 
        role: 'admin' 
      });

      if (admin) {
        const notification = new Notification({
          userId: admin._id,
          companyId: company._id,
          type: 'trial_extended',
          title: 'Trial Period Extended',
          message: `Your trial period has been extended by ${additionalDays} days.`,
          priority: 'normal',
          isRead: false,
          metadata: {
            companyId: company._id,
            companyName: company.name,
            additionalDays: additionalDays,
            extendedBy: extendedBy,
            newTrialEndDate: company.trialEndDate
          }
        });

        await notification.save();
        console.log(`Trial extension notification created for company: ${company.name}`);
      }
    } catch (error) {
      console.error('Error creating trial extension notification:', error);
    }
  }

  /**
   * Get trial status for a company
   */
  static async getTrialStatus(companyId) {
    try {
      const company = await Company.findById(companyId);
      
      if (!company) {
        throw new Error('Company not found');
      }

      const now = new Date();
      const isExpired = company.trialEndDate && now > company.trialEndDate;
      const daysRemaining = company.trialEndDate ? 
        Math.ceil((company.trialEndDate - now) / (1000 * 60 * 60 * 24)) : 0;

      return {
        companyId: company._id,
        companyName: company.name,
        status: company.status,
        trialStartDate: company.trialStartDate,
        trialEndDate: company.trialEndDate,
        trialDurationDays: company.trialDurationDays,
        trialSubscriptionPlan: company.trialSubscriptionPlan,
        trialPlanName: company.trialPlanName,
        isExpired: isExpired,
        daysRemaining: Math.max(0, daysRemaining),
        trialExpired: company.trialExpired
      };
    } catch (error) {
      console.error('Error getting trial status:', error);
      throw error;
    }
  }
}

module.exports = TrialService; 