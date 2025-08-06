const Notification = require('../models/Notification');
const { sendNotificationToUser } = require('./notificationService');
const FCMToken = require('../models/FCMToken');

class NotificationQueueService {
  constructor() {
    this.MAX_RETRIES = 3;
    this.RETRY_INTERVALS = [5000, 15000, 30000]; // Retry after 5s, 15s, 30s
    this.isProcessing = false;
  }

  async processQueue() {
    if (this.isProcessing) return;
    
    try {
      this.isProcessing = true;
      
      // Find failed or pending notifications that haven't exceeded max retries
      const notifications = await Notification.find({
        $or: [
          { status: 'pending' },
          { status: 'failed', attempts: { $lt: this.MAX_RETRIES } }
        ]
      }).sort({ createdAt: 1 }).limit(10);

      for (const notification of notifications) {
        await this.processNotification(notification);
      }
    } catch (error) {
      console.error('Error processing notification queue:', error);
    } finally {
      this.isProcessing = false;
    }
  }

  async processNotification(notification) {
    try {
      // Get user's FCM token
      const tokenDoc = await FCMToken.findOne({ userId: notification.userId });
      if (!tokenDoc || !tokenDoc.fcmToken) {
        await this.markNotificationFailed(notification, 'FCM token not found');
        return;
      }

      // Attempt to send notification
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        notification.title,
        notification.body,
        notification.data,
        notification.userId
      );

      // Mark as sent if successful
      notification.status = 'sent';
      notification.lastAttempt = new Date();
      await notification.save();

    } catch (error) {
      await this.handleNotificationError(notification, error);
    }
  }

  async handleNotificationError(notification, error) {
    notification.attempts += 1;
    notification.lastAttempt = new Date();
    notification.error = error.message;

    if (notification.attempts >= this.MAX_RETRIES) {
      notification.status = 'failed';
    } else {
      notification.status = 'retrying';
      // Schedule retry after interval
      const retryInterval = this.RETRY_INTERVALS[notification.attempts - 1] || this.RETRY_INTERVALS[this.RETRY_INTERVALS.length - 1];
      setTimeout(() => this.processQueue(), retryInterval);
    }

    await notification.save();

    console.error('Notification processing failed:', {
      notificationId: notification._id,
      userId: notification.userId,
      attempts: notification.attempts,
      error: error.message,
      status: notification.status
    });
  }

  async markNotificationFailed(notification, reason) {
    notification.status = 'failed';
    notification.error = reason;
    notification.lastAttempt = new Date();
    await notification.save();
  }
}

// Create singleton instance
const notificationQueue = new NotificationQueueService();

// Start processing queue periodically
setInterval(() => notificationQueue.processQueue(), 10000); // Process queue every 10 seconds

module.exports = notificationQueue;