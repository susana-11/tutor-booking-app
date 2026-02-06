const Booking = require('../models/Booking');
const AvailabilitySlot = require('../models/AvailabilitySlot');
const User = require('../models/User');
const notificationService = require('../services/notificationService');
const escrowService = require('../services/escrowService');

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
      .populate('rescheduleRequests.requestedBy', 'firstName lastName')
      .sort({ createdAt: -1 });

    const formattedRequests = bookings.map(booking => ({
      _id: booking._id,
      id: booking._id,
      studentId: booking.studentId._id,
      studentName: `${booking.studentId.firstName} ${booking.studentId.lastName}`,
      studentEmail: booking.studentId.email,
      studentPhone: booking.studentId.phone,
      slotId: booking.slotId,
      sessionDate: booking.sessionDate,
      // Support both old and new format
      timeSlot: booking.timeSlot || {
        startTime: booking.startTime,
        endTime: booking.endTime,
        durationMinutes: booking.duration
      },
      startTime: booking.startTime,
      endTime: booking.endTime,
      duration: booking.duration,
      subject: booking.subject,
      subjectName: booking.subject?.name,
      sessionType: booking.sessionType,
      location: booking.location,
      message: booking.notes?.student || booking.notes,
      amount: booking.totalAmount || booking.amount,
      totalAmount: booking.totalAmount,
      pricePerHour: booking.pricePerHour,
      status: booking.status,
      paymentStatus: booking.paymentStatus || booking.payment?.status,
      payment: booking.payment,
      rescheduleRequests: booking.rescheduleRequests || [],
      hasReview: booking.hasReview || false,
      sessionStartedAt: booking.sessionStartedAt,
      session: booking.session,
      checkIn: booking.checkIn,
      meetingLink: booking.meetingLink,
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
      .populate('rescheduleRequests.requestedBy', 'firstName lastName')
      .sort({ sessionDate: 1 });

    const formattedBookings = bookings.map(booking => ({
      _id: booking._id,
      id: booking._id,
      tutorId: booking.tutorId._id,
      tutorName: `${booking.tutorId.firstName} ${booking.tutorId.lastName}`,
      tutorEmail: booking.tutorId.email,
      tutorPhone: booking.tutorId.phone,
      slotId: booking.slotId,
      sessionDate: booking.sessionDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      timeSlot: booking.timeSlot,
      subject: booking.subject?.name || booking.subject,
      amount: booking.amount,
      totalAmount: booking.totalAmount,
      pricePerHour: booking.pricePerHour,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      payment: booking.payment,
      notes: booking.notes,
      meetingLink: booking.meetingLink,
      rescheduleRequests: booking.rescheduleRequests || [],
      hasReview: booking.hasReview || false,
      sessionStartedAt: booking.sessionStartedAt,
      session: booking.session,
      checkIn: booking.checkIn,
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

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email');
      
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    console.log('Booking found:', {
      bookingId: booking._id.toString(),
      studentId: booking.studentId?._id?.toString(),
      tutorId: booking.tutorId?._id?.toString(),
      userId: userId,
      status: booking.status,
      escrowStatus: booking.escrow?.status,
      paymentStatus: booking.payment?.status
    });

    // Check if user is authorized to cancel
    const isStudent = booking.studentId?._id?.toString() === userId.toString();
    const isTutor = booking.tutorId?._id?.toString() === userId.toString();

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

    // Cannot cancel if session has started or completed
    if (['completed', 'no-show'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Booking cannot be cancelled (current status: ${booking.status})`
      });
    }

    // Check if session has already started
    if (booking.session?.isActive || booking.sessionStartedAt) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel - session has already started'
      });
    }

    // Check if both parties have checked in (for offline sessions)
    if (booking.checkIn?.bothCheckedIn) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel - both parties have checked in'
      });
    }

    if (!['pending', 'confirmed'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Booking cannot be cancelled (current status: ${booking.status})`
      });
    }

    // Calculate refund eligibility
    // If tutor cancels, always give full refund
    let refundCalculation;
    if (isTutor) {
      refundCalculation = {
        refundAmount: booking.totalAmount,
        refundPercentage: 100,
        platformFeeRetained: 0,
        hoursUntilSession: 0,
        refundReason: 'Tutor cancelled - full refund',
        eligible: true
      };
      console.log('Tutor cancellation - full refund:', refundCalculation);
    } else {
      // Student cancellation - apply refund rules based on timing
      refundCalculation = escrowService.calculateRefundAmount(booking);
      console.log('Student cancellation - refund calculation:', refundCalculation);
    }
    
    console.log('Refund calculation:', refundCalculation);

    // Update booking
    booking.status = 'cancelled';
    booking.cancellationReason = reason;
    booking.cancelledBy = userId;
    booking.cancelledAt = new Date();
    booking.refundAmount = refundCalculation.refundAmount;
    booking.refundStatus = refundCalculation.eligible ? 'processing' : 'none';

    await booking.save();

    // Process refund if payment was made and escrow is held
    let refundResult = null;
    if (booking.payment?.status === 'paid' && booking.escrow?.status === 'held') {
      try {
        refundResult = await escrowService.refundEscrow(bookingId, reason);
        console.log('✅ Refund processed:', refundResult);
      } catch (refundError) {
        console.error('❌ Refund processing error:', refundError);
        // Continue with cancellation even if refund fails
      }
    }

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
      const notifyUserId = isStudent ? booking.tutorId._id : booking.studentId._id;
      const cancelledByUser = await User.findById(userId).select('firstName lastName');
      const cancelledByName = cancelledByUser ? `${cancelledByUser.firstName} ${cancelledByUser.lastName}` : 'User';
      const cancelledByRole = isStudent ? 'student' : 'tutor';

      console.log('📧 Sending cancellation notification:', {
        from: cancelledByName,
        fromRole: cancelledByRole,
        to: notifyUserId.toString(),
        toRole: isStudent ? 'tutor' : 'student',
        bookingId: booking._id.toString()
      });

      await notificationService.notifyBookingCancelled({
        userId: notifyUserId,
        cancelledBy: cancelledByName,
        subject: booking.subject?.name || 'Session',
        date: formattedDate,
        reason,
        bookingId: booking._id
      });

      console.log('✅ Cancellation notification sent successfully');
    } catch (notifError) {
      console.error('❌ Failed to send cancellation notification:', notifError);
      // Don't fail the cancellation if notification fails
    }

    res.json({
      success: true,
      message: 'Booking cancelled successfully',
      data: {
        bookingId: booking._id,
        status: booking.status,
        refund: refundResult ? {
          amount: refundResult.refundAmount,
          percentage: refundResult.refundPercentage,
          reason: refundResult.refundReason
        } : {
          amount: refundCalculation.refundAmount,
          percentage: refundCalculation.refundPercentage,
          reason: refundCalculation.refundReason
        }
      }
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
    const isStudent = booking.studentId._id.toString() === userId.toString();
    const isTutor = booking.tutorId._id.toString() === userId.toString();

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
    if (booking.studentId.toString() !== req.user.userId.toString()) {
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
    const { 
      newDate, 
      newStartTime, 
      newEndTime, 
      newSessionType,
      newLocation,
      newDuration,
      reason 
    } = req.body;

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName')
      .populate('tutorId', 'firstName lastName');
      
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized
    const isStudent = booking.studentId._id.toString() === req.user.userId.toString();
    const isTutor = booking.tutorId._id.toString() === req.user.userId.toString();

    console.log('🔐 Reschedule authorization check:', {
      bookingId: booking._id.toString(),
      studentId: booking.studentId._id.toString(),
      tutorId: booking.tutorId._id.toString(),
      requestUserId: req.user.userId.toString(),
      isStudent,
      isTutor
    });

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reschedule this booking'
      });
    }

    // Check if booking can be rescheduled
    if (!booking.canBeRescheduled) {
      const hoursUntilSession = (new Date(booking.sessionDate) - new Date()) / (1000 * 60 * 60);
      if (hoursUntilSession < 1) {
        return res.status(400).json({
          success: false,
          message: 'Booking cannot be rescheduled (must be at least 1 hour before session)'
        });
      }
      if (booking.rescheduleCount >= booking.maxRescheduleAttempts) {
        return res.status(400).json({
          success: false,
          message: `Maximum reschedule attempts (${booking.maxRescheduleAttempts}) reached`
        });
      }
    }

    // Check if there's already a pending reschedule request
    const hasPendingRequest = booking.rescheduleRequests.some(req => req.status === 'pending');
    if (hasPendingRequest) {
      return res.status(400).json({
        success: false,
        message: 'There is already a pending reschedule request for this booking'
      });
    }

    // Calculate price adjustment if duration or session type changes
    let priceAdjustment = 0;
    let newTotalAmount = booking.totalAmount;
    
    if (newDuration && newDuration !== booking.duration) {
      // Duration changed - recalculate price
      newTotalAmount = (booking.pricePerHour * newDuration) / 60;
      priceAdjustment = newTotalAmount - booking.totalAmount;
    } else if (newSessionType && newSessionType !== booking.sessionType) {
      // Session type changed - might have different pricing
      // For now, keep same price unless duration also changes
      priceAdjustment = 0;
    }

    // Add reschedule request
    const rescheduleRequest = {
      requestedBy: req.user.userId,
      requestedAt: new Date(),
      newDate: new Date(newDate),
      newStartTime,
      newEndTime,
      newSessionType: newSessionType || booking.sessionType,
      newLocation: newLocation || booking.location,
      newDuration: newDuration || booking.duration,
      newTotalAmount,
      priceAdjustment,
      reason,
      status: 'pending',
    };
    
    booking.rescheduleRequests.push(rescheduleRequest);
    await booking.save();

    // Get the saved request with ID
    const savedRequest = booking.rescheduleRequests[booking.rescheduleRequests.length - 1];

    // Send notification to the other party
    try {
      const requestedByName = isStudent 
        ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
        : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;
      
      const notifyUserId = isStudent ? booking.tutorId._id : booking.studentId._id;
      const requestedByRole = isStudent ? 'student' : 'tutor';
      
      const formattedNewDate = new Date(newDate).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      });

      let notificationBody = `${requestedByName} requested to reschedule your session to ${formattedNewDate} at ${newStartTime}`;
      
      if (priceAdjustment !== 0) {
        notificationBody += `. Price adjustment: ETB ${Math.abs(priceAdjustment).toFixed(2)} ${priceAdjustment > 0 ? 'additional' : 'refund'}`;
      }

      console.log('📧 Sending reschedule request notification:', {
        from: requestedByName,
        fromRole: requestedByRole,
        to: notifyUserId.toString(),
        toRole: isStudent ? 'tutor' : 'student',
        bookingId: booking._id.toString(),
        newDate: formattedNewDate,
        newTime: `${newStartTime} - ${newEndTime}`
      });

      await notificationService.createNotification({
        userId: notifyUserId,
        type: 'reschedule_request',
        title: 'Reschedule Request',
        body: notificationBody,
        data: {
          type: 'reschedule_request',
          bookingId: booking._id.toString(),
          requestId: savedRequest._id.toString(),
          newDate: formattedNewDate,
          newTime: `${newStartTime} - ${newEndTime}`,
          priceAdjustment: priceAdjustment
        },
        priority: 'high',
        actionUrl: isStudent ? '/tutor/bookings' : '/student/bookings'
      });

      console.log('✅ Reschedule request notification sent successfully');
    } catch (notifError) {
      console.error('❌ Failed to send reschedule notification:', notifError);
    }

    res.json({
      success: true,
      message: 'Reschedule request submitted successfully',
      data: {
        bookingId: booking._id,
        rescheduleRequest: savedRequest,
        priceAdjustment,
        newTotalAmount
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

// Respond to reschedule request
exports.respondToRescheduleRequest = async (req, res) => {
  try {
    const { bookingId, requestId } = req.params;
    const { response } = req.body; // 'accept' or 'reject'

    if (!['accept', 'reject'].includes(response)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid response. Must be "accept" or "reject"'
      });
    }

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName')
      .populate('tutorId', 'firstName lastName');
      
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Find the reschedule request
    const rescheduleRequest = booking.rescheduleRequests.id(requestId);
    if (!rescheduleRequest) {
      return res.status(404).json({
        success: false,
        message: 'Reschedule request not found'
      });
    }

    // Check if request is still pending
    if (rescheduleRequest.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Reschedule request already ${rescheduleRequest.status}`
      });
    }

    // Check if user is authorized (must be the other party, not the requester)
    const isStudent = booking.studentId._id.toString() === req.user.userId.toString();
    const isTutor = booking.tutorId._id.toString() === req.user.userId.toString();
    const isRequester = rescheduleRequest.requestedBy.toString() === req.user.userId.toString();

    console.log('🔐 Reschedule response authorization check:', {
      bookingId: booking._id.toString(),
      requestId: requestId,
      studentId: booking.studentId._id.toString(),
      tutorId: booking.tutorId._id.toString(),
      requesterId: rescheduleRequest.requestedBy.toString(),
      responseUserId: req.user.userId.toString(),
      isStudent,
      isTutor,
      isRequester
    });

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to respond to this reschedule request'
      });
    }

    if (isRequester) {
      return res.status(403).json({
        success: false,
        message: 'You cannot respond to your own reschedule request'
      });
    }

    // Update reschedule request status
    rescheduleRequest.status = response === 'accept' ? 'accepted' : 'rejected';
    rescheduleRequest.respondedAt = new Date();

    // If accepted, update the booking with new date/time and other details
    if (response === 'accept') {
      booking.sessionDate = rescheduleRequest.newDate;
      booking.startTime = rescheduleRequest.newStartTime;
      booking.endTime = rescheduleRequest.newEndTime;
      
      // Update session type if changed
      if (rescheduleRequest.newSessionType) {
        booking.sessionType = rescheduleRequest.newSessionType;
      }
      
      // Update location if changed (for offline sessions)
      if (rescheduleRequest.newLocation) {
        booking.location = rescheduleRequest.newLocation;
      }
      
      // Update duration and price if changed
      if (rescheduleRequest.newDuration) {
        booking.duration = rescheduleRequest.newDuration;
      }
      if (rescheduleRequest.newTotalAmount) {
        booking.totalAmount = rescheduleRequest.newTotalAmount;
      }
      
      // Increment reschedule count
      booking.rescheduleCount = (booking.rescheduleCount || 0) + 1;
      
      // Mark as rescheduled
      booking.isRescheduled = true;
      
      // Handle payment adjustment if price changed
      if (rescheduleRequest.priceAdjustment && rescheduleRequest.priceAdjustment !== 0) {
        // Update escrow amount if payment was made
        if (booking.payment?.status === 'paid' && booking.escrow?.status === 'held') {
          const newEscrowAmount = booking.escrow.amount + rescheduleRequest.priceAdjustment;
          booking.escrow.amount = Math.max(0, newEscrowAmount);
          
          // If additional payment needed, update payment status
          if (rescheduleRequest.priceAdjustment > 0) {
            booking.payment.amount = rescheduleRequest.newTotalAmount;
            // Note: Student would need to pay the difference
          }
        }
      }
      
      // Update availability slot if exists
      if (booking.slotId) {
        const AvailabilitySlot = require('../models/AvailabilitySlot');
        const slot = await AvailabilitySlot.findById(booking.slotId);
        if (slot && slot.booking) {
          slot.booking.sessionDate = rescheduleRequest.newDate;
          slot.booking.startTime = rescheduleRequest.newStartTime;
          slot.booking.endTime = rescheduleRequest.newEndTime;
          await slot.save();
        }
      }
    }

    await booking.save();

    // Send notification to the requester
    try {
      const responderName = isStudent 
        ? `${booking.studentId.firstName} ${booking.studentId.lastName}`
        : `${booking.tutorId.firstName} ${booking.tutorId.lastName}`;
      
      const notifyUserId = rescheduleRequest.requestedBy;
      const responderRole = isStudent ? 'student' : 'tutor';
      
      const formattedDate = new Date(rescheduleRequest.newDate).toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      });

      console.log('📧 Sending reschedule response notification:', {
        from: responderName,
        fromRole: responderRole,
        to: notifyUserId.toString(),
        response: response,
        bookingId: booking._id.toString(),
        newDate: formattedDate
      });

      if (response === 'accept') {
        await notificationService.createNotification({
          userId: notifyUserId,
          type: 'reschedule_accepted',
          title: 'Reschedule Request Accepted ✅',
          body: `${responderName} accepted your reschedule request. New session: ${formattedDate} at ${rescheduleRequest.newStartTime}`,
          data: {
            type: 'reschedule_accepted',
            bookingId: booking._id.toString(),
            newDate: formattedDate,
            newTime: `${rescheduleRequest.newStartTime} - ${rescheduleRequest.newEndTime}`
          },
          priority: 'high',
          actionUrl: isStudent ? '/tutor/bookings' : '/student/bookings'
        });
      } else {
        await notificationService.createNotification({
          userId: notifyUserId,
          type: 'reschedule_rejected',
          title: 'Reschedule Request Declined',
          body: `${responderName} declined your reschedule request`,
          data: {
            type: 'reschedule_rejected',
            bookingId: booking._id.toString()
          },
          priority: 'normal',
          actionUrl: isStudent ? '/tutor/bookings' : '/student/bookings'
        });
      }

      console.log('✅ Reschedule response notification sent successfully');
    } catch (notifError) {
      console.error('❌ Failed to send reschedule response notification:', notifError);
    }

    res.json({
      success: true,
      message: `Reschedule request ${response}ed successfully`,
      data: {
        bookingId: booking._id,
        rescheduleRequest: rescheduleRequest,
        ...(response === 'accept' && {
          newSessionDate: booking.sessionDate,
          newStartTime: booking.startTime,
          newEndTime: booking.endTime
        })
      }
    });

  } catch (error) {
    console.error('Respond to reschedule request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to respond to reschedule request',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Get reschedule requests for a booking
exports.getRescheduleRequests = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await Booking.findById(bookingId)
      .populate('rescheduleRequests.requestedBy', 'firstName lastName')
      .populate('studentId', 'firstName lastName')
      .populate('tutorId', 'firstName lastName');
      
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check if user is authorized
    const isStudent = booking.studentId._id.toString() === req.user.userId.toString();
    const isTutor = booking.tutorId._id.toString() === req.user.userId.toString();

    if (!isStudent && !isTutor) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view reschedule requests for this booking'
      });
    }

    res.json({
      success: true,
      data: {
        bookingId: booking._id,
        rescheduleRequests: booking.rescheduleRequests
      }
    });

  } catch (error) {
    console.error('Get reschedule requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reschedule requests',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};