const Notification = require('../models/Notification');
const User = require('../models/User');

// Create a notification (admin/system)
exports.createNotification = async (req, res) => {
  try {
    const { user, role, title, message, type, link, expiresAt } = req.body;
    const notification = new Notification({
      user: user || null,
      role: role || 'all',
      title,
      message,
      type: type || 'info',
      link: link || '',
      expiresAt: expiresAt || null,
    });
    await notification.save();
    res.status(201).json({ message: 'Notification created', notification });
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// List notifications for current user (user-specific, role, or broadcast)
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.userId;
    const role = req.user.role;
    // Fetch notifications:
    // 1. Directly addressed to this user (user field matches)
    // 2. Broadcast to this user's role with no specific user target (user is null)
    // 3. Broadcast to everyone (role === 'all' && user is null)
    const notifications = await Notification.find({
      $or: [
        { user: userId },
        { $and: [{ role: role }, { user: null }] },
        { $and: [{ role: 'all' }, { user: null }] },
      ],
    }).sort({ createdAt: -1 });
    res.json({ notifications });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const notificationId = req.params.id;
    const userId = req.user.userId;
    // Only allow marking as read if the notification is for this user, their role, or broadcast
    const notification = await Notification.findOne({
      _id: notificationId,
      $or: [
        { user: userId },
        { role: req.user.role },
        { role: 'all' },
      ],
    });
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    notification.isRead = true;
    await notification.save();
    res.status(200).json({ message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Mark all notifications as read
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.userId;
    const userRole = req.user.role;
    await Notification.updateMany(
      {
        $or: [
          { user: userId },
          { $and: [{ role: userRole }, { user: null }] },
          { $and: [{ role: 'all' }, { user: null }] },
        ],
        isRead: false,
      },
      { $set: { isRead: true } }
    );
    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete all notifications for the current user/role
exports.clearAllNotifications = async (req, res) => {
  try {
    console.log('clearAllNotifications called by user:', req.user);
    await Notification.deleteMany({
      $or: [
        { user: req.user.userId },
        { $and: [{ role: req.user.role }, { user: null }] },
        { $and: [{ role: 'all' }, { user: null }] },
      ],
    });
    res.status(200).json({ message: 'All notifications cleared' });
  } catch (error) {
    console.error('Clear all notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Admin-only: delete all admin notifications
exports.clearAllAdminNotifications = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can clear all admin notifications' });
    }
    const result = await Notification.deleteMany({ role: 'admin' });
    res.status(200).json({ message: 'All admin notifications cleared', deletedCount: result.deletedCount });
  } catch (error) {
    console.error('Clear all admin notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete a single notification by ID
exports.deleteNotification = async (req, res) => {
  try {
    const notificationId = req.params.id;
    const userId = req.user.userId;
    // Only allow deleting if the notification belongs to the user or their role
    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      $or: [
        { user: userId },
        { role: req.user.role },
        { role: 'all' }
      ]
    });
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    res.status(200).json({ message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
}; 