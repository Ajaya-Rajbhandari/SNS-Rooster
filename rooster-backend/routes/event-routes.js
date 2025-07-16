const express = require('express');
const router = express.Router();
const eventController = require('../controllers/event-controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');

// Event routes
router.post('/', authenticateToken, eventController.createEvent);
router.get('/', authenticateToken, eventController.getEvents);
router.get('/upcoming', authenticateToken, eventController.getUpcomingEvents);
router.get('/activities', authenticateToken, eventController.getRecentActivities);
router.get('/:id', authenticateToken, eventController.getEventById);
router.put('/:id', authenticateToken, eventController.updateEvent);
router.delete('/:id', authenticateToken, eventController.deleteEvent);
router.post('/:id/invite', authenticateToken, eventController.inviteUsersToEvent);
router.post('/:id/respond', authenticateToken, eventController.respondToEvent);
router.post('/:id/attendees', authenticateToken, eventController.joinEvent);
router.delete('/:id/attendees/:userId', authenticateToken, eventController.leaveEvent);

module.exports = router; 