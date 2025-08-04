const Notification = require('../models/Notification');
const { Logger } = require('../config/logger');

// Create a new notification
exports.createNotification = async (req, res) => {
  try {
    const { userId, title, body, data = {} } = req.body;
    
    const notification = new Notification({
      userId,
      title,
      body,
      data,
    });

    await notification.save();
    
    Logger.info(`Notification created for user ${userId}: ${title}`);
    
    res.status(201).json({
      success: true,
      message: 'Notification created successfully',
      data: notification,
    });
  } catch (error) {
    Logger.error('Error creating notification:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating notification',
      error: error.message,
    });
  }
};

// Get notifications for the current user
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20 } = req.query;
    
    const skip = (page - 1) * limit;
    
    // Build filter - exclude attendance notifications and only show notifications for current user
    const filter = { 
      userId,
      // Exclude attendance-related notifications
      $or: [
        { 'data.type': { $ne: 'attendance' } },
        { 'data.type': { $exists: false } }
      ]
    };
    
    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Notification.countDocuments(filter);
    const unreadCount = await Notification.countDocuments({ 
      userId, 
      readStatus: false,
      $or: [
        { 'data.type': { $ne: 'attendance' } },
        { 'data.type': { $exists: false } }
      ]
    });
    
    res.json({
      success: true,
      data: {
        notifications,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit),
        },
        unreadCount,
      },
    });
  } catch (error) {
    Logger.error('Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching notifications',
      error: error.message,
    });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId },
      { readStatus: true },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }
    
    res.json({
      success: true,
      message: 'Notification marked as read',
      data: notification,
    });
  } catch (error) {
    Logger.error('Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Error marking notification as read',
      error: error.message,
    });
  }
};

// Mark all notifications as read
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    await Notification.updateMany(
      { 
        userId, 
        readStatus: false,
        $or: [
          { 'data.type': { $ne: 'attendance' } },
          { 'data.type': { $exists: false } }
        ]
      },
      { readStatus: true }
    );
    
    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    Logger.error('Error marking all notifications as read:', error);
    res.status(500).json({
      success: false,
      message: 'Error marking all notifications as read',
      error: error.message,
    });
  }
};

// Delete a notification
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    const notification = await Notification.findOneAndDelete({ _id: id, userId });
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }
    
    res.json({
      success: true,
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    Logger.error('Error deleting notification:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting notification',
      error: error.message,
    });
  }
};

// Delete all notifications for user
exports.deleteAllNotifications = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Delete all notifications except attendance-related ones
    await Notification.deleteMany({ 
      userId,
      $or: [
        { 'data.type': { $ne: 'attendance' } },
        { 'data.type': { $exists: false } }
      ]
    });
    
    res.json({
      success: true,
      message: 'All notifications deleted successfully',
    });
  } catch (error) {
    Logger.error('Error deleting all notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting all notifications',
      error: error.message,
    });
  }
}; 