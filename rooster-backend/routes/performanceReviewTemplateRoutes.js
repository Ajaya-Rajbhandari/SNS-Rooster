const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  validateCompanyContext,
  validateUserCompanyAccess,
  requireFeature
} = require('../middleware/companyContext');

const {
  getTemplates,
  getTemplate,
  createTemplate,
  updateTemplate,
  deleteTemplate,
  duplicateTemplate
} = require('../controllers/performance-review-template-controller');

// Apply middleware to all routes
router.use(authenticateToken);
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);
router.use(requireFeature('performanceReviews'));

// Template routes
router.get('/', getTemplates);
router.get('/:id', getTemplate);
router.post('/', createTemplate);
router.put('/:id', updateTemplate);
router.delete('/:id', deleteTemplate);
router.post('/:id/duplicate', duplicateTemplate);

module.exports = router; 