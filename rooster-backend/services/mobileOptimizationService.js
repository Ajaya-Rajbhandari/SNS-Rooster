const crypto = require('crypto');
const jwt = require('jsonwebtoken');

class MobileOptimizationService {
  constructor() {
    this.locationCache = new Map();
    this.biometricCache = new Map();
    this.notificationPreferences = new Map();
  }

  // Location-based attendance validation
  validateLocationAttendance(userLocation, officeLocation, maxDistance = 100) {
    try {
      const distance = this.calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        officeLocation.latitude,
        officeLocation.longitude
      );

      return {
        isValid: distance <= maxDistance,
        distance: Math.round(distance),
        maxDistance,
        location: {
          user: userLocation,
          office: officeLocation
        }
      };
    } catch (error) {
      console.error('Location validation error:', error);
      return {
        isValid: false,
        error: 'Invalid location data'
      };
    }
  }

  // Calculate distance between two points using Haversine formula
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    const distance = R * c; // Distance in kilometers
    return distance * 1000; // Convert to meters
  }

  deg2rad(deg) {
    return deg * (Math.PI/180);
  }

  // Biometric authentication helper
  generateBiometricToken(userId, deviceId) {
    const payload = {
      userId,
      deviceId,
      type: 'biometric',
      timestamp: Date.now()
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5m' });
    
    // Cache the biometric token
    this.biometricCache.set(`${userId}-${deviceId}`, {
      token,
      createdAt: Date.now(),
      expiresAt: Date.now() + (5 * 60 * 1000) // 5 minutes
    });

    return token;
  }

  // Verify biometric token
  verifyBiometricToken(token, userId, deviceId) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      if (decoded.type !== 'biometric' || 
          decoded.userId !== userId || 
          decoded.deviceId !== deviceId) {
        return { isValid: false, error: 'Invalid biometric token' };
      }

      // Check cache
      const cached = this.biometricCache.get(`${userId}-${deviceId}`);
      if (!cached || cached.token !== token) {
        return { isValid: false, error: 'Token not found in cache' };
      }

      // Check expiration
      if (Date.now() > cached.expiresAt) {
        this.biometricCache.delete(`${userId}-${deviceId}`);
        return { isValid: false, error: 'Token expired' };
      }

      return { isValid: true, decoded };
    } catch (error) {
      return { isValid: false, error: 'Token verification failed' };
    }
  }

  // Push notification optimization
  optimizeNotificationDelivery(userId, notificationType, userPreferences = {}) {
    const preferences = this.getNotificationPreferences(userId);
    const optimized = { ...preferences, ...userPreferences };

    // Check if user has opted out of this notification type
    if (optimized.disabledTypes && optimized.disabledTypes.includes(notificationType)) {
      return {
        shouldSend: false,
        reason: 'User has disabled this notification type'
      };
    }

    // Check quiet hours
    const now = new Date();
    const currentHour = now.getHours();
    
    if (optimized.quietHours && 
        currentHour >= optimized.quietHours.start && 
        currentHour <= optimized.quietHours.end) {
      return {
        shouldSend: false,
        reason: 'Quiet hours active',
        scheduledFor: this.getNextAvailableTime(optimized.quietHours)
      };
    }

    // Check frequency limits
    const lastNotification = this.getLastNotificationTime(userId, notificationType);
    const minInterval = optimized.frequencyLimits?.[notificationType] || 300000; // 5 minutes default
    
    if (lastNotification && (Date.now() - lastNotification) < minInterval) {
      return {
        shouldSend: false,
        reason: 'Frequency limit exceeded',
        nextAvailable: new Date(lastNotification + minInterval)
      };
    }

    return {
      shouldSend: true,
      priority: this.calculateNotificationPriority(notificationType, optimized),
      deliveryMethod: this.getOptimalDeliveryMethod(optimized)
    };
  }

  // Get notification preferences for user
  getNotificationPreferences(userId) {
    return this.notificationPreferences.get(userId) || {
      disabledTypes: [],
      quietHours: { start: 22, end: 8 },
      frequencyLimits: {
        attendance: 300000, // 5 minutes
        leave: 600000, // 10 minutes
        general: 300000 // 5 minutes
      },
      deliveryMethod: 'push',
      priority: 'normal'
    };
  }

  // Set notification preferences for user
  setNotificationPreferences(userId, preferences) {
    this.notificationPreferences.set(userId, {
      ...this.getNotificationPreferences(userId),
      ...preferences
    });
  }

  // Calculate notification priority
  calculateNotificationPriority(notificationType, preferences) {
    const priorityMap = {
      'attendance': 'high',
      'leave_approval': 'high',
      'leave_rejection': 'high',
      'payroll': 'medium',
      'general': 'normal',
      'marketing': 'low'
    };

    return preferences.priorityOverrides?.[notificationType] || 
           priorityMap[notificationType] || 
           'normal';
  }

  // Get optimal delivery method
  getOptimalDeliveryMethod(preferences) {
    const methods = preferences.deliveryMethods || ['push', 'email'];
    return methods[0]; // Return primary method
  }

  // Get next available time after quiet hours
  getNextAvailableTime(quietHours) {
    const now = new Date();
    const nextTime = new Date(now);
    
    if (now.getHours() >= quietHours.start || now.getHours() <= quietHours.end) {
      nextTime.setHours(quietHours.end + 1, 0, 0, 0);
      if (nextTime <= now) {
        nextTime.setDate(nextTime.getDate() + 1);
      }
    }
    
    return nextTime;
  }

  // Get last notification time for frequency limiting
  getLastNotificationTime(userId, notificationType) {
    const key = `${userId}-${notificationType}`;
    return this.notificationCache?.get(key) || null;
  }

  // Update last notification time
  updateLastNotificationTime(userId, notificationType) {
    if (!this.notificationCache) {
      this.notificationCache = new Map();
    }
    
    const key = `${userId}-${notificationType}`;
    this.notificationCache.set(key, Date.now());
  }

  // Offline functionality support
  generateOfflineToken(userId, deviceId) {
    const payload = {
      userId,
      deviceId,
      type: 'offline',
      timestamp: Date.now(),
      permissions: ['attendance', 'profile', 'leave_view']
    };

    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '24h' });
  }

  // Validate offline token
  validateOfflineToken(token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      if (decoded.type !== 'offline') {
        return { isValid: false, error: 'Invalid offline token' };
      }

      // Check if token is not too old (24 hours)
      const tokenAge = Date.now() - decoded.timestamp;
      if (tokenAge > 24 * 60 * 60 * 1000) {
        return { isValid: false, error: 'Offline token expired' };
      }

      return { isValid: true, decoded };
    } catch (error) {
      return { isValid: false, error: 'Token verification failed' };
    }
  }

  // Touch interaction optimization
  optimizeTouchTargets(elementSize) {
    const minTouchTarget = 44; // iOS minimum touch target size
    const recommendedTouchTarget = 48; // Android recommended size
    
    return {
      isOptimized: elementSize >= minTouchTarget,
      recommendedSize: Math.max(elementSize, recommendedTouchTarget),
      accessibility: elementSize >= recommendedTouchTarget ? 'good' : 'needs-improvement'
    };
  }

  // Mobile-specific UI optimization
  getMobileUIOptimizations(screenSize, platform) {
    const optimizations = {
      touchTargets: {
        minSize: 44,
        recommendedSize: 48,
        spacing: 8
      },
      typography: {
        minFontSize: 16,
        lineHeight: 1.4,
        contrast: 'high'
      },
      navigation: {
        bottomNav: screenSize.height < 700,
        gestureSupport: true,
        backButton: platform === 'ios'
      },
      performance: {
        lazyLoading: true,
        imageOptimization: true,
        caching: true
      }
    };

    return optimizations;
  }

  // Clean up expired data
  cleanup() {
    const now = Date.now();
    
    // Clean up expired biometric tokens
    for (const [key, value] of this.biometricCache.entries()) {
      if (now > value.expiresAt) {
        this.biometricCache.delete(key);
      }
    }

    // Clean up old notification cache (older than 24 hours)
    if (this.notificationCache) {
      for (const [key, timestamp] of this.notificationCache.entries()) {
        if (now - timestamp > 24 * 60 * 60 * 1000) {
          this.notificationCache.delete(key);
        }
      }
    }
  }
}

module.exports = MobileOptimizationService; 