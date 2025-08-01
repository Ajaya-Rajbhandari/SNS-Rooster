const LeavePolicy = require('../models/LeavePolicy');
const Company = require('../models/Company');

// Get all leave policies across all companies (for super admin)
exports.getAllLeavePolicies = async (req, res) => {
  try {
    const policies = await LeavePolicy.find({ isActive: true })
      .populate('companyId', 'name domain')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: policies
    });
  } catch (error) {
    console.error('Error fetching all leave policies:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave policies'
    });
  }
};

// Get leave policies for a specific company
exports.getCompanyLeavePolicies = async (req, res) => {
  try {
    const { companyId } = req.params;

    // Validate company exists
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Company not found'
      });
    }

    const policies = await LeavePolicy.find({
      companyId,
      isActive: true
    }).sort({ isDefault: -1, createdAt: -1 });

    res.json({
      success: true,
      data: policies,
      company: {
        id: company._id,
        name: company.name,
        domain: company.domain
      }
    });
  } catch (error) {
    console.error('Error fetching company leave policies:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching company leave policies'
    });
  }
};

// Create leave policy for a specific company
exports.createCompanyLeavePolicy = async (req, res) => {
  try {
    const { companyId } = req.params;
    const { name, description, leaveTypes, rules, isDefault } = req.body;

    // Validate company exists
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Company not found'
      });
    }

    // Validate required fields
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Policy name is required'
      });
    }

    // If this is set as default, unset other default policies for this company
    if (isDefault) {
      await LeavePolicy.updateMany(
        { companyId },
        { isDefault: false }
      );
    }

    const policy = new LeavePolicy({
      companyId,
      name,
      description,
      leaveTypes,
      rules,
      isDefault: isDefault || false
    });

    await policy.save();

    res.status(201).json({
      success: true,
      data: policy,
      message: 'Leave policy created successfully'
    });
  } catch (error) {
    console.error('Error creating company leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating leave policy'
    });
  }
};

// Update leave policy for a specific company
exports.updateCompanyLeavePolicy = async (req, res) => {
  try {
    const { companyId, policyId } = req.params;
    const updates = req.body;

    // Validate company exists
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Company not found'
      });
    }

    // If this is set as default, unset other default policies for this company
    if (updates.isDefault) {
      await LeavePolicy.updateMany(
        { companyId, _id: { $ne: policyId } },
        { isDefault: false }
      );
    }

    const policy = await LeavePolicy.findOneAndUpdate(
      { _id: policyId, companyId },
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
    console.error('Error updating company leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating leave policy'
    });
  }
};

// Delete leave policy for a specific company
exports.deleteCompanyLeavePolicy = async (req, res) => {
  try {
    const { companyId, policyId } = req.params;

    // Validate company exists
    const company = await Company.findById(companyId);
    if (!company) {
      return res.status(404).json({
        success: false,
        message: 'Company not found'
      });
    }

    const policy = await LeavePolicy.findOne({
      _id: policyId,
      companyId
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

    await LeavePolicy.findByIdAndDelete(policyId);

    res.json({
      success: true,
      message: 'Leave policy deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting company leave policy:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting leave policy'
    });
  }
};

// Get leave policy statistics across all companies
exports.getLeavePolicyStatistics = async (req, res) => {
  try {
    const totalPolicies = await LeavePolicy.countDocuments({ isActive: true });
    const defaultPolicies = await LeavePolicy.countDocuments({ isDefault: true, isActive: true });
    const companiesWithPolicies = await LeavePolicy.distinct('companyId').countDocuments();
    const totalCompanies = await Company.countDocuments();

    res.json({
      success: true,
      data: {
        totalPolicies,
        defaultPolicies,
        companiesWithPolicies,
        totalCompanies,
        coveragePercentage: totalCompanies > 0 ? Math.round((companiesWithPolicies / totalCompanies) * 100) : 0
      }
    });
  } catch (error) {
    console.error('Error fetching leave policy statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching leave policy statistics'
    });
  }
}; 