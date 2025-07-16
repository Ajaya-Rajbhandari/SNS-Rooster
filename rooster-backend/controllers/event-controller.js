const Event = require('../models/Event');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendNotificationToUser } = require('../services/notificationService');

// Create a new event
const createEvent = async (req, res) => {
  try {
    const {
      title,
      description,
      type,
      startDate,
      endDate,
      location,
      attendees,
      department,
      priority,
      isPublic,
      isRecurring,
      recurrencePattern,
      recurrenceEndDate,
      tags
    } = req.body;

    const event = new Event({
      title,
      description,
      type,
      startDate,
      endDate,
      location,
      organizer: req.user.userId,
      attendees: attendees || [],
      department,
      priority,
      isPublic: isPublic !== undefined ? isPublic : true, // Default to public
      isRecurring,
      recurrencePattern,
      recurrenceEndDate,
      tags,
      createdBy: req.user.userId
    });

    await event.save();

    // Send notifications to attendees and relevant users
    try {
      if (attendees && attendees.length > 0) {
        const notificationPromises = attendees.map(async (attendee) => {
          const user = await User.findById(attendee.user);
          if (user) {
            // Create database notification
            const notification = new Notification({
              user: attendee.user,
              title: 'New Event Invitation',
              message: `You have been invited to: ${title}`,
              type: 'action',
              link: `/events/${event._id}`,
            });
            await notification.save();

            // Send FCM notification if user has FCM token
            if (user.fcmToken) {
              try {
                await sendNotificationToUser(user.fcmToken, 'New Event Invitation', `You have been invited to: ${title}`, {
                  type: 'event',
                  eventId: event._id.toString()
                });
              } catch (fcmError) {
                console.error('FCM notification failed:', fcmError);
                // Continue with other notifications even if FCM fails
              }
            }
          }
        });

        await Promise.all(notificationPromises);
      }

      // If it's a public event, notify all employees
      if (isPublic) {
        const allEmployees = await User.find({ role: 'employee' });
        const publicNotificationPromises = allEmployees.map(async (employee) => {
          // Skip if user is already an attendee
          const isAttendee = attendees && attendees.some(attendee => attendee.user.toString() === employee._id.toString());
          if (!isAttendee) {
            const notification = new Notification({
              user: employee._id,
              title: 'New Public Event',
              message: `A new public event has been created: ${title}`,
              type: 'info',
              link: `/events/${event._id}`,
            });
            await notification.save();

            // Send FCM notification if user has FCM token
            if (employee.fcmToken) {
              try {
                await sendNotificationToUser(employee.fcmToken, 'New Public Event', `A new public event has been created: ${title}`, {
                  type: 'event',
                  eventId: event._id.toString()
                });
              } catch (fcmError) {
                console.error('FCM notification failed:', fcmError);
              }
            }
          }
        });

        await Promise.all(publicNotificationPromises);
      }
    } catch (notificationError) {
      console.error('Error sending event notifications:', notificationError);
      // Don't fail the event creation if notifications fail
    }

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      event
    });
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create event',
      error: error.message
    });
  }
};

// Get all events (with filters)
const getEvents = async (req, res) => {
  try {
    const {
      type,
      department,
      status,
      startDate,
      endDate,
      limit = 20,
      page = 1
    } = req.query;

    const filter = {};

    // Show events that are:
    // 1. Public events (visible to all)
    // 2. Events where user is an attendee
    // 3. Events created by the user
    filter.$or = [
      { isPublic: true },
      { 'attendees.user': req.user.userId },
      { createdBy: req.user.userId }
    ];

    if (type) filter.type = type;
    if (department) filter.department = department;
    if (status) filter.status = status;
    if (startDate && endDate) {
      filter.startDate = { $gte: new Date(startDate), $lte: new Date(endDate) };
    }

    const events = await Event.find(filter)
      .populate('organizer', 'firstName lastName email')
      .populate('attendees.user', 'firstName lastName email')
      .sort({ startDate: 1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit));

    const total = await Event.countDocuments(filter);

    res.json({
      success: true,
      events,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch events',
      error: error.message
    });
  }
};

// Get upcoming events for dashboard
const getUpcomingEvents = async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    const now = new Date();

    const events = await Event.find({
      startDate: { $gte: now },
      status: 'published',
      $or: [
        { isPublic: true },
        { 'attendees.user': req.user.userId },
        { createdBy: req.user.userId }
      ]
    })
      .populate('organizer', 'firstName lastName email')
      .sort({ startDate: 1 })
      .limit(parseInt(limit));

    res.json({
      success: true,
      events
    });
  } catch (error) {
    console.error('Error fetching upcoming events:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch upcoming events',
      error: error.message
    });
  }
};

// Get recent activities for dashboard (simplified)
const getRecentActivities = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    // For now, return empty array until Activity model is properly set up
    res.json({
      success: true,
      activities: []
    });
  } catch (error) {
    console.error('Error fetching recent activities:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch recent activities',
      error: error.message
    });
  }
};

// Get event by ID
const getEventById = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('organizer', 'firstName lastName email')
      .populate('attendees.user', 'firstName lastName email')
      .populate('createdBy', 'firstName lastName email');

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    res.json({
      success: true,
      event
    });
  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch event',
      error: error.message
    });
  }
};

