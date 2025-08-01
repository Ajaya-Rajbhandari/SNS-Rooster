const express = require('express');
const router = express.Router();
const performanceReviewController = require('../controllers/performance-review-controller');
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess, requireFeature } = require('../middleware/companyContext');

// Apply middleware to all routes
router.use(authenticateToken);
router.use(validateCompanyContext);
router.use(validateUserCompanyAccess);
router.use(requireFeature('performanceReviews'));

// Performance Review routes

// GET /api/performance-reviews - Get all performance reviews for the company
router.get('/', performanceReviewController.getPerformanceReviews);

// GET /api/performance-reviews/statistics - Get performance review statistics
router.get('/statistics', performanceReviewController.getStatistics);

// GET /api/performance-reviews/eligible-employees - Get employees eligible for review
router.get('/eligible-employees', performanceReviewController.getEligibleEmployees);

// GET /api/performance-reviews/:id - Get a specific performance review
router.get('/:id', performanceReviewController.getPerformanceReview);

// POST /api/performance-reviews - Create a new performance review
router.post('/', performanceReviewController.createPerformanceReview);

// PUT /api/performance-reviews/:id - Update a performance review
router.put('/:id', performanceReviewController.updatePerformanceReview);

// POST /api/performance-reviews/:id/submit - Submit a performance review
router.post('/:id/submit', performanceReviewController.submitPerformanceReview);

// POST /api/performance-reviews/:id/complete - Complete a performance review
router.post('/:id/complete', performanceReviewController.completePerformanceReview);

// DELETE /api/performance-reviews/:id - Delete a performance review
router.delete('/:id', performanceReviewController.deletePerformanceReview);

module.exports = router; 