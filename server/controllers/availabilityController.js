const Availability = require('../models/Availability');
const TutorProfile = require('../models/TutorProfile');
const Booking = require('../models/Booking');

// Get tutor's availability
exports.getAvailability = async (req, res) => {
  try {
    console.log('Get availability request - User:', req.user);
    
    let tutorId;
    
    if (req.user.role === 'tutor') {
      // For tutors accessing their own availability
      if (!req.user.tutorProfileId) {
        // Try to find the tutor profile
        const tutorProfile = await TutorProfile.findOne({ userId: req.user.userId });
        if (!tutorProfile) {
          return res.status(404).json({ message: 'Tutor profile not found. Please complete your profile first.' });
        }
        tutorId = tutorProfile._id;
      } else {
        tutorId = req.user.tutorProfileId;
      }
    } else {
      // For students/admins accessing a specific tutor's availability
      tutorId = req.params.tutorId;
    }

    if (!tutorId) {
      return res.status(400).json({ message: 'Tutor ID is required' });
    }

    console.log('Looking for availability for tutorId:', tutorId);

    let availability = await Availability.findOne({ tutorId });

    if (!availability) {
      console.log('No availability found, creating default...');
      // Create default availability (9 AM to 5 PM, Monday to Friday)
      const defaultSchedule = [];
      for (let day = 1; day <= 5; day++) { // Monday to Friday
        defaultSchedule.push({
          dayOfWeek: day,
          isAvailable: true,
          timeSlots: [
            { startTime: '09:00', endTime: '12:00', isAvailable: true },
            { startTime: '13:00', endTime: '17:00', isAvailable: true },
          ],
        });
      }
      
      // Weekend - unavailable by default
      for (let day = 0; day <= 6; day += 6) { // Sunday and Saturday
        defaultSchedule.push({
          dayOfWeek: day,
          isAvailable: false,
          timeSlots: [],
        });
      }

      availability = new Availability({
        tutorId,
        weeklySchedule: defaultSchedule,
        blockedDates: [],
      });

      await availability.save();
      console.log('Default availability created');
    }

    res.json(availability);
  } catch (error) {
    console.error('Get availability error:', error);
    res.status(500).json({ message: error.message });
  }
};

