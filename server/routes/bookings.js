const express = require('express');
const mongoose = require('mongoose');
const { authenticate, authorize } = require('../middleware/auth');
const bookingController = require('../controllers/bookingController');

const router = express.Router();

// New booking system routes
router.post('/request', authenticate, authorize('student'), bookingController.createBookingRequest);
router.get('/requests', authenticate, authorize('tutor'), bookingController.getTutorBookingRequests);
router.post('/requests/:requestId/respond', authenticate, authorize('tutor'), bookingController.respondToBookingRequest);

// General booking routes
router.get('/student', authenticate, authorize('student'), bookingController.getStudentBookings);
router.get('/tutor', authenticate, authorize('tutor'), bookingController.getTutorBookingRequests);
router.get('/:bookingId', authenticate, bookingController.getBookingDetails);
router.post('/:bookingId/cancel', authenticate, bookingController.cancelBooking);
router.put('/:bookingId/cancel', authenticate, bookingController.cancelBooking); // Support PUT method
router.post('/:bookingId/respond', authenticate, bookingController.respondToBookingRequest); // Add respond route
router.put('/:bookingId/respond', authenticate, bookingController.respondToBookingRequest); // Support PUT method

// Rating endpoint
router.post('/:bookingId/rate', authenticate, bookingController.rateBooking);

// Reschedule endpoints
router.post('/:bookingId/reschedule/request', authenticate, bookingController.requestReschedule);
router.post('/:bookingId/reschedule/:requestId/respond', authenticate, bookingController.respondToRescheduleRequest);
router.get('/:bookingId/reschedule/requests', authenticate, bookingController.getRescheduleRequests);

// Legacy routes (keeping for backward compatibility)
// Get user's bookings
router.get('/', authenticate, async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const { status, page = 1, limit = 10 } = req.query;

    const filter = {
      $or: [
        { studentId: req.user.userId },
        { tutorId: req.user.userId }
      ]
    };

    if (status) {
      filter.status = status;
    }

    const bookings = await Booking.find(filter)
      .populate('studentId', 'firstName lastName profilePicture')
      .populate('tutorId', 'firstName lastName profilePicture')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await Booking.countDocuments(filter);

    // Format bookings for mobile app
    const Review = require('../models/Review');
    
    const formattedBookings = await Promise.all(bookings.map(async (booking) => {
      // Check if review exists for this booking
      let hasReview = false;
      if (booking.status === 'completed') {
        const review = await Review.findOne({ bookingId: booking._id });
        hasReview = !!review;
      }
      
      return {
        id: booking._id.toString(),
        _id: booking._id.toString(),
        studentId: booking.studentId?._id?.toString(),
        studentName: booking.studentId ? `${booking.studentId.firstName} ${booking.studentId.lastName}` : 'Unknown',
        studentProfilePicture: booking.studentId?.profilePicture,
        tutorId: booking.tutorId?._id?.toString(),
        tutorName: booking.tutorId ? `${booking.tutorId.firstName} ${booking.tutorId.lastName}` : 'Unknown',
        tutorProfilePicture: booking.tutorId?.profilePicture,
        subject: booking.subject?.name || 'Unknown',
        sessionDate: booking.sessionDate?.toISOString(),
        date: booking.sessionDate?.toISOString().split('T')[0],
        time: `${booking.startTime} - ${booking.endTime}`,
        startTime: booking.startTime,
        endTime: booking.endTime,
        duration: booking.duration,
        mode: booking.sessionType === 'online' ? 'Online' : 'In-Person',
        sessionType: booking.sessionType,
        location: booking.location,
        price: booking.pricePerHour,
        pricePerHour: booking.pricePerHour,
        totalAmount: booking.totalAmount,
        earnings: booking.totalAmount,
        status: booking.status,
        paymentStatus: booking.paymentStatus,
        studentMessage: booking.notes?.student,
        tutorMessage: booking.notes?.tutor,
        requestedAt: booking.createdAt?.toISOString(),
        meetingLink: booking.meetingLink,
        rating: booking.rating,
        review: booking.review,
        hasReview: hasReview,
        cancelledBy: booking.cancelledBy,
        cancelledAt: booking.cancelledAt?.toISOString(),
        reason: booking.cancellationReason,
      };
    }));

    res.json({
      success: true,
      data: {
        bookings: formattedBookings,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get bookings'
    });
  }
});

