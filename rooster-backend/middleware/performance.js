const compression = require('compression');
const NodeCache = require('node-cache');

// Initialize cache with 5 minutes TTL and check period of 10 minutes
const apiCache = new NodeCache({ 
  stdTTL: 300, // 5 minutes
  checkperiod: 600, // 10 minutes
  useClones: false // Better performance
});

// Compression middleware for all responses
const compressionMiddleware = compression({
  level: 6, // Balanced compression level
  threshold: 1024, // Only compress responses > 1KB
  filter: (req, res) => {
    // Don't compress if client doesn't support it
    if (req.headers['x-no-compression']) {
      return false;
    }
    // Use compression for all other responses
    return compression.filter(req, res);
  }
});

// Cache middleware for GET requests
const cacheMiddleware = (duration = 300) => {
  return (req, res, next) => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next();
    }

    // Skip cache for authenticated requests with specific headers
    if (req.headers['cache-control'] === 'no-cache' || 
        req.headers['authorization']) {
      return next();
    }

    const key = `${req.originalUrl || req.url}`;
    const cachedResponse = apiCache.get(key);

    if (cachedResponse) {
      res.set('X-Cache', 'HIT');
      return res.json(cachedResponse);
    }

    // Store original send function
    const originalSend = res.json;

    // Override send function to cache response
    res.json = function(data) {
      // Cache the response
      apiCache.set(key, data, duration);
      res.set('X-Cache', 'MISS');
      
      // Call original send function
      return originalSend.call(this, data);
    };

    next();
  };
};

// Cache invalidation middleware
const invalidateCache = (patterns = []) => {
  return (req, res, next) => {
    // Store original send function
    const originalSend = res.json;

    // Override send function to invalidate cache
    res.json = function(data) {
      // Invalidate cache based on patterns
      patterns.forEach(pattern => {
        const keys = apiCache.keys();
        keys.forEach(key => {
          if (key.includes(pattern)) {
            apiCache.del(key);
          }
        });
      });

      // Call original send function
      return originalSend.call(this, data);
    };

    next();
  };
};

// Performance monitoring middleware
const performanceMonitor = (req, res, next) => {
  const start = Date.now();

  // Add performance headers before response is sent
  res.set('X-Response-Time', '0ms');
  res.set('X-Content-Length', '0');

  // Update headers when response finishes
  res.on('finish', () => {
    const duration = Date.now() - start;
    const contentLength = res.get('Content-Length') || 0;
    
    // Log performance metrics
    console.debug(`PERFORMANCE: ${req.method} ${req.originalUrl} - ${duration}ms - ${contentLength} bytes`);
  });

  next();
};

// Memory monitoring middleware
const memoryMonitor = (req, res, next) => {
  const startMemory = process.memoryUsage();
  
  res.on('finish', () => {
    const endMemory = process.memoryUsage();
    const memoryDiff = {
      rss: endMemory.rss - startMemory.rss,
      heapUsed: endMemory.heapUsed - startMemory.heapUsed,
      heapTotal: endMemory.heapTotal - startMemory.heapTotal,
      external: endMemory.external - startMemory.external
    };
    
    // Log if memory usage increased significantly
    if (memoryDiff.heapUsed > 50 * 1024 * 1024) { // 50MB increase
      console.warn(`MEMORY_WARNING: ${req.method} ${req.originalUrl} - Heap used increased by ${Math.round(memoryDiff.heapUsed / 1024 / 1024)}MB`);
    }
    
    // Log if total memory usage is high
    if (endMemory.heapUsed > 500 * 1024 * 1024) { // 500MB threshold
      console.error(`MEMORY_CRITICAL: ${req.method} ${req.originalUrl} - Heap used: ${Math.round(endMemory.heapUsed / 1024 / 1024)}MB`);
    }
  });
  
  next();
};

// Response size limiter middleware
const responseSizeLimiter = (maxSizeMB = 50) => {
  return (req, res, next) => {
    const originalSend = res.send;
    const originalJson = res.json;
    
    res.send = function(data) {
      const dataSize = Buffer.byteLength(data, 'utf8');
      const sizeMB = dataSize / 1024 / 1024;
      
      if (sizeMB > maxSizeMB) {
        console.error(`RESPONSE_SIZE_WARNING: ${req.method} ${req.originalUrl} - Response size: ${sizeMB.toFixed(2)}MB (limit: ${maxSizeMB}MB)`);
        return res.status(413).json({ 
          error: 'Response too large', 
          message: `Response size (${sizeMB.toFixed(2)}MB) exceeds limit (${maxSizeMB}MB)` 
        });
      }
      
      return originalSend.call(this, data);
    };
    
    res.json = function(data) {
      const dataSize = Buffer.byteLength(JSON.stringify(data), 'utf8');
      const sizeMB = dataSize / 1024 / 1024;
      
      if (sizeMB > maxSizeMB) {
        console.error(`RESPONSE_SIZE_WARNING: ${req.method} ${req.originalUrl} - JSON response size: ${sizeMB.toFixed(2)}MB (limit: ${maxSizeMB}MB)`);
        return res.status(413).json({ 
          error: 'Response too large', 
          message: `Response size (${sizeMB.toFixed(2)}MB) exceeds limit (${maxSizeMB}MB)` 
        });
      }
      
      return originalJson.call(this, data);
    };
    
    next();
  };
};

// Database query optimization helper
const optimizeQuery = (query, options = {}) => {
  const {
    limit = 50,
    sort = { createdAt: -1 },
    select = null,
    populate = null
  } = options;

  // Add pagination
  if (limit) {
    query = query.limit(limit);
  }

  // Add sorting
  if (sort) {
    query = query.sort(sort);
  }

  // Add field selection
  if (select) {
    query = query.select(select);
  }

  // Add population
  if (populate) {
    query = query.populate(populate);
  }

  return query;
};

// Lazy loading helper for large datasets
const lazyLoad = (model, filter = {}, options = {}) => {
  const {
    page = 1,
    limit = 20,
    sort = { createdAt: -1 },
    select = null,
    populate = null
  } = options;

  const skip = (page - 1) * limit;

  let query = model.find(filter);

  // Apply optimizations
  query = optimizeQuery(query, { limit, sort, select, populate });
  query = query.skip(skip);

  return query;
};

// Cache statistics
const getCacheStats = () => {
  return {
    keys: apiCache.keys().length,
    hits: apiCache.getStats().hits,
    misses: apiCache.getStats().misses,
    hitRate: apiCache.getStats().hits / (apiCache.getStats().hits + apiCache.getStats().misses) * 100
  };
};

// Clear all cache
const clearCache = () => {
  apiCache.flushAll();
  return { message: 'Cache cleared successfully' };
};

module.exports = {
  compressionMiddleware,
  cacheMiddleware,
  invalidateCache,
  performanceMonitor,
  memoryMonitor,
  responseSizeLimiter,
  optimizeQuery,
  lazyLoad,
  getCacheStats,
  clearCache,
  apiCache
}; 