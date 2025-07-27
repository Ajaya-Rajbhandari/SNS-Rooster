import apiService from './apiService';
import { 
  shortCache, 
  mediumCache, 
  longCache, 
  staticCache, 
  CACHE_KEYS 
} from './cacheService';

// Cache strategies for different endpoints
const CACHE_STRATEGIES = {
  // Auth - short cache for security
  '/api/auth/validate': { cache: shortCache, ttl: 30 * 1000 },
  '/api/auth/login': { cache: null }, // No cache for login
  
  // Companies - medium cache
  '/api/super-admin/companies': { cache: mediumCache, ttl: 2 * 60 * 1000 },
  '/api/companies': { cache: mediumCache, ttl: 2 * 60 * 1000 },
  
  // Subscription plans - long cache (rarely change)
  '/api/super-admin/subscription-plans': { cache: longCache, ttl: 15 * 60 * 1000 },
  
  // Dashboard stats - short cache (frequently updated)
  '/api/super-admin/dashboard/stats': { cache: shortCache, ttl: 60 * 1000 },
  
  // Analytics - medium cache
  '/api/super-admin/analytics': { cache: mediumCache, ttl: 5 * 60 * 1000 },
  
  // Users - medium cache
  '/api/super-admin/users': { cache: mediumCache, ttl: 2 * 60 * 1000 },
  
  // Settings - long cache
  '/api/super-admin/settings': { cache: longCache, ttl: 10 * 60 * 1000 },
  '/api/admin/settings': { cache: longCache, ttl: 10 * 60 * 1000 },
  
  // Notifications - short cache
  '/api/super-admin/notifications': { cache: shortCache, ttl: 30 * 1000 },
  
  // Monitoring - short cache
  '/api/monitoring/health': { cache: shortCache, ttl: 30 * 1000 },
  '/api/monitoring/errors': { cache: shortCache, ttl: 30 * 1000 },
  '/api/monitoring/performance': { cache: shortCache, ttl: 30 * 1000 }
};

// Helper to get cache strategy for URL
function getCacheStrategy(url: string) {
  // Find matching strategy
  for (const [pattern, strategy] of Object.entries(CACHE_STRATEGIES)) {
    if (url.includes(pattern)) {
      return strategy;
    }
  }
  
  // Default to no cache
  return { cache: null, ttl: 0 };
}

// Helper to generate cache key
function generateCacheKey(method: string, url: string, data?: any): string {
  const baseKey = `${method}:${url}`;
  
  // Include data in key for POST/PUT/PATCH requests
  if (data && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
    const dataHash = JSON.stringify(data).slice(0, 100); // Limit hash length
    return `${baseKey}:${dataHash}`;
  }
  
  return baseKey;
}

// Cached API service
export const cachedApiService = {
  // GET with caching
  async get<T>(url: string, config?: any): Promise<T> {
    const strategy = getCacheStrategy(url);
    const cacheKey = generateCacheKey('GET', url);
    
    // Check cache first
    if (strategy.cache) {
      const cached = strategy.cache.get<T>(cacheKey);
      if (cached !== null) {
        console.log(`Cache HIT: ${url}`);
        return cached;
      }
    }
    
    // Fetch from API
    console.log(`Cache MISS: ${url}`);
    const data = await apiService.get<T>(url, config);
    
    // Store in cache
    if (strategy.cache) {
      strategy.cache.set(cacheKey, data, strategy.ttl);
    }
    
    return data;
  },

  // POST without caching (mutations)
  async post<T>(url: string, data?: any, config?: any): Promise<T> {
    const result = await apiService.post<T>(url, data, config);
    
    // Invalidate related caches after mutations
    this.invalidateRelatedCaches(url, data);
    
    return result;
  },

  // PUT without caching (mutations)
  async put<T>(url: string, data?: any, config?: any): Promise<T> {
    const result = await apiService.put<T>(url, data, config);
    
    // Invalidate related caches after mutations
    this.invalidateRelatedCaches(url, data);
    
    return result;
  },

  // PATCH without caching (mutations)
  async patch<T>(url: string, data?: any, config?: any): Promise<T> {
    const result = await apiService.patch<T>(url, data, config);
    
    // Invalidate related caches after mutations
    this.invalidateRelatedCaches(url, data);
    
    return result;
  },

  // DELETE without caching (mutations)
  async delete<T>(url: string, config?: any): Promise<T> {
    const result = await apiService.delete<T>(url, config);
    
    // Invalidate related caches after mutations
    this.invalidateRelatedCaches(url);
    
    return result;
  },

  // Upload without caching
  async upload<T>(url: string, formData: FormData, config?: any): Promise<T> {
    const result = await apiService.upload<T>(url, formData, config);
    
    // Invalidate related caches after mutations
    this.invalidateRelatedCaches(url);
    
    return result;
  },

  // Cache invalidation methods
  invalidateRelatedCaches(url: string, data?: any) {
    // Invalidate based on URL patterns
    if (url.includes('/companies')) {
      mediumCache.delete(CACHE_KEYS.COMPANIES_LIST);
      console.log('Invalidated companies cache');
    }
    
    if (url.includes('/users')) {
      mediumCache.delete(CACHE_KEYS.USERS_LIST);
      console.log('Invalidated users cache');
    }
    
    if (url.includes('/settings')) {
      longCache.delete(CACHE_KEYS.SYSTEM_SETTINGS);
      console.log('Invalidated settings cache');
    }
    
    if (url.includes('/analytics')) {
      mediumCache.delete(CACHE_KEYS.ANALYTICS_DATA('30d'));
      console.log('Invalidated analytics cache');
    }
    
    if (url.includes('/dashboard')) {
      shortCache.delete(CACHE_KEYS.DASHBOARD_STATS);
      console.log('Invalidated dashboard cache');
    }
  },

  // Manual cache invalidation
  invalidateCache(pattern: string) {
    [shortCache, mediumCache, longCache, staticCache].forEach(cache => {
      // This is a simplified invalidation - in production you'd want more sophisticated pattern matching
      console.log(`Invalidating cache pattern: ${pattern}`);
    });
  },

  // Clear all caches
  clearAllCaches() {
    shortCache.clear();
    mediumCache.clear();
    longCache.clear();
    staticCache.clear();
    console.log('All caches cleared');
  },

  // Get cache statistics
  getCacheStats() {
    return {
      short: shortCache.getStats(),
      medium: mediumCache.getStats(),
      long: longCache.getStats(),
      static: staticCache.getStats()
    };
  },

  // Preload important data
  async preloadData() {
    try {
      console.log('Preloading important data...');
      
      // Preload subscription plans (long cache)
      await this.get('/api/super-admin/subscription-plans');
      
      // Preload system settings (long cache)
      await this.get('/api/super-admin/settings');
      
      console.log('Data preloading completed');
    } catch (error) {
      console.warn('Data preloading failed:', error);
    }
  }
};

export default cachedApiService; 