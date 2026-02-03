const AvailabilitySlot = require('../models/AvailabilitySlot');
const User = require('../models/User');
const Booking = require('../models/Booking');

// Get tutor's weekly schedule
exports.getWeeklySchedule = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { weekStart } = req.query;

    if (!weekStart) {
      return res.status(400).json({
        success: false,
        message: 'Week start date is required'
      });
    }

    const startDate = new Date(weekStart);
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 6);

    const slots = await AvailabilitySlot.getWeeklySchedule(tutorId, startDate);

    // Group slots by day of week
    const schedule = {
      Monday: [],
      Tuesday: [],
      Wednesday: [],
      Thursday: [],
      Friday: [],
      Saturday: [],
      Sunday: []
    };

    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    slots.forEach(slot => {
      const dayName = dayNames[slot.date.getDay()];
      schedule[dayName].push({
        id: slot._id,
        tutorId: slot.tutorId,
        date: slot.date,
        timeSlot: slot.timeSlot,
        isAvailable: slot.isAvailable,
        isRecurring: slot.isRecurring,
        recurringPattern: slot.recurringPattern,
        booking: slot.booking ? {
          id: slot.booking.bookingId,
          studentId: slot.booking.studentId,
          studentName: slot.booking.studentName,
          studentEmail: slot.booking.studentEmail,
          studentPhone: slot.booking.studentPhone,
          subject: slot.booking.subject,
          status: slot.booking.status,
          amount: slot.booking.amount,
          notes: slot.booking.notes,
          meetingLink: slot.booking.meetingLink,
          bookedAt: slot.booking.bookedAt
        } : null,
        createdAt: slot.createdAt,
        updatedAt: slot.updatedAt
      });
    });

    res.json({
      success: true,
      data: {
        schedule,
        weekStart: startDate,
        weekEnd: endDate
      }
    });

  } catch (error) {
    console.error('Get weekly schedule error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch weekly schedule',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get availability slots for date range
exports.getAvailabilitySlots = async (req, res) => {
  try {
    const { startDate, endDate, tutorId: queryTutorId } = req.query;
    const userRole = req.user.role;
    const userId = req.user.userId;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date are required'
      });
    }

    // Determine which tutor's slots to fetch
    let tutorId;
    if (userRole === 'tutor') {
      // Tutors can only see their own slots
      tutorId = userId;
    } else if (userRole === 'student') {
      // Students must specify which tutor's slots they want to see
      if (!queryTutorId) {
        return res.status(400).json({
          success: false,
          message: 'Tutor ID is required for students'
        });
      }
      tutorId = queryTutorId;
    } else {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    console.log(`🔍 Querying slots for tutorId: ${tutorId}, role: ${userRole}`);
    console.log(`📅 Date range: ${startDate} to ${endDate}`);
    
    // Normalize dates to start of day for proper comparison
    const queryStartDate = new Date(startDate);
    queryStartDate.setHours(0, 0, 0, 0);
    
    const queryEndDate = new Date(endDate);
    queryEndDate.setHours(23, 59, 59, 999);
    
    console.log(`📅 Normalized start: ${queryStartDate}`);
    console.log(`📅 Normalized end: ${queryEndDate}`);
    
    const slots = await AvailabilitySlot.find({
      tutorId,
      date: { $gte: queryStartDate, $lte: queryEndDate },
      isActive: true
    }).populate('booking.studentId', 'firstName lastName email phone')
      .sort({ date: 1, 'timeSlot.startTime': 1 });
    
    console.log(`✅ Found ${slots.length} slots for tutor ${tutorId}`);
    
    if (slots.length > 0) {
      console.log(`📊 First slot date: ${slots[0].date}`);
      console.log(`📊 Last slot date: ${slots[slots.length - 1].date}`);
    }

    const formattedSlots = slots.map(slot => ({
      id: slot._id,
      tutorId: slot.tutorId,
      date: slot.date,
      timeSlot: slot.timeSlot,
      isAvailable: slot.isAvailable,
      isRecurring: slot.isRecurring,
      recurringPattern: slot.recurringPattern,
      booking: slot.booking ? {
        id: slot.booking.bookingId,
        studentId: slot.booking.studentId,
        studentName: slot.booking.studentName,
        studentEmail: slot.booking.studentEmail,
        studentPhone: slot.booking.studentPhone,
        subject: slot.booking.subject,
        status: slot.booking.status,
        amount: slot.booking.amount,
        notes: slot.booking.notes,
        meetingLink: slot.booking.meetingLink,
        bookedAt: slot.booking.bookedAt
      } : null,
      createdAt: slot.createdAt,
      updatedAt: slot.updatedAt
    }));

    res.json({
      success: true,
      data: formattedSlots // Return slots directly, not wrapped in an object
    });

  } catch (error) {
    console.error('Get availability slots error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch availability slots',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Create availability slot
exports.createAvailabilitySlot = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { date, startTime, endTime, isRecurring, recurringPattern, recurringEndDate } = req.body;

    // Validate required fields
    if (!date || !startTime || !endTime) {
      return res.status(400).json({
        success: false,
        message: 'Date, start time, and end time are required'
      });
    }

    // Calculate duration
    const start = startTime.split(':');
    const end = endTime.split(':');
    const startMinutes = parseInt(start[0]) * 60 + parseInt(start[1]);
    const endMinutes = parseInt(end[0]) * 60 + parseInt(end[1]);
    const durationMinutes = endMinutes - startMinutes;

    console.log(`⏰ Time slot: ${startTime} - ${endTime}`);
    console.log(`📊 Duration calculated: ${durationMinutes} minutes`);

    if (durationMinutes <= 0) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time'
      });
    }

    if (durationMinutes < 15) {
      return res.status(400).json({
        success: false,
        message: `Time slot must be at least 15 minutes long. Current duration: ${durationMinutes} minutes. Please select a longer time slot.`
      });
    }

    // Check for conflicts
    const conflictingSlot = await AvailabilitySlot.findOne({
      tutorId,
      date: new Date(date),
      isActive: true,
      $or: [
        {
          'timeSlot.startTime': { $lt: endTime },
          'timeSlot.endTime': { $gt: startTime }
        }
      ]
    });

    if (conflictingSlot) {
      return res.status(400).json({
        success: false,
        message: 'Time slot conflicts with existing availability'
      });
    }

    const slotData = {
      tutorId,
      date: new Date(date),
      timeSlot: {
        startTime,
        endTime,
        durationMinutes
      },
      isAvailable: true,
      isRecurring: isRecurring || false,
      lastModifiedBy: tutorId
    };

    if (isRecurring) {
      slotData.recurringPattern = recurringPattern;
      if (recurringEndDate) {
        slotData.recurringEndDate = new Date(recurringEndDate);
      }
    }

    const slot = new AvailabilitySlot(slotData);
    await slot.save();

    res.status(201).json({
      success: true,
      message: 'Availability slot created successfully',
      data: {
        id: slot._id,
        tutorId: slot.tutorId,
        date: slot.date,
        timeSlot: slot.timeSlot,
        isAvailable: slot.isAvailable,
        isRecurring: slot.isRecurring,
        recurringPattern: slot.recurringPattern,
        createdAt: slot.createdAt,
        updatedAt: slot.updatedAt
      }
    });

  } catch (error) {
    console.error('Create availability slot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create availability slot',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Create bulk availability slots
exports.createBulkAvailability = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { dates, startTime, endTime, isRecurring, recurringPattern } = req.body;

    if (!dates || !Array.isArray(dates) || dates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Dates array is required'
      });
    }

    if (!startTime || !endTime) {
      return res.status(400).json({
        success: false,
        message: 'Start time and end time are required'
      });
    }

    // Calculate duration
    const start = startTime.split(':');
    const end = endTime.split(':');
    const startMinutes = parseInt(start[0]) * 60 + parseInt(start[1]);
    const endMinutes = parseInt(end[0]) * 60 + parseInt(end[1]);
    const durationMinutes = endMinutes - startMinutes;

    if (durationMinutes <= 0) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time'
      });
    }

    const slots = [];
    const errors = [];

    for (const dateStr of dates) {
      try {
        const date = new Date(dateStr);

        // Check for conflicts
        const conflictingSlot = await AvailabilitySlot.findOne({
          tutorId,
          date,
          isActive: true,
          $or: [
            {
              'timeSlot.startTime': { $lt: endTime },
              'timeSlot.endTime': { $gt: startTime }
            }
          ]
        });

        if (conflictingSlot) {
          errors.push(`Conflict on ${date.toDateString()}`);
          continue;
        }

        const slot = new AvailabilitySlot({
          tutorId,
          date,
          timeSlot: {
            startTime,
            endTime,
            durationMinutes
          },
          isAvailable: true,
          isRecurring: isRecurring || false,
          recurringPattern: isRecurring ? recurringPattern : undefined,
          lastModifiedBy: tutorId
        });

        await slot.save();
        slots.push({
          id: slot._id,
          tutorId: slot.tutorId,
          date: slot.date,
          timeSlot: slot.timeSlot,
          isAvailable: slot.isAvailable,
          isRecurring: slot.isRecurring,
          recurringPattern: slot.recurringPattern,
          createdAt: slot.createdAt,
          updatedAt: slot.updatedAt
        });

      } catch (error) {
        errors.push(`Error on ${dateStr}: ${error.message}`);
      }
    }

    res.status(201).json({
      success: true,
      message: `Created ${slots.length} availability slots`,
      data: {
        slots,
        errors: errors.length > 0 ? errors : undefined
      }
    });

  } catch (error) {
    console.error('Create bulk availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create bulk availability',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Update availability slot
exports.updateAvailabilitySlot = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { slotId } = req.params;
    const updates = req.body;

    const slot = await AvailabilitySlot.findOne({
      _id: slotId,
      tutorId,
      isActive: true
    });

    if (!slot) {
      return res.status(404).json({
        success: false,
        message: 'Availability slot not found'
      });
    }

    // Check if slot can be modified
    if (!slot.canBeModified()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot modify this slot (it may be booked or in the past)'
      });
    }

    // Update allowed fields
    const allowedUpdates = ['isAvailable', 'startTime', 'endTime', 'isRecurring', 'recurringPattern', 'notes'];
    const actualUpdates = {};

    Object.keys(updates).forEach(key => {
      if (allowedUpdates.includes(key)) {
        if (key === 'startTime' || key === 'endTime') {
          actualUpdates[`timeSlot.${key}`] = updates[key];
        } else {
          actualUpdates[key] = updates[key];
        }
      }
    });

    // Recalculate duration if time changed
    if (updates.startTime || updates.endTime) {
      const startTime = updates.startTime || slot.timeSlot.startTime;
      const endTime = updates.endTime || slot.timeSlot.endTime;
      
      const start = startTime.split(':');
      const end = endTime.split(':');
      const startMinutes = parseInt(start[0]) * 60 + parseInt(start[1]);
      const endMinutes = parseInt(end[0]) * 60 + parseInt(end[1]);
      const durationMinutes = endMinutes - startMinutes;

      if (durationMinutes <= 0) {
        return res.status(400).json({
          success: false,
          message: 'End time must be after start time'
        });
      }

      actualUpdates['timeSlot.durationMinutes'] = durationMinutes;
    }

    actualUpdates.lastModifiedBy = tutorId;
    actualUpdates.updatedAt = new Date();

    const updatedSlot = await AvailabilitySlot.findByIdAndUpdate(
      slotId,
      { $set: actualUpdates },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Availability slot updated successfully',
      data: {
        id: updatedSlot._id,
        tutorId: updatedSlot.tutorId,
        date: updatedSlot.date,
        timeSlot: updatedSlot.timeSlot,
        isAvailable: updatedSlot.isAvailable,
        isRecurring: updatedSlot.isRecurring,
        recurringPattern: updatedSlot.recurringPattern,
        createdAt: updatedSlot.createdAt,
        updatedAt: updatedSlot.updatedAt
      }
    });

  } catch (error) {
    console.error('Update availability slot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update availability slot',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Delete availability slot
exports.deleteAvailabilitySlot = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { slotId } = req.params;

    const slot = await AvailabilitySlot.findOne({
      _id: slotId,
      tutorId,
      isActive: true
    });

    if (!slot) {
      return res.status(404).json({
        success: false,
        message: 'Availability slot not found'
      });
    }

    // Check if slot can be deleted
    if (slot.isBooked && slot.booking.status === 'confirmed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete a confirmed booking'
      });
    }

    // Soft delete
    slot.isActive = false;
    slot.lastModifiedBy = tutorId;
    await slot.save();

    res.json({
      success: true,
      message: 'Availability slot deleted successfully'
    });

  } catch (error) {
    console.error('Delete availability slot error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete availability slot',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get upcoming sessions
exports.getUpcomingSessions = async (req, res) => {
  try {
    const tutorId = req.user.userId;

    const sessions = await AvailabilitySlot.findUpcomingSessions(tutorId);

    const formattedSessions = sessions.map(session => ({
      id: session._id,
      tutorId: session.tutorId,
      date: session.date,
      timeSlot: session.timeSlot,
      booking: {
        id: session.booking.bookingId,
        studentId: session.booking.studentId,
        studentName: session.booking.studentName,
        studentEmail: session.booking.studentEmail,
        studentPhone: session.booking.studentPhone,
        subject: session.booking.subject,
        status: session.booking.status,
        amount: session.booking.amount,
        notes: session.booking.notes,
        meetingLink: session.booking.meetingLink,
        bookedAt: session.booking.bookedAt
      },
      createdAt: session.createdAt,
      updatedAt: session.updatedAt
    }));

    res.json({
      success: true,
      data: {
        sessions: formattedSessions
      }
    });

  } catch (error) {
    console.error('Get upcoming sessions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch upcoming sessions',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Mark session as completed
exports.markSessionCompleted = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { slotId } = req.params;
    const { notes, rating } = req.body;

    const slot = await AvailabilitySlot.findOne({
      _id: slotId,
      tutorId,
      isActive: true,
      booking: { $exists: true }
    });

    if (!slot) {
      return res.status(404).json({
        success: false,
        message: 'Session not found'
      });
    }

    if (slot.booking.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Session is already marked as completed'
      });
    }

    // Update booking status
    slot.booking.status = 'completed';
    if (notes) slot.booking.notes = notes;
    slot.lastModifiedBy = tutorId;

    await slot.save();

    // Update the main Booking record if it exists
    if (slot.booking.bookingId) {
      await Booking.findByIdAndUpdate(slot.booking.bookingId, {
        status: 'completed',
        completedAt: new Date(),
        tutorNotes: notes,
        tutorRating: rating
      });
    }

    res.json({
      success: true,
      message: 'Session marked as completed successfully'
    });

  } catch (error) {
    console.error('Mark session completed error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark session as completed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Cancel session
exports.cancelSession = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { slotId } = req.params;
    const { reason } = req.body;

    const slot = await AvailabilitySlot.findOne({
      _id: slotId,
      tutorId,
      isActive: true,
      booking: { $exists: true }
    });

    if (!slot) {
      return res.status(404).json({
        success: false,
        message: 'Session not found'
      });
    }

    if (!slot.canBeCancelled()) {
      return res.status(400).json({
        success: false,
        message: 'Session cannot be cancelled'
      });
    }

    // Update booking status
    slot.booking.status = 'cancelled';
    slot.cancelledAt = new Date();
    slot.cancelledBy = tutorId;
    slot.cancellationReason = reason;
    slot.lastModifiedBy = tutorId;

    await slot.save();

    // Update the main Booking record if it exists
    if (slot.booking.bookingId) {
      await Booking.findByIdAndUpdate(slot.booking.bookingId, {
        status: 'cancelled',
        cancelledAt: new Date(),
        cancelledBy: tutorId,
        cancellationReason: reason
      });
    }

    // TODO: Send notification to student about cancellation
    // TODO: Handle refund if applicable

    res.json({
      success: true,
      message: 'Session cancelled successfully'
    });

  } catch (error) {
    console.error('Cancel session error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel session',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

module.exports = exports;