// Update event
const updateEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user is organizer or admin
    if (event.organizer.toString() !== req.user.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this event'
      });
    }

    const updatedEvent = await Event.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('organizer', 'firstName lastName email')
     .populate('attendees.user', 'firstName lastName email');

    res.json({
      success: true,
      message: 'Event updated successfully',
      event: updatedEvent
    });
  } catch (error) {
    console.error('Error updating event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update event',
      error: error.message
    });
  }
};

// Delete event
const deleteEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user is organizer or admin
    if (event.organizer.toString() !== req.user.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this event'
      });
    }

    await Event.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Event deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete event',
      error: error.message
    });
  }
};

// Invite users to an event
const inviteUsersToEvent = async (req, res) => {
  try {
    const { userIds } = req.body; // Array of user IDs to invite
    const eventId = req.params.id;

    const event = await Event.findById(eventId);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user is organizer or admin
    if (event.organizer.toString() !== req.user.userId.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to invite users to this event'
      });
    }

    // Add new attendees
    const newAttendees = userIds.map(userId => ({
      user: userId,
      status: 'invited'
    }));

    event.attendees.push(...newAttendees);
    await event.save();

    res.json({
      success: true,
      message: 'Users invited successfully',
      event
    });
  } catch (error) {
    console.error('Error inviting users to event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to invite users to event',
      error: error.message
    });
  }
};

// Join an event
const joinEvent = async (req, res) => {
  try {
    const eventId = req.params.id;
    const userId = req.user.userId;

    const event = await Event.findById(eventId);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user is already an attendee
    const existingAttendee = event.attendees.find(
      attendee => attendee.user.toString() === userId.toString()
    );

    if (existingAttendee) {
      return res.status(400).json({
        success: false,
        message: 'You are already attending this event'
      });
    }

    // Add user as attendee
    event.attendees.push({
      user: userId,
      status: 'accepted',
      responseDate: new Date()
    });

    await event.save();

    // Notify event organizer
    try {
      const organizer = await User.findById(event.organizer);
      if (organizer) {
        const user = await User.findById(userId);
        const notification = new Notification({
          user: event.organizer,
          title: 'Event Attendance Update',
          message: `${user.firstName} ${user.lastName} has joined your event: ${event.title}`,
          type: 'info',
          link: `/events/${event._id}`,
        });
        await notification.save();

        if (organizer.fcmToken) {
          await sendNotificationToUser(organizer.fcmToken, 'Event Attendance Update', `${user.firstName} ${user.lastName} has joined your event: ${event.title}`, {
            type: 'event',
            eventId: event._id.toString()
          });
        }
      }
    } catch (notificationError) {
      console.error('Error sending join notification:', notificationError);
    }

    res.json({
      success: true,
      message: 'Successfully joined event',
      event
    });
  } catch (error) {
    console.error('Error joining event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to join event',
      error: error.message
    });
  }
};

// Leave an event
const leaveEvent = async (req, res) => {
  try {
    const eventId = req.params.id;
    const userId = req.user.userId;

    const event = await Event.findById(eventId);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Find and remove attendee
    const attendeeIndex = event.attendees.findIndex(
      attendee => attendee.user.toString() === userId.toString()
    );

    if (attendeeIndex === -1) {
      return res.status(400).json({
        success: false,
        message: 'You are not attending this event'
      });
    }

    event.attendees.splice(attendeeIndex, 1);
    await event.save();

    // Notify event organizer
    try {
      const organizer = await User.findById(event.organizer);
      if (organizer) {
        const user = await User.findById(userId);
        const notification = new Notification({
          user: event.organizer,
          title: 'Event Attendance Update',
          message: `${user.firstName} ${user.lastName} has left your event: ${event.title}`,
          type: 'info',
          link: `/events/${event._id}`,
        });
        await notification.save();

        if (organizer.fcmToken) {
          await sendNotificationToUser(organizer.fcmToken, 'Event Attendance Update', `${user.firstName} ${user.lastName} has left your event: ${event.title}`, {
            type: 'event',
            eventId: event._id.toString()
          });
        }
      }
    } catch (notificationError) {
      console.error('Error sending leave notification:', notificationError);
    }

    res.json({
      success: true,
      message: 'Successfully left event',
      event
    });
  } catch (error) {
    console.error('Error leaving event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to leave event',
      error: error.message
    });
  }
};

// Respond to event invitation
const respondToEvent = async (req, res) => {
  try {
    const { status } = req.body; // 'accepted', 'declined', 'pending'
    const eventId = req.params.id;
    const userId = req.user.userId;

    const event = await Event.findById(eventId);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Find and update attendee status
    const attendeeIndex = event.attendees.findIndex(
      attendee => attendee.user.toString() === userId.toString()
    );

    if (attendeeIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'You are not invited to this event'
      });
    }

    event.attendees[attendeeIndex].status = status;
    event.attendees[attendeeIndex].responseDate = new Date();
    await event.save();

    res.json({
      success: true,
      message: `Event ${status} successfully`,
      event
    });
  } catch (error) {
    console.error('Error responding to event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to respond to event',
      error: error.message
    });
  }
};



module.exports = {
  createEvent,
  getEvents,
  getUpcomingEvents,
  getRecentActivities,
  getEventById,
  updateEvent,
  deleteEvent,
  inviteUsersToEvent,
  respondToEvent,
  joinEvent,
  leaveEvent
}; 