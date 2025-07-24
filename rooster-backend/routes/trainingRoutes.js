const express = require('express');
const router = express.Router();
const Training = require('../models/Training');
const Employee = require('../models/Employee');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/training/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx|ppt|pptx|xls|xlsx|mp4|avi|mov|wmv/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image, document, presentation, spreadsheet, and video files are allowed'));
    }
  }
});

// Get all trainings for the company
router.get('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      category,
      type,
      startDate,
      endDate,
      search
    } = req.query;
    
    const query = { companyId: req.companyId };
    
    // Apply filters
    if (status) query.status = status;
    if (category) query.category = category;
    if (type) query.type = type;
    if (startDate || endDate) {
      query['schedule.startDate'] = {};
      if (startDate) query['schedule.startDate'].$gte = new Date(startDate);
      if (endDate) query['schedule.startDate'].$lte = new Date(endDate);
    }
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    
    const skip = (page - 1) * limit;
    
    const trainings = await Training.find(query)
      .populate('location', 'name')
      .populate('assignedTo.employeeId', 'firstName lastName email employeeId')
      .populate('createdBy', 'firstName lastName')
      .sort({ 'schedule.startDate': -1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Training.countDocuments(query);
    
    res.json({
      success: true,
      trainings,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching trainings:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch trainings',
      message: error.message
    });
  }
});

// Get training statistics
router.get('/stats', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { startDate, endDate, category, type } = req.query;
    
    const filters = {};
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (category) filters.category = category;
    if (type) filters.type = type;
    
    const stats = await Training.getTrainingStats(req.companyId, filters);
    
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('Error fetching training stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch training statistics',
      message: error.message
    });
  }
});

// Get a specific training by ID
router.get('/:trainingId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId)
      .populate('location', 'name')
      .populate('assignedTo.employeeId', 'firstName lastName email employeeId')
      .populate('createdBy', 'firstName lastName')
      .populate('schedule.sessions.instructor', 'firstName lastName');
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    res.json({
      success: true,
      training
    });
  } catch (error) {
    console.error('Error fetching training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch training',
      message: error.message
    });
  }
});

// Create a new training
router.post('/', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), upload.array('materials', 10), async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      type,
      format,
      duration,
      schedule,
      instructor,
      location,
      virtualMeeting,
      prerequisites,
      learningObjectives,
      assessment,
      enrollment,
      cost,
      tags
    } = req.body;
    
    // Validate required fields
    if (!title || !category || !type || !format || !schedule) {
      return res.status(400).json({
        success: false,
        error: 'Title, category, type, format, and schedule are required'
      });
    }
    
    const trainingData = {
      companyId: req.companyId,
      title,
      description,
      category,
      type,
      format,
      duration: duration ? JSON.parse(duration) : { hours: 0, minutes: 0 },
      schedule: {
        startDate: new Date(schedule.startDate),
        endDate: new Date(schedule.endDate),
        sessions: schedule.sessions ? JSON.parse(schedule.sessions) : []
      },
      instructor: instructor ? JSON.parse(instructor) : {},
      location,
      virtualMeeting: virtualMeeting ? JSON.parse(virtualMeeting) : {},
      prerequisites: prerequisites ? prerequisites.split(',').map(p => p.trim()) : [],
      learningObjectives: learningObjectives ? learningObjectives.split(',').map(o => o.trim()) : [],
      assessment: assessment ? JSON.parse(assessment) : { required: false },
      enrollment: enrollment ? JSON.parse(enrollment) : { maxParticipants: 50, currentParticipants: 0 },
      cost: cost ? JSON.parse(cost) : { perParticipant: 0, currency: 'NPR' },
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      createdBy: req.user.id
    };
    
    // Handle file uploads
    if (req.files && req.files.length > 0) {
      trainingData.materials = req.files.map(file => ({
        title: file.originalname,
        type: path.extname(file.originalname).toLowerCase() === '.pdf' ? 'document' : 'file',
        filename: file.filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        url: `/uploads/training/${file.filename}`
      }));
    }
    
    const training = new Training(trainingData);
    await training.save();
    
    // Populate location info for response
    if (training.location) {
      await training.populate('location', 'name');
    }
    
    res.status(201).json({
      success: true,
      training,
      message: 'Training created successfully'
    });
  } catch (error) {
    console.error('Error creating training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create training',
      message: error.message
    });
  }
});

