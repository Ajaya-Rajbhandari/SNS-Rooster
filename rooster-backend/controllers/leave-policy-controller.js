const LeavePolicy = require('../models/LeavePolicy');
const Leave = require('../models/Leave');
const Employee = require('../models/Employee');

// Get company's leave policies
exports.getLeavePolicies = async (req, res) => {
  try {
    const policies = await LeavePolicy.find({
      companyId: req.companyId,
      isActive: true
    }).sort({ isDefault: -1, createdAt: -1 });

    res.json({
      success: true,
      data: policies
    });
  } catch (error) {
    console.error('Error fetching leave policies:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave policies'
    });
  }
};

// Get default leave policy for company
exports.getDefaultPolicy = async (req, res) => {
  try {
    let policy = await LeavePolicy.findOne({
      companyId: req.companyId,
      isDefault: true,
      isActive: true
    });

    // If no default policy exists, create one
    if (!policy) {
      policy = new LeavePolicy({
        companyId: req.companyId,
        name: 'Default Policy',
        description: 'Default leave policy for the company',
        isDefault: true
      });
      await policy.save();
    }

    res.json({
      success: true,
      data: policy
    });
  } catch (error) {
    console.error('Error fetching default policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching default policy'
    });
  }
};

// Create new leave policy
exports.createLeavePolicy = async (req, res) => {
  try {
    const { name, description, leaveTypes, rules } = req.body;

    // Validate required fields
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Policy name is required'
      });
    }

    // If this is set as default, unset other default policies
    if (req.body.isDefault) {
      await LeavePolicy.updateMany(
        { companyId: req.companyId },
        { isDefault: false }
      );
    }

    const policy = new LeavePolicy({
      companyId: req.companyId,
      name,
      description,
      leaveTypes,
      rules,
      isDefault: req.body.isDefault || false
    });

    await policy.save();

    res.status(201).json({
      success: true,
      data: policy,
      message: 'Leave policy created successfully'
    });
  } catch (error) {
    console.error('Error creating leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating leave policy'
    });
  }
};

// Update leave policy
exports.updateLeavePolicy = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // If this is set as default, unset other default policies
    if (updates.isDefault) {
      await LeavePolicy.updateMany(
        { companyId: req.companyId, _id: { $ne: id } },
        { isDefault: false }
      );
    }

    const policy = await LeavePolicy.findOneAndUpdate(
      { _id: id, companyId: req.companyId },
      { ...updates, updatedAt: new Date() },
      { new: true, runValidators: true }
    );

    if (!policy) {
      return res.status(404).json({
        success: false,
        message: 'Leave policy not found'
      });
    }

    res.json({
      success: true,
      data: policy,
      message: 'Leave policy updated successfully'
    });
  } catch (error) {
    console.error('Error updating leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating leave policy'
    });
  }
};

// Delete leave policy
exports.deleteLeavePolicy = async (req, res) => {
  try {
    const { id } = req.params;

    const policy = await LeavePolicy.findOne({
      _id: id,
      companyId: req.companyId
    });

    if (!policy) {
      return res.status(404).json({
        success: false,
        message: 'Leave policy not found'
      });
    }

    // Don't allow deletion of default policy
    if (policy.isDefault) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete default policy'
      });
    }

    await LeavePolicy.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Leave policy deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting leave policy'
    });
  }
};

// Calculate leave balance for employee based on policy
exports.calculateLeaveBalance = async (req, res) => {
  try {
    const { employeeId } = req.params;
    const { policyId } = req.query;

    // Get employee
    const employee = await Employee.findById(employeeId);
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found'
      });
    }

    // Get leave policy (default if not specified)
    let policy;
    if (policyId) {
      policy = await LeavePolicy.findOne({
        _id: policyId,
        companyId: req.companyId,
        isActive: true
      });
    } else {
      policy = await LeavePolicy.findOne({
        companyId: req.companyId,
        isDefault: true,
        isActive: true
      });
    }

    if (!policy) {
      return res.status(404).json({
        success: false,
        message: 'Leave policy not found'
      });
    }

    // Calculate current leave year
    const now = new Date();
    const currentYear = now.getFullYear();
    const policyYearStart = new Date(
      currentYear,
      policy.rules.leaveYearStartMonth - 1,
      policy.rules.leaveYearStartDay
    );

    // If current date is before policy year start, use previous year
    const leaveYearStart = now < policyYearStart 
      ? new Date(currentYear - 1, policy.rules.leaveYearStartMonth - 1, policy.rules.leaveYearStartDay)
      : policyYearStart;

    const leaveYearEnd = new Date(
      leaveYearStart.getFullYear() + 1,
      policy.rules.leaveYearStartMonth - 1,
      policy.rules.leaveYearStartDay
    );

    // Get approved leaves for this leave year
    const leaves = await Leave.find({
      employee: employeeId,
      status: { $regex: /^approved$/i },
      startDate: { $gte: leaveYearStart },
      endDate: { $lt: leaveYearEnd }
    });

    // Calculate used days for each type
    const used = {
      annualLeave: 0,
      sickLeave: 0,
      casualLeave: 0,
      maternityLeave: 0,
      paternityLeave: 0,
      unpaidLeave: 0
    };

    leaves.forEach(leave => {
      const type = (leave.leaveType || '').toLowerCase().replace(/\s/g, '');
      const days = Math.max(1, Math.ceil((new Date(leave.endDate) - new Date(leave.startDate)) / (1000 * 60 * 60 * 24)) + 1);
      
      if (type.includes('annual')) used.annualLeave += days;
      else if (type.includes('sick')) used.sickLeave += days;
      else if (type.includes('casual')) used.casualLeave += days;
      else if (type.includes('maternity')) used.maternityLeave += days;
      else if (type.includes('paternity')) used.paternityLeave += days;
      else if (type.includes('unpaid')) used.unpaidLeave += days;
    });

    // Calculate available days
    const balance = {};
    Object.keys(policy.leaveTypes).forEach(type => {
      const policyType = policy.leaveTypes[type];
      if (policyType.isActive) {
        balance[type] = {
          total: policyType.totalDays,
          used: used[type] || 0,
          available: Math.max(0, policyType.totalDays - (used[type] || 0)),
          description: policyType.description
        };
      }
    });

    const responseData = {
      success: true,
      data: {
        employeeId,
        employeeName: `${employee.firstName} ${employee.lastName}`,
        policyId: policy._id,
        policyName: policy.name,
        leaveYearStart,
        leaveYearEnd,
        balance
      }
    };
    
    console.log('DEBUG: calculateLeaveBalance response:', JSON.stringify(responseData, null, 2));
    res.json(responseData);
  } catch (error) {
    console.error('Error calculating leave balance:', error);
    res.status(500).json({
      success: false,
      message: 'Error calculating leave balance'
    });
  }
}; 