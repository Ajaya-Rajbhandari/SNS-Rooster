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
    const userRole = req.user.role;
    // Find notifications for this user, their role, or broadcast
    const notifications = await Notification.find({
      $or: [
        { user: userId },
        { role: userRole },
        { role: 'all' },
      ],
      $or: [
        { expiresAt: null },
        { expiresAt: { $gt: new Date() } },
      ],
    })
      .sort({ createdAt: -1 })
      .limit(100);
    res.status(200).json({ notifications });
  } catch (error) {
    console.error('Get notifications error:', error);
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