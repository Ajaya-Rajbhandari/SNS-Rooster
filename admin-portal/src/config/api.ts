// API Configuration
const API_CONFIG = {
  // Base URL for API calls
  BASE_URL: process.env.REACT_APP_API_BASE_URL || 'https://sns-rooster.onrender.com',
  
  // API endpoints
  ENDPOINTS: {
    // Auth endpoints
    LOGIN: '/api/auth/login',
    LOGOUT: '/api/auth/logout',
    REFRESH_TOKEN: '/api/auth/refresh',
    
    // Super admin endpoints
    SUBSCRIPTION_PLANS: '/api/super-admin/subscription-plans',
    COMPANIES: '/api/companies',
    LEAVE_POLICIES: '/api/super-admin/leave-policies',
    COMPANY_LEAVE_POLICIES: '/api/super-admin/companies',
    
    // Admin endpoints
    ADMIN_ATTENDANCE: '/api/admin/attendance',
    ADMIN_ANALYTICS: '/api/admin/analytics',
    ADMIN_SETTINGS: '/api/admin/settings',
    
    // Employee endpoints
    EMPLOYEES: '/api/employees',
    ATTENDANCE: '/api/attendance',
    PAYROLL: '/api/payroll',
    LEAVE: '/api/leave',
    
    // Other endpoints
    NOTIFICATIONS: '/api/notifications',
    EVENTS: '/api/events',
    FCM: '/api/fcm'
  },
  
  // Request timeout (in milliseconds)
  TIMEOUT: 10000,
  
  // Retry configuration
  RETRY: {
    MAX_ATTEMPTS: 3,
    DELAY: 1000
  }
};

export default API_CONFIG; 