// Create new booking
router.post('/', authenticate, async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const TutorProfile = require('../models/TutorProfile');
    const Subject = require('../models/Subject');

    let { tutorId, subjectId, date, startTime, endTime, mode, location, message } = req.body;

    // Validate required fields
    if (!tutorId || !subjectId || !date || !startTime || !endTime) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: tutorId, subjectId, date, startTime, endTime'
      });
    }

    // Check if tutorId is a profile ID or user ID
    // Try to find tutor profile first
    let tutorProfile = await TutorProfile.findById(tutorId);
    let tutorProfileId = tutorId; // Store the original tutorId (profile ID)

    if (tutorProfile) {
      // It's a profile ID - perfect, use it as is
      tutorProfileId = tutorProfile._id.toString();
    } else {
      // It might be a user ID, try to find profile by userId
      tutorProfile = await TutorProfile.findOne({ userId: tutorId });
      if (!tutorProfile) {
        return res.status(404).json({
          success: false,
          message: 'Tutor profile not found'
        });
      }
      tutorProfileId = tutorProfile._id.toString();
    }

    // Check if tutor is accepting bookings
    if (!tutorProfile.isAvailable) {
      return res.status(400).json({
        success: false,
        message: 'This tutor is not accepting new bookings at the moment. Please try again later.'
      });
    }

    // Get subject info
    let subject;

    // Try to find by ObjectId first
    if (mongoose.Types.ObjectId.isValid(subjectId)) {
      subject = await Subject.findById(subjectId);
    }

    // If not found by ID, try to find by name (backward compatibility)
    if (!subject) {
      subject = await Subject.findOne({ name: { $regex: new RegExp(`^${subjectId}$`, 'i') } });
      if (subject) {
        subjectId = subject._id.toString();
      }
    }

    if (!subject) {
      return res.status(404).json({
        success: false,
        message: `Subject not found: ${subjectId}`
      });
    }

    // Calculate duration in minutes
    const [startHour, startMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);
    const duration = (endHour * 60 + endMin) - (startHour * 60 + startMin);

    // Calculate price
    const pricePerHour = tutorProfile.pricing?.hourlyRate || 45;
    const totalAmount = (pricePerHour * duration) / 60;

    const bookingData = {
      studentId: req.user.userId,
      tutorId: tutorProfile.userId, // User ID for filtering
      tutorProfileId: tutorProfile._id, // Profile ID for details
      subject: {
        name: subject.name,
        grades: subject.grades || []
      },
      sessionDate: new Date(date),
      startTime,
      endTime,
      duration,
      sessionType: mode || 'online',
      location: mode === 'in-person' ? location : null,
      pricePerHour,
      totalAmount,
      status: 'pending',
      paymentStatus: 'pending',
      payment: {
        amount: totalAmount,
        status: 'pending',
        method: 'chapa'
      },
      notes: {
        student: message || ''
      }
    };

    const booking = new Booking(bookingData);
    await booking.save();

    await booking.populate([
      { path: 'studentId', select: 'firstName lastName email profilePicture' },
      { path: 'tutorId', select: 'firstName lastName email profilePicture' }
    ]);

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create booking',
      error: error.message
    });
  }
});

// Update booking status
router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const Booking = require('../models/Booking');
    const { status } = req.body;

    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized to update this booking
    if (booking.studentId.toString() !== req.user.userId &&
      booking.tutorId.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this booking'
      });
    }

    booking.status = status;
    await booking.save();

    await booking.populate([
      { path: 'studentId', select: 'firstName lastName profilePicture' },
      { path: 'tutorId', select: 'firstName lastName profilePicture' },
      { path: 'subjectId', select: 'name' }
    ]);

    res.json({
      success: true,
      message: 'Booking status updated successfully',
      data: { booking }
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update booking status'
    });
  }
});

module.exports = router;