const Notification = require('../models/Notification');
const User = require('../models/User');
const Company = require('../models/Company');

// Use Logger if available, otherwise use console
let Logger;
try {
  const loggerModule = require('../config/logger');
  Logger = loggerModule.Logger;
} catch (error) {
  Logger = {
    info: (message) => console.log(`[INFO] ${message}`),
    error: (message) => console.error(`[ERROR] ${message}`),
  };
}

class CompanyNotificationService {
  /**
   * Send notification to all users in a company
   * @param {ObjectId} companyId - Company ID
   * @param {String} title - Notification title
   * @param {String} message - Notification message
   * @param {String} type - Notification type
   * @param {String} role - Target role ('all', 'admin', 'employee')
   * @param {String} link - Optional link
   */
  static async sendCompanyNotification(companyId, title, message, type, role = 'all', link = '') {
    try {
      Logger.info(`Sending company notification: ${title} to company ${companyId}`);
      
      const notification = new Notification({
        company: companyId,
        title,
        message,
        type,
        role,
        link,
      });

      await notification.save();
      Logger.info(`Company notification sent successfully: ${notification._id}`);
      return notification;
    } catch (error) {
      Logger.error(`Error sending company notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send notification to specific role in a company
   * @param {ObjectId} companyId - Company ID
   * @param {String} title - Notification title
   * @param {String} message - Notification message
   * @param {String} type - Notification type
   * @param {String} role - Target role ('admin', 'employee')
   * @param {String} link - Optional link
   */
  static async sendRoleNotification(companyId, title, message, type, role, link = '') {
    try {
      Logger.info(`Sending role notification: ${title} to ${role}s in company ${companyId}`);
      
      const notification = new Notification({
        company: companyId,
        title,
        message,
        type,
        role,
        link,
      });

      await notification.save();
      Logger.info(`Role notification sent successfully: ${notification._id}`);
      return notification;
    } catch (error) {
      Logger.error(`Error sending role notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Send location assignment notification to admins
   * @param {ObjectId} companyId - Company ID
   * @param {String} employeeName - Employee name
   * @param {String} locationName - Location name
   * @param {String} assignedBy - Admin who made the assignment
   */
  static async sendLocationAssignmentNotification(companyId, employeeName, locationName, assignedBy) {
    const title = 'Employee Location Assignment';
    const message = `${employeeName} has been assigned to ${locationName} by ${assignedBy}`;
    const link = '/admin/location-management';
    
    return await this.sendRoleNotification(
      companyId,
      title,
      message,
      'location_assignment',
      'admin',
      link
    );
  }

  /**
   * Send location settings change notification
   * @param {ObjectId} companyId - Company ID
   * @param {String} settingType - Type of setting changed
   * @param {String} changedBy - Admin who made the change
   * @param {String} details - Additional details about the change
   */
  static async sendLocationSettingsNotification(companyId, settingType, changedBy, details = '') {
    const title = 'Location Settings Updated';
    const message = `${settingType} settings have been updated by ${changedBy}. ${details}`;
    const link = '/admin/location-management';
    
    return await this.sendRoleNotification(
      companyId,
      title,
      message,
      'location_settings',
      'admin',
      link
    );
  }

  /**
   * Send company settings change notification
   * @param {ObjectId} companyId - Company ID
   * @param {String} settingType - Type of setting changed
   * @param {String} changedBy - Admin who made the change
   * @param {String} details - Additional details about the change
   */
  static async sendCompanySettingsNotification(companyId, settingType, changedBy, details = '') {
    const title = 'Company Settings Updated';
    const message = `${settingType} settings have been updated by ${changedBy}. ${details}`;
    const link = '/admin/settings';
    
    return await this.sendCompanyNotification(
      companyId,
      title,
      message,
      'company_settings',
      'all',
      link
    );
  }

  /**
   * Get notifications for a specific company and user
   * @param {ObjectId} companyId - Company ID
   * @param {ObjectId} userId - User ID
   * @param {String} userRole - User role
   * @param {Object} options - Query options
   */
  static async getCompanyNotifications(companyId, userId, userRole, options = {}) {
    try {
      const { limit = 50, skip = 0, unreadOnly = false } = options;
      
      const query = {
        company: companyId,
        $or: [
          { user: userId }, // Personal notifications
          { user: null, role: 'all' }, // Company-wide notifications
          { user: null, role: userRole }, // Role-based notifications
        ],
      };

      if (unreadOnly) {
        query.isRead = false;
      }

      const notifications = await Notification.find(query)
        .sort({ createdAt: -1 })
        .limit(limit)
        .skip(skip)
        .populate('user', 'name email')
        .lean();

      return notifications;
    } catch (error) {
      Logger.error(`Error fetching company notifications: ${error.message}`);
      throw error;
    }
  }

  /**
   * Mark notification as read
   * @param {ObjectId} notificationId - Notification ID
   * @param {ObjectId} userId - User ID
   */
  static async markAsRead(notificationId, userId) {
    try {
      const notification = await Notification.findById(notificationId);
      if (!notification) {
        throw new Error('Notification not found');
      }

      // Check if user has access to this notification
      if (notification.user && notification.user.toString() !== userId.toString()) {
        throw new Error('Access denied');
      }

      notification.isRead = true;
      await notification.save();
      
      Logger.info(`Notification marked as read: ${notificationId} by user ${userId}`);
      return notification;
    } catch (error) {
      Logger.error(`Error marking notification as read: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get unread notification count for a user
   * @param {ObjectId} companyId - Company ID
   * @param {ObjectId} userId - User ID
   * @param {String} userRole - User role
   */
  static async getUnreadCount(companyId, userId, userRole) {
    try {
      const query = {
        company: companyId,
        isRead: false,
        $or: [
          { user: userId },
          { user: null, role: 'all' },
          { user: null, role: userRole },
        ],
      };

      const count = await Notification.countDocuments(query);
      return count;
    } catch (error) {
      Logger.error(`Error getting unread count: ${error.message}`);
      throw error;
    }
  }
}

module.exports = CompanyNotificationService; 