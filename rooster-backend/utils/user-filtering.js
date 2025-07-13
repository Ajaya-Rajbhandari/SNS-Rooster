/**
 * User Filtering Utility
 * Centralized logic for filtering users by role across all features
 */

const User = require('../models/User');

/**
 * Get user filter based on feature and admin preference
 * @param {string} feature - The feature name (timesheet, leave, analytics, etc.)
 * @param {Object} options - Filtering options
 * @param {boolean} options.includeAdmins - Whether to include admin users (default: true)
 * @param {boolean} options.onlyEmployees - Whether to show only employees (default: false)
 * @param {boolean} options.onlyAdmins - Whether to show only admins (default: false)
 * @returns {Object} - Mongoose filter object
 */
function getUserFilter(feature, options = {}) {
  const { includeAdmins = true, onlyEmployees = false, onlyAdmins = false } = options;
  
  // Default behavior: include all users with attendance/activity
  if (includeAdmins && !onlyEmployees && !onlyAdmins) {
    return {}; // No filter - include all users
  }
  
  // Filter by role based on options
  if (onlyEmployees) {
    return { role: 'employee' };
  }
  
  if (onlyAdmins) {
    return { role: 'admin' };
  }
  
  // Feature-specific defaults
  const featureDefaults = {
    timesheet: { includeAdmins: true }, // Show all users with attendance
    leave: { includeAdmins: true },     // Show all users with leave requests
    analytics: { onlyEmployees: true }, // Analytics typically focus on employees
    employeeManagement: { onlyEmployees: true }, // Employee management is for employees
    attendanceStats: { onlyEmployees: true }, // Stats typically for employees
  };
  
  const featureDefault = featureDefaults[feature] || { includeAdmins: true };
  
  // Apply feature default if no explicit option provided
  if (featureDefault.onlyEmployees) {
    return { role: 'employee' };
  }
  
  return {}; // Default: include all users
}

/**
 * Get user IDs for filtering in related collections
 * @param {string} feature - The feature name
 * @param {Object} options - Filtering options
 * @returns {Array} - Array of user IDs to include
 */
async function getUserIdsForFilter(feature, options = {}) {
  const filter = getUserFilter(feature, options);
  const users = await User.find(filter, '_id');
  return users.map(user => user._id);
}

/**
 * Create population filter for related collections
 * @param {string} feature - The feature name
 * @param {Object} options - Filtering options
 * @returns {Object} - Mongoose populate options with match filter
 */
function getPopulationFilter(feature, options = {}) {
  const filter = getUserFilter(feature, options);
  
  if (Object.keys(filter).length === 0) {
    return { path: 'user', select: 'firstName lastName email role userId' };
  }
  
  return {
    path: 'user',
    match: filter,
    select: 'firstName lastName email role userId'
  };
}

module.exports = {
  getUserFilter,
  getUserIdsForFilter,
  getPopulationFilter
}; 