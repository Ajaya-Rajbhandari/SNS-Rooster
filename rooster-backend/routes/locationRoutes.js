const express = require('express');
const router = express.Router();
const Location = require('../models/Location');
const Employee = require('../models/Employee');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');

// Get all locations for the company
router.get('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const locations = await Location.getCompanyLocations(req.companyId);
    
    // Convert to plain objects to ensure activeUsers field is included in JSON
    const locationsWithActiveUsers = locations.map(location => {
      const locationObj = location.toObject();
      locationObj.activeUsers = location.activeUsers || 0;
      return locationObj;
    });
    
    res.json({
      success: true,
      locations: locationsWithActiveUsers,
      count: locations.length
    });
  } catch (error) {
    console.error('Error fetching locations:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch locations',
      message: error.message
    });
  }
});

// Get a specific location by ID
router.get('/:locationId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const location = await Location.getLocationWithEmployeeCount(req.params.locationId);
    
    if (!location) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    // Verify the location belongs to the company
    if (location.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Convert to plain object to ensure activeUsers field is included in JSON
    const locationObj = location.toObject();
    locationObj.activeUsers = location.activeUsers || 0;
    
    res.json({
      success: true,
      location: locationObj
    });
  } catch (error) {
    console.error('Error fetching location:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch location',
      message: error.message
    });
  }
});

// Create a new location
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const {
      name,
      address,
      coordinates,
      contactInfo,
      settings,
      description,
      capacity,
      assignedManager,
      createdBy
    } = req.body;
    
    // Validate required fields
    if (!name || !address) {
      return res.status(400).json({
        success: false,
        error: 'Name and address are required'
      });
    }
    
    // Check if this is the first location (make it default)
    const existingLocations = await Location.countDocuments({ companyId: req.companyId });
    const isDefault = existingLocations === 0;
    
    const location = new Location({
      companyId: req.companyId,
      name,
      address,
      coordinates,
      contactInfo,
      settings,
      description,
      capacity,
      assignedManager,
      isDefault,
      createdBy: createdBy || req.user.id // Use createdBy from request body, fallback to user.id
    });
    
    await location.save();
    
    res.status(201).json({
      success: true,
      location,
      message: 'Location created successfully'
    });
  } catch (error) {
    console.error('Error creating location:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create location',
      message: error.message
    });
  }
});

// Update a location
router.put('/:locationId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const location = await Location.findById(req.params.locationId);
    
    if (!location) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    // Verify the location belongs to the company
    if (location.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    const updateData = req.body;
    
    // Update the location
    Object.assign(location, updateData);
    await location.save();
    
    res.json({
      success: true,
      location,
      message: 'Location updated successfully'
    });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update location',
      message: error.message
    });
  }
});

// Delete a location
router.delete('/:locationId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const location = await Location.findById(req.params.locationId);
    
    if (!location) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    // Verify the location belongs to the company
    if (location.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Check if there are employees assigned to this location
    const employeeCount = await Employee.countDocuments({
      companyId: req.companyId,
      locationId: location._id,
      isActive: true
    });
    
    if (employeeCount > 0) {
      return res.status(400).json({
        success: false,
        error: 'Cannot delete location with assigned employees',
        message: `There are ${employeeCount} employees assigned to this location`
      });
    }
    
    // Soft delete by setting status to deleted
    location.status = 'deleted';
    await location.save();
    
    res.json({
      success: true,
      message: 'Location deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting location:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete location',
      message: error.message
    });
  }
});

// Get location statistics
router.get('/:locationId/stats', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const location = await Location.findById(req.params.locationId);
    
    if (!location) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    // Verify the location belongs to the company
    if (location.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Get employee statistics
    const employeeStats = await Employee.aggregate([
      {
        $match: {
          companyId: req.companyId,
          locationId: location._id,
          isActive: true
        }
      },
      {
        $group: {
          _id: null,
          totalEmployees: { $sum: 1 },
          avgSalary: { $avg: '$monthlySalary' },
          totalSalary: { $sum: '$monthlySalary' }
        }
      }
    ]);
    
    // Get attendance statistics for the location
    const Attendance = require('../models/Attendance');
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    
    const attendanceStats = await Attendance.aggregate([
      {
        $match: {
          companyId: req.companyId,
          date: { $gte: startOfMonth }
        }
      },
      {
        $lookup: {
          from: 'employees',
          localField: 'employeeId',
          foreignField: '_id',
          as: 'employee'
        }
      },
      {
        $match: {
          'employee.locationId': location._id
        }
      },
      {
        $group: {
          _id: null,
          totalAttendance: { $sum: 1 },
          avgWorkHours: { $avg: '$totalHours' }
        }
      }
    ]);
    
    const stats = {
      location: {
        name: location.name,
        capacity: location.capacity,
        currentEmployees: location.currentEmployees,
        utilization: location.capacity > 0 ? Math.round((location.currentEmployees / location.capacity) * 100) : 0
      },
      employees: employeeStats[0] || {
        totalEmployees: 0,
        avgSalary: 0,
        totalSalary: 0
      },
      attendance: attendanceStats[0] || {
        totalAttendance: 0,
        avgWorkHours: 0
      }
    };
    
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('Error fetching location stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch location statistics',
      message: error.message
    });
  }
});

// Assign employees to location
router.post('/:locationId/assign-employees', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const { employeeIds } = req.body;
    
    if (!employeeIds || !Array.isArray(employeeIds)) {
      return res.status(400).json({
        success: false,
        error: 'Employee IDs array is required'
      });
    }
    
    const location = await Location.findById(req.params.locationId);
    
    if (!location) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    // Verify the location belongs to the company
    if (location.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Check capacity
    const newEmployeeCount = location.currentEmployees + employeeIds.length;
    if (newEmployeeCount > location.capacity) {
      return res.status(400).json({
        success: false,
        error: 'Location capacity exceeded',
        message: `Cannot assign ${employeeIds.length} employees. Location capacity is ${location.capacity}`
      });
    }
    
    // Update employees
    const result = await Employee.updateMany(
      {
        _id: { $in: employeeIds },
        companyId: req.companyId
      },
      {
        locationId: location._id
      }
    );
    
    // Update location employee count
    await location.updateEmployeeCount();
    
    res.json({
      success: true,
      message: `Successfully assigned ${result.modifiedCount} employees to location`,
      assignedCount: result.modifiedCount
    });
  } catch (error) {
    console.error('Error assigning employees to location:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to assign employees to location',
      message: error.message
    });
  }
});

module.exports = router; 