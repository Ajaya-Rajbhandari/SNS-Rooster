import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import cachedApiService from '../services/cachedApiService';
import { useAuth } from './AuthContext';

interface CacheContextType {
  stats: any;
  clearAllCaches: () => void;
  invalidateCache: (pattern: string) => void;
  preloadData: () => Promise<void>;
  refreshStats: () => void;
}

const CacheContext = createContext<CacheContextType | undefined>(undefined);

export const useCache = () => {
  const context = useContext(CacheContext);
  if (!context) {
    throw new Error('useCache must be used within a CacheProvider');
  }
  return context;
};

interface CacheProviderProps {
  children: ReactNode;
}

export const CacheProvider: React.FC<CacheProviderProps> = ({ children }) => {
  const [stats, setStats] = useState<any>({});
  const { isAuthenticated } = useAuth();

  const refreshStats = () => {
    setStats(cachedApiService.getCacheStats());
  };

  const clearAllCaches = () => {
    cachedApiService.clearAllCaches();
    refreshStats();
  };

  const invalidateCache = (pattern: string) => {
    cachedApiService.invalidateCache(pattern);
    refreshStats();
  };

  const preloadData = async () => {
    // Only preload data if user is authenticated
    if (isAuthenticated) {
      await cachedApiService.preloadData();
      refreshStats();
    }
  };

  // Refresh stats periodically
  useEffect(() => {
    refreshStats();
    
    const interval = setInterval(refreshStats, 30000); // Every 30 seconds
    
    return () => clearInterval(interval);
  }, []);

  // Preload important data only when authenticated
  useEffect(() => {
    if (isAuthenticated) {
      preloadData();
    }
  }, [isAuthenticated]);

  const value: CacheContextType = {
    stats,
    clearAllCaches,
    invalidateCache,
    preloadData,
    refreshStats
  };

  return (
    <CacheContext.Provider value={value}>
      {children}
    </CacheContext.Provider>
  );
}; 