const PerformanceReviewTemplate = require('../models/PerformanceReviewTemplate');
const { Logger } = require('../config/logger');

// Get all templates for the company
exports.getTemplates = async (req, res) => {
  try {
    const companyId = req.companyId;

    // Get company-specific templates
    const companyTemplates = await PerformanceReviewTemplate.find({ companyId })
      .populate('createdBy', 'firstName lastName email')
      .sort({ createdAt: -1 });

    // Get default templates
    const defaultTemplates = PerformanceReviewTemplate.getDefaultTemplates();

    // Combine company templates with default templates
    const allTemplates = [
      ...defaultTemplates.map(template => ({
        ...template,
        _id: `default_${template.name.replace(/\s+/g, '_').toLowerCase()}`,
        isDefault: true
      })),
      ...companyTemplates
    ];

    Logger.info(`Retrieved ${allTemplates.length} templates for company ${companyId}`);

    res.json({
      success: true,
      data: allTemplates
    });
  } catch (error) {
    Logger.error('Error fetching templates:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch templates',
      error: error.message
    });
  }
};

// Get a specific template
exports.getTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;

    // Check if it's a default template
    if (id.startsWith('default_')) {
      const defaultTemplates = PerformanceReviewTemplate.getDefaultTemplates();
      const templateName = id.replace('default_', '').replace(/_/g, ' ');
      const template = defaultTemplates.find(t => 
        t.name.toLowerCase().replace(/\s+/g, ' ') === templateName
      );

      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found'
        });
      }

      return res.json({
        success: true,
        data: {
          ...template,
          _id: id,
          isDefault: true
        }
      });
    }

    // Get company-specific template
    const template = await PerformanceReviewTemplate.findOne({ _id: id, companyId })
      .populate('createdBy', 'firstName lastName email')
      .populate('updatedBy', 'firstName lastName email');

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    Logger.info(`Retrieved template ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: template
    });
  } catch (error) {
    Logger.error('Error fetching template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch template',
      error: error.message
    });
  }
};

// Create a new template
exports.createTemplate = async (req, res) => {
  try {
    const companyId = req.companyId;
    const createdBy = req.user.id;
    const {
      name,
      description,
      categories = [],
      goals = [],
      questions = []
    } = req.body;

    // Validate required fields
    if (!name || !description) {
      return res.status(400).json({
        success: false,
        message: 'Name and description are required'
      });
    }

    // Check if template with same name already exists
    const existingTemplate = await PerformanceReviewTemplate.findOne({
      name,
      companyId
    });

    if (existingTemplate) {
      return res.status(400).json({
        success: false,
        message: 'Template with this name already exists'
      });
    }

    // Create template
    const template = new PerformanceReviewTemplate({
      name,
      description,
      companyId,
      categories,
      goals,
      questions,
      createdBy
    });

    await template.save();

    Logger.info(`Created template ${template._id} for company ${companyId}`);

    res.status(201).json({
      success: true,
      data: template,
      message: 'Template created successfully'
    });
  } catch (error) {
    Logger.error('Error creating template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create template',
      error: error.message
    });
  }
};

// Update a template
exports.updateTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;
    const updatedBy = req.user.id;
    const updateData = { ...req.body, updatedBy };

    // Cannot update default templates
    if (id.startsWith('default_')) {
      return res.status(400).json({
        success: false,
        message: 'Cannot update default templates'
      });
    }

    const template = await PerformanceReviewTemplate.findOneAndUpdate(
      { _id: id, companyId },
      updateData,
      { new: true, runValidators: true }
    ).populate('createdBy', 'firstName lastName email')
     .populate('updatedBy', 'firstName lastName email');

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    Logger.info(`Updated template ${id} for company ${companyId}`);

    res.json({
      success: true,
      data: template,
      message: 'Template updated successfully'
    });
  } catch (error) {
    Logger.error('Error updating template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update template',
      error: error.message
    });
  }
};

// Delete a template
exports.deleteTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;

    // Cannot delete default templates
    if (id.startsWith('default_')) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete default templates'
      });
    }

    const template = await PerformanceReviewTemplate.findOneAndDelete({ _id: id, companyId });

    if (!template) {
      return res.status(404).json({
        success: false,
        message: 'Template not found'
      });
    }

    Logger.info(`Deleted template ${id} for company ${companyId}`);

    res.json({
      success: true,
      message: 'Template deleted successfully'
    });
  } catch (error) {
    Logger.error('Error deleting template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete template',
      error: error.message
    });
  }
};

// Duplicate a template
exports.duplicateTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const companyId = req.companyId;
    const createdBy = req.user.id;
    const { name, description } = req.body;

    let sourceTemplate;

    // Check if it's a default template
    if (id.startsWith('default_')) {
      const defaultTemplates = PerformanceReviewTemplate.getDefaultTemplates();
      const templateName = id.replace('default_', '').replace(/_/g, ' ');
      sourceTemplate = defaultTemplates.find(t => 
        t.name.toLowerCase().replace(/\s+/g, ' ') === templateName
      );

      if (!sourceTemplate) {
        return res.status(404).json({
          success: false,
          message: 'Template not found'
        });
      }
    } else {
      // Get company-specific template
      sourceTemplate = await PerformanceReviewTemplate.findOne({ _id: id, companyId });
      
      if (!sourceTemplate) {
        return res.status(404).json({
          success: false,
          message: 'Template not found'
        });
      }
    }

    // Create new template based on source
    const newTemplate = new PerformanceReviewTemplate({
      name: name || `${sourceTemplate.name} (Copy)`,
      description: description || sourceTemplate.description,
      companyId,
      categories: sourceTemplate.categories,
      goals: sourceTemplate.goals,
      questions: sourceTemplate.questions,
      createdBy
    });

    await newTemplate.save();

    Logger.info(`Duplicated template ${id} to ${newTemplate._id} for company ${companyId}`);

    res.status(201).json({
      success: true,
      data: newTemplate,
      message: 'Template duplicated successfully'
    });
  } catch (error) {
    Logger.error('Error duplicating template:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to duplicate template',
      error: error.message
    });
  }
}; 