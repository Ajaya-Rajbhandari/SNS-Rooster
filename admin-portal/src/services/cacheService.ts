// Cache Service for Admin Portal
// Provides intelligent caching to reduce API calls and improve performance

interface CacheItem<T> {
  data: T;
  timestamp: number;
  ttl: number; // Time to live in milliseconds
  key: string;
}

interface CacheConfig {
  defaultTTL: number; // Default time to live in milliseconds
  maxSize: number; // Maximum number of items in cache
  cleanupInterval: number; // How often to clean expired items
}

class CacheService {
  private cache = new Map<string, CacheItem<any>>();
  private config: CacheConfig;
  private cleanupTimer: NodeJS.Timeout | null = null;

  constructor(config: Partial<CacheConfig> = {}) {
    this.config = {
      defaultTTL: 5 * 60 * 1000, // 5 minutes default
      maxSize: 100, // Maximum 100 items
      cleanupInterval: 60 * 1000, // Cleanup every minute
      ...config
    };

    this.startCleanupTimer();
  }

  /**
   * Set an item in cache
   */
  set<T>(key: string, data: T, ttl?: number): void {
    const item: CacheItem<T> = {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.config.defaultTTL,
      key
    };

    // Remove oldest items if cache is full
    if (this.cache.size >= this.config.maxSize) {
      this.evictOldest();
    }

    this.cache.set(key, item);
  }

  /**
   * Get an item from cache
   */
  get<T>(key: string): T | null {
    const item = this.cache.get(key);
    
    if (!item) {
      return null;
    }

    // Check if item has expired
    if (Date.now() - item.timestamp > item.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.data;
  }

  /**
   * Check if a key exists and is not expired
   */
  has(key: string): boolean {
    return this.get(key) !== null;
  }

  /**
   * Remove an item from cache
   */
  delete(key: string): boolean {
    return this.cache.delete(key);
  }

  /**
   * Clear all cache
   */
  clear(): void {
    this.cache.clear();
  }

  /**
   * Get cache statistics
   */
  getStats() {
    const now = Date.now();
    let expiredCount = 0;
    let validCount = 0;

    this.cache.forEach(item => {
      if (now - item.timestamp > item.ttl) {
        expiredCount++;
      } else {
        validCount++;
      }
    });

    return {
      total: this.cache.size,
      valid: validCount,
      expired: expiredCount,
      maxSize: this.config.maxSize
    };
  }

  /**
   * Evict oldest items when cache is full
   */
  private evictOldest(): void {
    let oldestKey: string | null = null;
    let oldestTime = Date.now();

    this.cache.forEach((item, key) => {
      if (item.timestamp < oldestTime) {
        oldestTime = item.timestamp;
        oldestKey = key;
      }
    });

    if (oldestKey) {
      this.cache.delete(oldestKey);
    }
  }

  /**
   * Clean up expired items
   */
  private cleanup(): void {
    const now = Date.now();
    const expiredKeys: string[] = [];

    this.cache.forEach((item, key) => {
      if (now - item.timestamp > item.ttl) {
        expiredKeys.push(key);
      }
    });

    expiredKeys.forEach(key => this.cache.delete(key));

    if (expiredKeys.length > 0) {
      console.log(`CacheService: Cleaned up ${expiredKeys.length} expired items`);
    }
  }

  /**
   * Start cleanup timer
   */
  private startCleanupTimer(): void {
    this.cleanupTimer = setInterval(() => {
      this.cleanup();
    }, this.config.cleanupInterval);
  }

  /**
   * Stop cleanup timer
   */
  destroy(): void {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }
    this.clear();
  }
}

// Cache configurations for different data types
export const CACHE_CONFIGS = {
  // Short-lived cache for frequently changing data
  SHORT: {
    defaultTTL: 30 * 1000, // 30 seconds
    maxSize: 50
  },
  
  // Medium cache for moderately changing data
  MEDIUM: {
    defaultTTL: 5 * 60 * 1000, // 5 minutes
    maxSize: 100
  },
  
  // Long cache for rarely changing data
  LONG: {
    defaultTTL: 30 * 60 * 1000, // 30 minutes
    maxSize: 50
  },
  
  // Very long cache for static data
  STATIC: {
    defaultTTL: 24 * 60 * 60 * 1000, // 24 hours
    maxSize: 20
  }
};

// Create cache instances
export const shortCache = new CacheService(CACHE_CONFIGS.SHORT);
export const mediumCache = new CacheService(CACHE_CONFIGS.MEDIUM);
export const longCache = new CacheService(CACHE_CONFIGS.LONG);
export const staticCache = new CacheService(CACHE_CONFIGS.STATIC);

// Cache key generators
export const CACHE_KEYS = {
  // Auth related
  USER_PROFILE: (userId: string) => `user:profile:${userId}`,
  AUTH_TOKEN: 'auth:token',
  
  // Company related
  COMPANIES_LIST: 'companies:list',
  COMPANY_DETAILS: (companyId: string) => `company:details:${companyId}`,
  COMPANY_FEATURES: (companyId: string) => `company:features:${companyId}`,
  
  // Subscription plans
  SUBSCRIPTION_PLANS: 'subscription:plans',
  PLAN_DETAILS: (planId: string) => `plan:details:${planId}`,
  
  // Analytics and stats
  DASHBOARD_STATS: 'dashboard:stats',
  ANALYTICS_DATA: (timeRange: string) => `analytics:${timeRange}`,
  
  // User management
  USERS_LIST: 'users:list',
  USER_DETAILS: (userId: string) => `user:details:${userId}`,
  
  // Settings
  SYSTEM_SETTINGS: 'system:settings',
  ADMIN_SETTINGS: (companyId: string) => `admin:settings:${companyId}`,
  
  // Notifications
  NOTIFICATIONS_LIST: 'notifications:list',
  
  // Monitoring
  HEALTH_STATUS: 'monitoring:health',
  ERROR_STATS: 'monitoring:errors',
  PERFORMANCE_STATS: 'monitoring:performance'
};

export default CacheService; 