// Update tutor's availability
exports.updateAvailability = async (req, res) => {
  try {
    const tutorId = req.user.tutorProfileId;
    const { weeklySchedule, blockedDates, timezone } = req.body;

    if (!tutorId) {
      return res.status(400).json({ message: 'Tutor profile not found' });
    }

    let availability = await Availability.findOne({ tutorId });

    if (!availability) {
      availability = new Availability({ tutorId });
    }

    if (weeklySchedule) availability.weeklySchedule = weeklySchedule;
    if (blockedDates) availability.blockedDates = blockedDates;
    if (timezone) availability.timezone = timezone;

    await availability.save();

    res.json({
      message: 'Availability updated successfully',
      availability,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get available time slots for a specific date
exports.getAvailableSlots = async (req, res) => {
  try {
    const { tutorId, date } = req.params;
    const requestedDate = new Date(date);
    const dayOfWeek = requestedDate.getDay();

    // Release expired locks first
    await Booking.releaseExpiredLocks();

    const availability = await Availability.findOne({ tutorId });

    if (!availability) {
      return res.status(404).json({ message: 'Availability not found' });
    }

    // Check if date is blocked
    const isBlocked = availability.blockedDates.some(blocked => {
      const blockedDate = new Date(blocked.date);
      return blockedDate.toDateString() === requestedDate.toDateString();
    });

    if (isBlocked) {
      return res.json({ availableSlots: [], message: 'Date is blocked' });
    }

    // Find the day's schedule
    const daySchedule = availability.weeklySchedule.find(
      schedule => schedule.dayOfWeek === dayOfWeek
    );

    if (!daySchedule || !daySchedule.isAvailable) {
      return res.json({ availableSlots: [], message: 'Tutor not available on this day' });
    }

    // Get existing bookings for this date
    const existingBookings = await Booking.find({
      tutorId,
      sessionDate: {
        $gte: new Date(requestedDate.setHours(0, 0, 0, 0)),
        $lt: new Date(requestedDate.setHours(23, 59, 59, 999))
      },
      status: { $in: ['pending', 'confirmed'] }
    });

    // Filter available slots and check against bookings
    const availableSlots = daySchedule.timeSlots.filter(slot => {
      if (!slot.isAvailable) return false;

      // Check if slot conflicts with any booking
      const hasConflict = existingBookings.some(booking => {
        return (
          (slot.startTime < booking.endTime && slot.endTime > booking.startTime) ||
          (booking.startTime < slot.endTime && booking.endTime > slot.startTime)
        );
      });

      return !hasConflict;
    }).map(slot => ({
      ...slot.toObject(),
      isBooked: false, // Real-time check shows it's available
    }));

    res.json({
      date: requestedDate,
      dayOfWeek,
      availableSlots,
      timezone: availability.timezone,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Block/unblock specific time slots
exports.toggleTimeSlot = async (req, res) => {
  try {
    const tutorId = req.user.tutorProfileId;
    const { dayOfWeek, startTime, endTime, isAvailable } = req.body;

    const availability = await Availability.findOne({ tutorId });

    if (!availability) {
      return res.status(404).json({ message: 'Availability not found' });
    }

    const daySchedule = availability.weeklySchedule.find(
      schedule => schedule.dayOfWeek === dayOfWeek
    );

    if (!daySchedule) {
      return res.status(404).json({ message: 'Day schedule not found' });
    }

    const timeSlot = daySchedule.timeSlots.find(
      slot => slot.startTime === startTime && slot.endTime === endTime
    );

    if (!timeSlot) {
      return res.status(404).json({ message: 'Time slot not found' });
    }

    timeSlot.isAvailable = isAvailable;

    await availability.save();

    res.json({
      message: `Time slot ${isAvailable ? 'enabled' : 'disabled'} successfully`,
      availability,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Add blocked date
exports.addBlockedDate = async (req, res) => {
  try {
    const tutorId = req.user.tutorProfileId;
    const { date, reason } = req.body;

    const availability = await Availability.findOne({ tutorId });

    if (!availability) {
      return res.status(404).json({ message: 'Availability not found' });
    }

    // Check if date is already blocked
    const existingBlock = availability.blockedDates.find(blocked => {
      const blockedDate = new Date(blocked.date);
      const newDate = new Date(date);
      return blockedDate.toDateString() === newDate.toDateString();
    });

    if (existingBlock) {
      return res.status(400).json({ message: 'Date is already blocked' });
    }

    availability.blockedDates.push({ date, reason: reason || 'Unavailable' });
    await availability.save();

    res.json({
      message: 'Date blocked successfully',
      availability,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Remove blocked date
exports.removeBlockedDate = async (req, res) => {
  try {
    const tutorId = req.user.tutorProfileId;
    const { date } = req.params;

    const availability = await Availability.findOne({ tutorId });

    if (!availability) {
      return res.status(404).json({ message: 'Availability not found' });
    }

    availability.blockedDates = availability.blockedDates.filter(blocked => {
      const blockedDate = new Date(blocked.date);
      const removeDate = new Date(date);
      return blockedDate.toDateString() !== removeDate.toDateString();
    });

    await availability.save();

    res.json({
      message: 'Blocked date removed successfully',
      availability,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Lock a time slot temporarily (for booking process)
exports.lockTimeSlot = async (req, res) => {
  try {
    const { tutorId, date, startTime, endTime } = req.body;
    const userId = req.user.userId;
    const sessionDate = new Date(date);

    // Release expired locks first
    await Booking.releaseExpiredLocks();

    // Check if slot is available
    const isAvailable = await Booking.isSlotAvailable(tutorId, sessionDate, startTime, endTime);
    
    if (!isAvailable) {
      return res.status(400).json({ message: 'Time slot is not available' });
    }

    // Lock the slot
    const lock = await Booking.lockSlot(tutorId, sessionDate, startTime, endTime, userId, 10); // 10 minutes lock

    res.json({
      message: 'Time slot locked successfully',
      lockId: lock._id,
      expiresAt: lock.lockExpiresAt,
    });
  } catch (error) {
    if (error.message === 'Slot is currently locked by another user') {
      return res.status(409).json({ message: error.message });
    }
    res.status(500).json({ message: error.message });
  }
};

// Release a locked time slot
exports.releaseTimeSlot = async (req, res) => {
  try {
    const { lockId } = req.params;
    const userId = req.user.userId;

    const booking = await Booking.findOne({
      _id: lockId,
      lockedBy: userId,
      isSlotLocked: true,
      status: 'pending'
    });

    if (!booking) {
      return res.status(404).json({ message: 'Lock not found or expired' });
    }

    await Booking.deleteOne({ _id: lockId });

    res.json({ message: 'Time slot released successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Check if a specific slot is available (real-time check)
exports.checkSlotAvailability = async (req, res) => {
  try {
    const { tutorId, date, startTime, endTime } = req.query;
    const sessionDate = new Date(date);

    // Release expired locks first
    await Booking.releaseExpiredLocks();

    const isAvailable = await Booking.isSlotAvailable(tutorId, sessionDate, startTime, endTime);

    res.json({
      isAvailable,
      tutorId,
      date: sessionDate,
      startTime,
      endTime,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};