// Update a training
router.put('/:trainingId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), upload.array('materials', 10), async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow updates if training is draft
    if (training.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update training that is not in draft status'
      });
    }
    
    const updateData = req.body;
    
    // Handle file uploads
    if (req.files && req.files.length > 0) {
      const newMaterials = req.files.map(file => ({
        title: file.originalname,
        type: path.extname(file.originalname).toLowerCase() === '.pdf' ? 'document' : 'file',
        filename: file.filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        url: `/uploads/training/${file.filename}`
      }));
      
      updateData.materials = [...(training.materials || []), ...newMaterials];
    }
    
    // Update the training
    Object.assign(training, updateData);
    await training.save();
    
    res.json({
      success: true,
      training,
      message: 'Training updated successfully'
    });
  } catch (error) {
    console.error('Error updating training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update training',
      message: error.message
    });
  }
});

// Publish a training
router.post('/:trainingId/publish', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (training.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Training is not in draft status'
      });
    }
    
    await training.publish();
    
    res.json({
      success: true,
      training,
      message: 'Training published successfully'
    });
  } catch (error) {
    console.error('Error publishing training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to publish training',
      message: error.message
    });
  }
});

// Start a training
router.post('/:trainingId/start', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (training.status !== 'published') {
      return res.status(400).json({
        success: false,
        error: 'Training must be published before starting'
      });
    }
    
    await training.start();
    
    res.json({
      success: true,
      training,
      message: 'Training started successfully'
    });
  } catch (error) {
    console.error('Error starting training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to start training',
      message: error.message
    });
  }
});

// Complete a training
router.post('/:trainingId/complete', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (training.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        error: 'Training is not in progress'
      });
    }
    
    await training.complete();
    
    res.json({
      success: true,
      training,
      message: 'Training completed successfully'
    });
  } catch (error) {
    console.error('Error completing training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to complete training',
      message: error.message
    });
  }
});

// Enroll employee in training
router.post('/:trainingId/enroll', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { employeeId } = req.body;
    
    if (!employeeId) {
      return res.status(400).json({
        success: false,
        error: 'Employee ID is required'
      });
    }
    
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    if (training.status !== 'published' && training.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        error: 'Training is not available for enrollment'
      });
    }
    
    await training.enrollEmployee(employeeId);
    
    res.json({
      success: true,
      message: 'Employee enrolled successfully'
    });
  } catch (error) {
    console.error('Error enrolling employee:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to enroll employee',
      message: error.message
    });
  }
});

// Complete training for employee
router.post('/:trainingId/complete-employee', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { employeeId, score } = req.body;
    
    if (!employeeId) {
      return res.status(400).json({
        success: false,
        error: 'Employee ID is required'
      });
    }
    
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    await training.completeForEmployee(employeeId, score);
    
    res.json({
      success: true,
      message: 'Training completed for employee successfully'
    });
  } catch (error) {
    console.error('Error completing training for employee:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to complete training for employee',
      message: error.message
    });
  }
});

// Delete a training
router.delete('/:trainingId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, authorizeRoles('admin'), async (req, res) => {
  try {
    const training = await Training.findById(req.params.trainingId);
    
    if (!training) {
      return res.status(404).json({
        success: false,
        error: 'Training not found'
      });
    }
    
    // Verify the training belongs to the company
    if (training.companyId.toString() !== req.companyId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Only allow deletion if training is draft
    if (training.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Cannot delete training that is not in draft status'
      });
    }
    
    await Training.findByIdAndDelete(req.params.trainingId);
    
    res.json({
      success: true,
      message: 'Training deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting training:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete training',
      message: error.message
    });
  }
});

module.exports = router; 