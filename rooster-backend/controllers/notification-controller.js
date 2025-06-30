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
    // Fetch notifications for the user or their role, sorted by newest first
    const notifications = await Notification.find({
      $or: [
        { user: userId },
        { role: role },
        { role: 'all' }
      ]
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
          { role: userRole },
          { role: 'all' }
        ],
        isRead: false
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
    const userId = req.user.userId;
    const userRole = req.user.role;
    await Notification.deleteMany({
      $or: [
        { user: userId },
        { role: userRole },
        { role: 'all' }
      ]
    });
    res.status(200).json({ message: 'All notifications cleared' });
  } catch (error) {
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