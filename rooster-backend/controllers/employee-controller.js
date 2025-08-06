const mongoose = require('mongoose');
const Employee = require('../models/Employee');
const User = require('../models/User');
const Notification = require('../models/Notification');
const Location = require('../models/Location');

function getAvatarUrl(avatar) {
  if (!avatar) return null;
  if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
    return avatar;
  }
  return `/uploads/avatars/${avatar}`;
}

exports.getAllEmployees = async (req, res) => {
  try {
    console.log('DEBUG: getAllEmployees called, user role:', req.user.role);
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can view all employees' });
    }
    const showInactive = req.query.showInactive === 'true';
    const filter = showInactive ? { companyId: req.companyId } : { isActive: true, companyId: req.companyId };
    console.log('DEBUG: Employee filter:', filter);
    const employees = await Employee.find(filter);
    console.log('DEBUG: Found employees count:', employees.length);
    const employeesWithAvatar = employees.map(e => {
      const obj = e.toObject();
      obj.avatar = getAvatarUrl(obj.avatar);
      return obj;
    });
    res.status(200).json(employeesWithAvatar);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getEmployeeById = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== req.params.id) {
      return res.status(403).json({ message: 'Unauthorized to view this employee data' });
    }
    
    const employee = await Employee.findOne({ _id: req.params.id, companyId: req.companyId });
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    const obj = employee.toObject();
    obj.avatar = getAvatarUrl(obj.avatar);
    res.status(200).json(obj);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can create new employees' });
    }

    // Check if user exists and has 'employee' role
    const user = await User.findOne({ _id: req.body.userId, companyId: req.companyId });
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }
    if (user.role !== 'employee') {
      return res.status(400).json({ message: 'User must have the employee role to be assigned as an employee.' });
    }

    // Prevent duplicate employee records for the same user
    const existingEmployee = await Employee.findOne({ userId: req.body.userId, companyId: req.companyId });
    if (existingEmployee) {
      return res.status(400).json({ message: 'This user is already assigned as an employee.' });
    }

    const employee = new Employee({
      userId: req.body.userId,
      companyId: req.companyId,
      firstName: req.body.firstName,
      lastName: req.body.lastName,
      email: req.body.email,
      employeeId: req.body.employeeId,
      hireDate: req.body.hireDate,
      position: req.body.position,
      department: req.body.department,
      hourlyRate: req.body.hourlyRate,
      monthlySalary: req.body.monthlySalary,
      employeeType: req.body.employeeType,
      employeeSubType: req.body.employeeSubType,
    });

    const newEmployee = await employee.save();

    // Also update the corresponding User document with position and department
    try {
      if (req.body.position !== undefined) user.position = req.body.position;
      if (req.body.department !== undefined) user.department = req.body.department;
      await user.save();
    } catch (err) {
      console.error('Warning: Failed to sync position/department to User:', err);
    }

    res.status(201).json(newEmployee);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.updateEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin' && req.user.role !== 'manager' && req.user.userId !== req.params.id) {
      return res.status(403).json({ message: 'Unauthorized to update this employee data' });
    }
    
    const employee = await Employee.findOne({ _id: req.params.id, companyId: req.companyId });
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }

    employee.firstName = req.body.firstName || employee.firstName;
    employee.lastName = req.body.lastName || employee.lastName;
    employee.email = req.body.email || employee.email;
    employee.employeeId = req.body.employeeId || employee.employeeId;
    employee.hireDate = req.body.hireDate || employee.hireDate;
    employee.position = req.body.position || employee.position;
    employee.department = req.body.department || employee.department;
    employee.userId = req.body.userId || employee.userId;
    if (req.body.hourlyRate !== undefined) employee.hourlyRate = req.body.hourlyRate;
    if (req.body.monthlySalary !== undefined) employee.monthlySalary = req.body.monthlySalary;

    // Sync position & department changes to User model if this employee is linked
    if (employee.userId) {
      try {
        const linkedUser = await User.findOne({ _id: employee.userId, companyId: req.companyId });
        if (linkedUser) {
          if (req.body.position !== undefined) linkedUser.position = req.body.position;
          if (req.body.department !== undefined) linkedUser.department = req.body.department;
          await linkedUser.save();
        }
      } catch (err) {
        console.error('Warning: Failed to sync position/department to User on update:', err);
      }
    }

    const updatedEmployee = await employee.save();
    res.status(200).json(updatedEmployee);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.deleteEmployee = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can delete employees' });
    }
    
    const employee = await Employee.findOneAndDelete({ _id: req.params.id, companyId: req.companyId });
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    res.status(200).json({ message: 'Employee deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getEmployeeDashboard = async (req, res) => {
  try {
    console.log('DASHBOARD ROUTE: Returning mock data directly');
    const mockData = {
      tasks: ['Task 1', 'Task 2'],
      notifications: ['Notification 1'],
      stats: {
        completedTasks: 10,
        pendingTasks: 5,
      },
    };
    res.status(200).json({ dashboardData: mockData });
  } catch (error) {
    console.error('DASHBOARD ROUTE: Error processing request:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getEmployeeByUserId = async (req, res) => {
  try {
    const userId = req.params.userId;
    console.log('Fetching employee with userId:', userId);

    const employee = await Employee.findOne({ userId, companyId: req.companyId });

    if (!employee) {
      console.error(`No employee found for userId: ${userId}`);
      return res.status(404).json({ message: 'Employee record not found' });
    }

    const employeeObj = employee.toObject();
    employeeObj.userId = employeeObj.userId?.toString();
    employeeObj.avatar = getAvatarUrl(employeeObj.avatar);
    res.status(200).json({ data: employeeObj });
  } catch (error) {
    console.error('Error fetching employee by userId:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.getLeaveBalance = async (req, res) => {
  try {
    const employeeId = req.params.id;
    console.log('DEBUG: getLeaveBalance called for employeeId:', employeeId);
    console.log('DEBUG: Request companyId:', req.companyId);
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(employeeId)) {
      return res.status(400).json({ message: 'Invalid employee ID.' });
    }

    // Use the new leave policy controller to calculate balance
    const leavePolicyController = require('./leave-policy-controller');
    
    // Create a mock request object for the policy controller
    const mockReq = {
      ...req,
      params: { employeeId },
      query: req.query
    };

    console.log('DEBUG: Calling leavePolicyController.calculateLeaveBalance');
    // Call the policy controller's calculateLeaveBalance method
    await leavePolicyController.calculateLeaveBalance(mockReq, res);
    
  } catch (e) {
    console.error('Error in getLeaveBalance:', e);
    res.status(500).json({ message: 'Error fetching leave balance.' });
  }
};

exports.getUnassignedUsers = async (req, res) => {
  try {
    // Only consider Employee records with a valid userId in the current company
    const assignedUserIds = (await Employee.find({ companyId: req.companyId }, 'userId')).map(e => e.userId && e.userId.toString()).filter(Boolean);
    
    // Only return users who are not assigned, have role 'employee', are active, and belong to the current company
    const unassignedUsers = await User.find({
      _id: { $nin: assignedUserIds },
      role: 'employee',
      isActive: true,
      companyId: req.companyId
    });
    
    console.log('Unassigned users in company', req.companyId, ':', unassignedUsers.map(u => u.email));
    res.json(unassignedUsers);
  } catch (err) {
    console.error('Error in getUnassignedUsers:', err);
    res.status(500).json({ message: 'Error fetching unassigned users' });
  }
};

exports.verifyUserDocument = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can verify documents' });
    }
    const { userId, docId } = req.params;
    const { status } = req.body;
    if (!['verified', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const doc = user.documents.id(docId);
    if (!doc) return res.status(404).json({ message: 'Document not found' });

    doc.status = status;
    doc.verifiedBy = req.user.userId;
    doc.verifiedAt = new Date();

    await user.save();

    // Send notification to employee
    try {
      const existing = await Notification.findOne({
        user: user._id,
        title: 'Document Review',
        message: { $regex: new RegExp(`^Your ${doc.type} has been (verified|rejected)\.`, 'i') }
      });
      if (!existing) {
        await Notification.create({
          user: user._id,
          role: 'employee',
          title: 'Document Review',
          message: `Your ${doc.type} has been ${status}.`,
          type: 'review',
          link: '/profile',
        });
      }
    } catch (nErr) {
      console.error('Failed to create notification for document review:', nErr);
    }

    res.json({ message: `Document ${status}`, document: doc });
  } catch (error) {
    console.error('verifyUserDocument error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.adminChangeUserPassword = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can change user passwords' });
    }
    const userId = req.params.id;
    const { password } = req.body;
    if (!password || password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters long' });
    }
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    user.password = password; // Will be hashed by pre-save hook
    await user.save();
    res.json({ message: 'Password updated successfully for user.' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

exports.getEmployeeLocation = async (req, res) => {
  try {
    console.log('DEBUG: getEmployeeLocation called for user:', req.user.userId);
    
    // Find the employee record for the current user
    const employee = await Employee.findOne({ 
      userId: req.user.userId, 
      companyId: req.companyId 
    });
    
    if (!employee) {
      console.log('DEBUG: Employee record not found for user:', req.user.userId);
      return res.status(404).json({ message: 'Employee record not found' });
    }
    
    console.log('DEBUG: Employee found, locationId:', employee.locationId);
    
    if (!employee.locationId) {
      console.log('DEBUG: No location assigned to employee');
      return res.json({ assignedLocation: null });
    }
    
    // Get the location details
    const location = await Location.findById(employee.locationId);
    
    if (!location) {
      console.log('DEBUG: Location not found for ID:', employee.locationId);
      return res.json({ assignedLocation: null });
    }
    
    console.log('DEBUG: Location found:', location.name);
    
    const locationData = {
      _id: location._id,
      name: location.name,
      address: location.address,
      coordinates: location.coordinates,
      status: location.status,
      settings: location.settings,
      createdAt: location.createdAt,
      updatedAt: location.updatedAt
    };
    
    res.json({ assignedLocation: locationData });
    
  } catch (error) {
    console.error('Error in getEmployeeLocation:', error);
    res.status(500).json({ message: 'Error fetching employee location' });
  }
};

exports.updateEmployeeLocation = async (req, res) => {
  try {
    console.log('DEBUG: updateEmployeeLocation called for employee:', req.params.id);
    console.log('DEBUG: New locationId:', req.body.locationId);
    
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can update employee locations' });
    }
    
    const { locationId } = req.body;
    
    if (!locationId) {
      return res.status(400).json({ message: 'Location ID is required' });
    }
    
    // Verify the location exists and belongs to the company
    const location = await Location.findOne({ 
      _id: locationId, 
      companyId: req.companyId 
    });
    
    if (!location) {
      return res.status(404).json({ message: 'Location not found' });
    }
    
    // Update the employee's location
    const employee = await Employee.findByIdAndUpdate(
      req.params.id,
      { locationId: locationId },
      { new: true }
    );
    
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    
    console.log('DEBUG: Employee location updated successfully');
    
    res.json({ 
      success: true,
      message: 'Employee location updated successfully',
      employee: {
        _id: employee._id,
        firstName: employee.firstName,
        lastName: employee.lastName,
        locationId: employee.locationId
      }
    });
    
  } catch (error) {
    console.error('Error in updateEmployeeLocation:', error);
    res.status(500).json({ message: 'Error updating employee location' });
  }
};

exports.getEmployeesByLocation = async (req, res) => {
  try {
    console.log('DEBUG: getEmployeesByLocation called for location:', req.params.locationId);
    
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can view employees by location' });
    }
    
    const { locationId } = req.params;
    
    // Verify the location exists and belongs to the company
    const location = await Location.findOne({ 
      _id: locationId, 
      companyId: req.companyId 
    });
    
    if (!location) {
      return res.status(404).json({ message: 'Location not found' });
    }
    
    // Get all employees assigned to this location
    const employees = await Employee.find({ 
      locationId: locationId,
      companyId: req.companyId 
    });
    
    console.log('DEBUG: Found', employees.length, 'employees assigned to location');
    
    const employeesWithAvatar = employees.map(e => {
      const obj = e.toObject();
      obj.avatar = getAvatarUrl(obj.avatar);
      return obj;
    });
    
    res.json(employeesWithAvatar);
    
  } catch (error) {
    console.error('Error in getEmployeesByLocation:', error);
    res.status(500).json({ message: 'Error fetching employees by location' });
  }
};

exports.removeEmployeeFromLocation = async (req, res) => {
  try {
    console.log('DEBUG: removeEmployeeFromLocation called for employee:', req.params.id);
    
    if (req.user.role !== 'admin' && req.user.role !== 'manager') {
      return res.status(403).json({ message: 'Only admins and managers can remove employees from locations' });
    }
    
    const { id: employeeId } = req.params;
    
    // Find the employee and verify they belong to the company
    const employee = await Employee.findOne({ 
      _id: employeeId, 
      companyId: req.companyId 
    });
    
    if (!employee) {
      return res.status(404).json({ message: 'Employee not found' });
    }
    
    // Check if employee is currently assigned to a location
    if (!employee.locationId) {
      return res.status(400).json({ message: 'Employee is not currently assigned to any location' });
    }
    
    // Get the current location for logging
    const currentLocation = await Location.findById(employee.locationId);
    const locationName = currentLocation ? currentLocation.name : 'Unknown Location';
    
    // Remove the employee from their current location
    employee.locationId = null;
    await employee.save();
    
    console.log('DEBUG: Employee removed from location successfully');
    
    res.json({ 
      success: true,
      message: `Employee removed from ${locationName} successfully`,
      employee: {
        _id: employee._id,
        firstName: employee.firstName,
        lastName: employee.lastName,
        locationId: employee.locationId
      }
    });
    
  } catch (error) {
    console.error('Error in removeEmployeeFromLocation:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error removing employee from location' 
    });
  }
};

// Bulk operations for employee management
exports.bulkCreateEmployees = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can perform bulk operations' });
    }

    const { employees } = req.body;
    
    if (!employees || !Array.isArray(employees) || employees.length === 0) {
      return res.status(400).json({ message: 'Employees array is required and must not be empty' });
    }

    if (employees.length > 100) {
      return res.status(400).json({ message: 'Cannot create more than 100 employees at once' });
    }

    const results = {
      successful: [],
      failed: [],
      total: employees.length
    };

    for (const employeeData of employees) {
      try {
        // Validate required fields
        if (!employeeData.email || !employeeData.firstName || !employeeData.lastName) {
          results.failed.push({
            email: employeeData.email,
            error: 'Missing required fields: email, firstName, lastName'
          });
          continue;
        }

        // Check if user already exists
        let user = await User.findOne({ 
          email: employeeData.email, 
          companyId: req.companyId 
        });

        if (!user) {
          // Create new user
          user = new User({
            email: employeeData.email,
            password: employeeData.password || 'defaultPassword123', // Will be changed on first login
            firstName: employeeData.firstName,
            lastName: employeeData.lastName,
            role: 'employee',
            companyId: req.companyId,
            position: employeeData.position,
            department: employeeData.department,
            isActive: true
          });
          await user.save();
        } else if (user.role !== 'employee') {
          results.failed.push({
            email: employeeData.email,
            error: 'User exists but is not an employee'
          });
          continue;
        }

        // Check if employee record already exists
        const existingEmployee = await Employee.findOne({ 
          userId: user._id, 
          companyId: req.companyId 
        });

        if (existingEmployee) {
          results.failed.push({
            email: employeeData.email,
            error: 'Employee already exists'
          });
          continue;
        }

        // Create employee record
        const employee = new Employee({
          userId: user._id,
          companyId: req.companyId,
          firstName: employeeData.firstName,
          lastName: employeeData.lastName,
          email: employeeData.email,
          employeeId: employeeData.employeeId,
          hireDate: employeeData.hireDate || new Date(),
          position: employeeData.position,
          department: employeeData.department,
          hourlyRate: employeeData.hourlyRate,
          monthlySalary: employeeData.monthlySalary,
          employeeType: employeeData.employeeType || 'Full-time',
          employeeSubType: employeeData.employeeSubType,
          isActive: true
        });

        const newEmployee = await employee.save();
        
        results.successful.push({
          email: employeeData.email,
          employeeId: newEmployee._id,
          userId: user._id
        });

      } catch (error) {
        results.failed.push({
          email: employeeData.email,
          error: error.message
        });
      }
    }

    res.status(200).json({
      message: `Bulk employee creation completed. ${results.successful.length} successful, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    console.error('Bulk create employees error:', error);
    res.status(500).json({ message: error.message });
  }
};

exports.bulkUpdateEmployees = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can perform bulk operations' });
    }

    const { updates } = req.body;
    
    if (!updates || !Array.isArray(updates) || updates.length === 0) {
      return res.status(400).json({ message: 'Updates array is required and must not be empty' });
    }

    if (updates.length > 100) {
      return res.status(400).json({ message: 'Cannot update more than 100 employees at once' });
    }

    const results = {
      successful: [],
      failed: [],
      total: updates.length
    };

    for (const updateData of updates) {
      try {
        const { employeeId, updates: employeeUpdates } = updateData;

        if (!employeeId) {
          results.failed.push({
            employeeId: 'unknown',
            error: 'Employee ID is required'
          });
          continue;
        }

        // Validate employee exists and belongs to company
        const employee = await Employee.findOne({ 
          _id: employeeId, 
          companyId: req.companyId 
        });

        if (!employee) {
          results.failed.push({
            employeeId,
            error: 'Employee not found'
          });
          continue;
        }

        // Update employee
        const updatedEmployee = await Employee.findByIdAndUpdate(
          employeeId,
          employeeUpdates,
          { new: true, runValidators: true }
        );

        // Also update corresponding user if position/department changed
        if (employeeUpdates.position || employeeUpdates.department) {
          await User.findByIdAndUpdate(employee.userId, {
            position: employeeUpdates.position,
            department: employeeUpdates.department
          });
        }

        results.successful.push({
          employeeId,
          email: updatedEmployee.email
        });

      } catch (error) {
        results.failed.push({
          employeeId: updateData.employeeId || 'unknown',
          error: error.message
        });
      }
    }

    res.status(200).json({
      message: `Bulk employee update completed. ${results.successful.length} successful, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    console.error('Bulk update employees error:', error);
    res.status(500).json({ message: error.message });
  }
};

exports.bulkDeleteEmployees = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can perform bulk operations' });
    }

    const { employeeIds } = req.body;
    
    if (!employeeIds || !Array.isArray(employeeIds) || employeeIds.length === 0) {
      return res.status(400).json({ message: 'Employee IDs array is required and must not be empty' });
    }

    if (employeeIds.length > 100) {
      return res.status(400).json({ message: 'Cannot delete more than 100 employees at once' });
    }

    const results = {
      successful: [],
      failed: [],
      total: employeeIds.length
    };

    for (const employeeId of employeeIds) {
      try {
        // Validate employee exists and belongs to company
        const employee = await Employee.findOne({ 
          _id: employeeId, 
          companyId: req.companyId 
        });

        if (!employee) {
          results.failed.push({
            employeeId,
            error: 'Employee not found'
          });
          continue;
        }

        // Delete employee
        await Employee.findByIdAndDelete(employeeId);

        // Optionally deactivate user (soft delete)
        await User.findByIdAndUpdate(employee.userId, { isActive: false });

        results.successful.push({
          employeeId,
          email: employee.email
        });

      } catch (error) {
        results.failed.push({
          employeeId,
          error: error.message
        });
      }
    }

    res.status(200).json({
      message: `Bulk employee deletion completed. ${results.successful.length} successful, ${results.failed.length} failed`,
      results
    });

  } catch (error) {
    console.error('Bulk delete employees error:', error);
    res.status(500).json({ message: error.message });
  }
};