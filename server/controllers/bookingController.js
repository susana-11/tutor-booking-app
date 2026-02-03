const Booking = require('../models/Booking');
const AvailabilitySlot = require('../models/AvailabilitySlot');
const User = require('../models/User');
const notificationService = require('../services/notificationService');

// Create a new booking request
exports.createBookingRequest = async (req, res) => {
  try {
    const {
      tutorId,
      slotId,
      studentId,
      studentName,
      studentEmail,
      subject,
      sessionDate,
      timeSlot,
      amount,
      notes
    } = req.body;

    // Validate required fields
    if (!tutorId || !slotId || !studentId || !sessionDate || !timeSlot || !amount) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Check if the slot is still available
    const availabilitySlot = await AvailabilitySlot.findById(slotId);
    if (!availabilitySlot) {
      return res.status(404).json({
        success: false,
        message: 'Availability slot not found'
      });
    }

    if (!availabilitySlot.canBeBooked()) {
      return res.status(400).json({
        success: false,
        message: 'This slot is no longer available for booking'
      });
    }

    // Check if tutor is accepting bookings
    const TutorProfile = require('../models/TutorProfile');
    const tutorProfile = await TutorProfile.findById(tutorId);
    
    if (!tutorProfile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    if (!tutorProfile.isAvailable) {
      return res.status(400).json({
        success: false,
        message: 'This tutor is not accepting new bookings at the moment. Please try again later.'
      });
    }

    // Create the booking
    const booking = new Booking({
      tutorId,
      studentId,
      slotId,
      sessionDate: new Date(sessionDate),
      timeSlot: {
        startTime: timeSlot.startTime,
        endTime: timeSlot.endTime,
        durationMinutes: timeSlot.durationMinutes
      },
      subject,
      amount,
      notes,
      status: 'pending',
      payment: {
        amount: amount,
        status: 'pending',
        method: 'chapa'
      },
      studentInfo: {
        name: studentName,
        email: studentEmail
      }
    });

    await booking.save();

    // Update the availability slot with booking info
    availabilitySlot.booking = {
      bookingId: booking._id,
      studentId,
      studentName,
      studentEmail,
      subject,
      status: 'pending',
      amount,
      notes,
      bookedAt: new Date()
    };

    await availabilitySlot.save();

    // Populate tutor and student info for response
    await booking.populate([
      { path: 'tutorId', select: 'firstName lastName email' },
      { path: 'studentId', select: 'firstName lastName email' }
    ]);

    // Send notification to tutor about new booking request
    try {
      const formattedDate = new Date(sessionDate).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      });
      const formattedTime = `${timeSlot.startTime} - ${timeSlot.endTime}`;

      await notificationService.notifyBookingRequest({
        tutorId,
        studentName,
        subject,
        date: formattedDate,
        time: formattedTime,
        bookingId: booking._id
      });
    } catch (notifError) {
      console.error('Failed to send booking notification:', notifError);
      // Don't fail the booking if notification fails
    }

    res.status(201).json({
      success: true,
      message: 'Booking request created successfully',
      data: {
        id: booking._id,
        tutorId: booking.tutorId,
        studentId: booking.studentId,
        slotId: booking.slotId,
        sessionDate: booking.sessionDate,
        timeSlot: booking.timeSlot,
        subject: booking.subject,
        amount: booking.amount,
        notes: booking.notes,
        status: booking.status,
        createdAt: booking.createdAt
      }
    });

  } catch (error) {
    console.error('Create booking request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create booking request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get booking requests for tutor
exports.getTutorBookingRequests = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { status } = req.query;

    const filter = { tutorId };
    if (status) {
      filter.status = status;
    }

    const bookings = await Booking.find(filter)
      .populate('studentId', 'firstName lastName email phone')
      .sort({ createdAt: -1 });

    const formattedRequests = bookings.map(booking => ({
      id: booking._id,
      studentId: booking.studentId._id,
      studentName: `${booking.studentId.firstName} ${booking.studentId.lastName}`,
      studentEmail: booking.studentId.email,
      studentPhone: booking.studentId.phone,
      slotId: booking.slotId,
      sessionDate: booking.sessionDate,
      timeSlot: booking.timeSlot,
      subject: booking.subject,
      message: booking.notes,
      amount: booking.amount,
      status: booking.status,
      requestedAt: booking.createdAt
    }));

    res.json({
      success: true,
      data: {
        requests: formattedRequests
      }
    });

  } catch (error) {
    console.error('Get tutor booking requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking requests',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get bookings for student
exports.getStudentBookings = async (req, res) => {
  try {
    const studentId = req.user.userId;
    const { status } = req.query;

    const filter = { studentId };
    if (status) {
      filter.status = status;
    }

    const bookings = await Booking.find(filter)
      .populate('tutorId', 'firstName lastName email phone')
      .sort({ sessionDate: 1 });

    const formattedBookings = bookings.map(booking => ({
      id: booking._id,
      tutorId: booking.tutorId._id,
      tutorName: `${booking.tutorId.firstName} ${booking.tutorId.lastName}`,
      tutorEmail: booking.tutorId.email,
      tutorPhone: booking.tutorId.phone,
      slotId: booking.slotId,
      sessionDate: booking.sessionDate,
      timeSlot: booking.timeSlot,
      subject: booking.subject,
      amount: booking.amount,
      status: booking.status,
      notes: booking.notes,
      meetingLink: booking.meetingLink,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt
    }));

    res.json({
      success: true,
      data: {
        bookings: formattedBookings
      }
    });

  } catch (error) {
    console.error('Get student bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bookings',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Respond to booking request (accept/decline)
exports.respondToBookingRequest = async (req, res) => {
  try {
    const tutorId = req.user.userId;
    const { requestId, bookingId } = req.params; // Support both parameter names
    const bookingIdToUse = requestId || bookingId; // Use whichever is provided
    let { response, status, message } = req.body; // Support both 'response' and 'status'

    // Normalize the response value - support both formats
    if (status && !response) {
      // Mobile app sends 'status': 'accepted'/'declined'
      response = status === 'accepted' ? 'accept' : status === 'declined' ? 'decline' : status;
    }

    console.log('Respond to booking request:', { tutorId, bookingIdToUse, response, originalStatus: status });

    if (!['accept', 'decline'].includes(response)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid response. Must be "accept"/"decline" or "accepted"/"declined"'
      });
    }

    const booking = await Booking.findById(bookingIdToUse);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking request not found'
      });
    }

    console.log('Booking found:', {
      bookingId: booking._id.toString(),
      tutorId: booking.tutorId?.toString(),
      requestTutorId: tutorId,
      status: booking.status
    });

    // Check if user is the tutor for this booking
    if (booking.tutorId?.toString() !== tutorId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to respond to this booking'
      });
    }

    // Check if booking is still pending
    if (booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Booking request already processed (current status: ${booking.status})`
      });
    }

    // Update booking status
    const newStatus = response === 'accept' ? 'confirmed' : 'declined';
    booking.status = newStatus;
    booking.tutorResponse = message;
    booking.respondedAt = new Date();

    if (response === 'accept') {
      // Generate meeting link (mock for now)
      booking.meetingLink = `https://meet.tutorbooking.com/session/${booking._id}`;
    }

    await booking.save();

    // Update availability slot
    const availabilitySlot = await AvailabilitySlot.findById(booking.slotId);
    if (availabilitySlot && availabilitySlot.booking) {
      availabilitySlot.booking.status = newStatus;
      if (booking.meetingLink) {
        availabilitySlot.booking.meetingLink = booking.meetingLink;
      }
      await availabilitySlot.save();
    }

    // Send notification to student about booking response
    try {
      // Get tutor info
      const tutor = await User.findById(tutorId).select('firstName lastName');
      const tutorName = tutor ? `${tutor.firstName} ${tutor.lastName}` : 'Tutor';

      const formattedDate = new Date(booking.sessionDate).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      });
      const formattedTime = `${booking.timeSlot.startTime} - ${booking.timeSlot.endTime}`;

      if (response === 'accept') {
        await notificationService.notifyBookingAccepted({
          studentId: booking.studentId,
          tutorName,
          subject: booking.subject,
          date: formattedDate,
          time: formattedTime,
          bookingId: booking._id
        });
      } else {
        await notificationService.notifyBookingDeclined({
          studentId: booking.studentId,
          tutorName,
          subject: booking.subject,
          reason: message,
          bookingId: booking._id
        });
      }
    } catch (notifError) {
      console.error('Failed to send booking response notification:', notifError);
      // Don't fail the response if notification fails
    }

    res.json({
      success: true,
      message: `Booking request ${response}ed successfully`,
      data: {
        bookingId: booking._id,
        status: booking.status,
        meetingLink: booking.meetingLink
      }
    });

  } catch (error) {
    console.error('Respond to booking request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to respond to booking request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Cancel booking
exports.cancelBooking = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookingId } = req.params;
    const { reason } = req.body;

    console.log('Cancel booking request:', { userId, bookingId, reason });

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    console.log('Booking found:', {
      bookingId: booking._id.toString(),
      studentId: booking.studentId?.toString(),
      tutorId: booking.tutorId?.toString(),
      userId: userId,
      status: booking.status
    });

    // Check if user is authorized to cancel
    const isStudent = booking.studentId?.toString() === userId.toString();
    const isTutor = booking.tutorId?.toString() === userId.toString();

    console.log('Authorization check:', { isStudent, isTutor });

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to cancel this booking'
      });
    }

    // Check if booking can be cancelled
    if (booking.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already cancelled'
      });
    }

    if (!['pending', 'confirmed'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Booking cannot be cancelled (current status: ${booking.status})`
      });
    }

    // Check cancellation policy (24 hours before session)
    const sessionDateTime = new Date(booking.sessionDate);
    const now = new Date();
    const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);

    console.log('Cancellation policy check:', {
      sessionDateTime,
      now,
      hoursUntilSession,
      isStudent
    });

    // Allow cancellation if more than 1 hour before session (relaxed for testing)
    // In production, change this back to 24 hours
    if (hoursUntilSession < 1 && hoursUntilSession > 0 && isStudent) {
      return res.status(400).json({
        success: false,
        message: 'Bookings can only be cancelled at least 1 hour before the session'
      });
    }

    // Allow cancellation of past bookings for testing purposes
    // In production, you might want to prevent this

    // Update booking
    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    booking.cancelledBy = userId;
    booking.cancelledAt = new Date();

    await booking.save();

    // Update availability slot
    const availabilitySlot = await AvailabilitySlot.findById(booking.slotId);
    if (availabilitySlot) {
      // Remove booking info and make slot available again
      availabilitySlot.booking = undefined;
      availabilitySlot.isAvailable = true;
      await availabilitySlot.save();
    }

    // Send notification to the other party about cancellation
    try {
      const formattedDate = new Date(booking.sessionDate).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      });

      // Notify the other party (if student cancelled, notify tutor and vice versa)
      const notifyUserId = isStudent ? booking.tutorId : booking.studentId;
      const cancelledByUser = await User.findById(userId).select('firstName lastName');
      const cancelledByName = cancelledByUser ? `${cancelledByUser.firstName} ${cancelledByUser.lastName}` : 'User';

      await notificationService.notifyBookingCancelled({
        userId: notifyUserId,
        cancelledBy: cancelledByName,
        subject: booking.subject,
        date: formattedDate,
        reason,
        bookingId: booking._id
      });
    } catch (notifError) {
      console.error('Failed to send cancellation notification:', notifError);
      // Don't fail the cancellation if notification fails
    }

    res.json({
      success: true,
      message: 'Booking cancelled successfully'
    });

  } catch (error) {
    console.error('Cancel booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel booking',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get booking details
exports.getBookingDetails = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookingId } = req.params;

    const booking = await Booking.findById(bookingId)
      .populate('tutorId', 'firstName lastName email phone')
      .populate('studentId', 'firstName lastName email phone');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized to view
    const isStudent = booking.studentId._id.toString() === userId;
    const isTutor = booking.tutorId._id.toString() === userId;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this booking'
      });
    }

    res.json({
      success: true,
      data: {
        id: booking._id,
        tutorId: booking.tutorId._id,
        tutorName: `${booking.tutorId.firstName} ${booking.tutorId.lastName}`,
        tutorEmail: booking.tutorId.email,
        tutorPhone: booking.tutorId.phone,
        studentId: booking.studentId._id,
        studentName: `${booking.studentId.firstName} ${booking.studentId.lastName}`,
        studentEmail: booking.studentId.email,
        studentPhone: booking.studentId.phone,
        slotId: booking.slotId,
        sessionDate: booking.sessionDate,
        timeSlot: booking.timeSlot,
        subject: booking.subject,
        amount: booking.amount,
        status: booking.status,
        notes: booking.notes,
        meetingLink: booking.meetingLink,
        tutorResponse: booking.tutorResponse,
        cancellationReason: booking.cancellationReason,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        respondedAt: booking.respondedAt,
        cancelledAt: booking.cancelledAt
      }
    });

  } catch (error) {
    console.error('Get booking details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking details',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Rate a completed booking
exports.rateBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { rating, review, categories } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Validate rating
    if (!rating || rating < 1 || rating > 5 || !Number.isInteger(rating)) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be a whole number between 1 and 5'
      });
    }

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName')
      .populate('tutorId');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is a participant
    const isStudent = booking.studentId._id.toString() === userId;
    const isTutor = booking.tutorId?._id?.toString() === userId;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'You can only rate your own bookings'
      });
    }

    // Verify booking is completed
    if (booking.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'You can only rate completed sessions'
      });
    }

    // Check if already rated
    if (isStudent && booking.rating?.studentRating?.score) {
      return res.status(400).json({
        success: false,
        message: 'You have already rated this session'
      });
    }

    if (isTutor && booking.rating?.tutorRating?.score) {
      return res.status(400).json({
        success: false,
        message: 'You have already rated this session'
      });
    }

    // Add rating to booking
    await booking.addRating(userId, rating, review, userRole);

    // If student is rating, create Review document
    if (isStudent) {
      const Review = require('../models/Review');
      const TutorProfile = require('../models/TutorProfile');

      // Check if review already exists
      const existingReview = await Review.findOne({ bookingId });

      if (!existingReview) {
        const newReview = await Review.create({
          bookingId,
          tutorId: booking.tutorId._id,
          studentId: userId,
          rating,
          review: review || '',
          categories: categories || {},
          sessionDate: booking.sessionDate,
          subject: booking.subject?.name || 'Session'
        });

        // Notify tutor
        const tutorUser = await TutorProfile.findById(booking.tutorId._id).populate('userId');
        if (tutorUser && tutorUser.userId) {
          await notificationService.createNotification({
            userId: tutorUser.userId._id,
            type: 'new_review',
            title: 'New Review Received ⭐',
            body: `${booking.studentId.firstName} rated your session ${rating} stars`,
            data: {
              type: 'new_review',
              reviewId: newReview._id.toString(),
              bookingId: bookingId.toString(),
              rating
            },
            priority: 'normal',
            actionUrl: '/tutor/reviews'
          });
        }
      }
    }

    res.json({
      success: true,
      message: 'Rating submitted successfully',
      data: {
        bookingId: booking._id,
        rating: booking.rating
      }
    });

  } catch (error) {
    console.error('Rate booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit rating',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

module.exports = exports;


// Process payment for booking
exports.processPayment = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { paymentMethod, paymentToken } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is the student
    if (booking.studentId.toString() !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to pay for this booking'
      });
    }

    // Check if already paid
    if (booking.paymentStatus === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Booking already paid'
      });
    }

    // Mock payment processing (integrate with Stripe/PayPal in production)
    const paymentResult = await processPaymentMock({
      amount: booking.totalAmount,
      currency: 'USD',
      paymentMethod,
      paymentToken,
      bookingId: booking._id,
    });

    if (paymentResult.success) {
      booking.paymentStatus = 'paid';
      booking.paymentId = paymentResult.paymentId;
      booking.paymentMethod = paymentMethod;
      booking.paymentIntentId = paymentResult.intentId;
      booking.transactionId = paymentResult.transactionId;
      booking.paidAt = new Date();

      await booking.save();

      res.json({
        success: true,
        message: 'Payment processed successfully',
        data: {
          bookingId: booking._id,
          paymentId: booking.paymentId,
          amount: booking.totalAmount,
          paymentStatus: booking.paymentStatus,
        }
      });
    } else {
      booking.paymentStatus = 'failed';
      await booking.save();

      res.status(400).json({
        success: false,
        message: 'Payment failed',
        error: paymentResult.error
      });
    }

  } catch (error) {
    console.error('Process payment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process payment',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Mock payment processing function
async function processPaymentMock({ amount, currency, paymentMethod, paymentToken, bookingId }) {
  // Simulate payment processing delay
  await new Promise(resolve => setTimeout(resolve, 1000));

  // Mock success (90% success rate)
  const success = Math.random() > 0.1;

  if (success) {
    return {
      success: true,
      paymentId: `pay_${Date.now()}`,
      intentId: `pi_${Date.now()}`,
      transactionId: `txn_${Date.now()}`,
    };
  } else {
    return {
      success: false,
      error: 'Payment declined by bank'
    };
  }
}

// Request reschedule
exports.requestReschedule = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { newDate, newStartTime, newEndTime, reason } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized
    const isStudent = booking.studentId.toString() === req.user.userId;
    const isTutor = booking.tutorId.toString() === req.user.userId;

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reschedule this booking'
      });
    }

    // Check if booking can be rescheduled
    if (!booking.canBeRescheduled) {
      return res.status(400).json({
        success: false,
        message: 'Booking cannot be rescheduled (must be at least 48 hours before session)'
      });
    }

    // Add reschedule request
    booking.rescheduleRequests.push({
      requestedBy: req.user.userId,
      requestedAt: new Date(),
      newDate: new Date(newDate),
      newStartTime,
      newEndTime,
      reason,
      status: 'pending',
    });

    await booking.save();

    res.json({
      success: true,
      message: 'Reschedule request submitted successfully',
      data: {
        bookingId: booking._id,
        rescheduleRequest: booking.rescheduleRequests[booking.rescheduleRequests.length - 1]
      }
    });

  } catch (error) {
    console.error('Request reschedule error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to request reschedule',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};