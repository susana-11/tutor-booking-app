const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const Booking = require('../models/Booking');
const paymentService = require('../services/paymentService');
const notificationService = require('../services/notificationService');

// Alias for consistency with other routes
const protect = authenticate;

// Payment routes
router.post('/:bookingId/payment/intent', protect, async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.studentId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const result = await paymentService.createPaymentIntent({
      amount: booking.totalAmount,
      currency: 'USD',
      metadata: {
        bookingId: booking._id.toString(),
        studentId: booking.studentId.toString(),
        tutorId: booking.tutorId.toString(),
      },
    });

    if (result.success) {
      booking.paymentIntentId = result.paymentIntent.id;
      booking.paymentStatus = 'processing';
      await booking.save();
    }

    res.json(result);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/:bookingId/payment/confirm', protect, async (req, res) => {
  try {
    const { paymentMethod } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const result = await paymentService.confirmPayment({
      paymentIntentId: booking.paymentIntentId,
      paymentMethod,
    });

    if (result.success) {
      booking.paymentStatus = 'paid';
      booking.paymentMethod = paymentMethod;
      booking.transactionId = result.transactionId;
      booking.paidAt = new Date();
      booking.status = 'confirmed';
      await booking.save();

      await notificationService.sendPaymentConfirmation(booking, result.paymentIntent);
    } else {
      booking.paymentStatus = 'failed';
      await booking.save();
    }

    res.json(result);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Reschedule routes
router.post('/:bookingId/reschedule/request', protect, async (req, res) => {
  try {
    const { newDate, newStartTime, newEndTime, reason } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const isAuthorized = booking.studentId.toString() === req.user.userId || 
                        booking.tutorId.toString() === req.user.userId;
    
    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (!booking.canBeRescheduled) {
      return res.status(400).json({ 
        success: false, 
        message: 'Booking cannot be rescheduled (must be at least 48 hours before session)' 
      });
    }

    const rescheduleRequest = {
      requestedBy: req.user.userId,
      requestedAt: new Date(),
      newDate: new Date(newDate),
      newStartTime,
      newEndTime,
      reason,
      status: 'pending',
    };

    booking.rescheduleRequests.push(rescheduleRequest);
    await booking.save();

    await notificationService.sendRescheduleNotification(booking, rescheduleRequest);

    res.json({
      success: true,
      message: 'Reschedule request submitted',
      data: { rescheduleRequest },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/:bookingId/reschedule/:requestId/respond', protect, async (req, res) => {
  try {
    const { response } = req.body; // 'accept' or 'reject'
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const rescheduleRequest = booking.rescheduleRequests.id(req.params.requestId);
    if (!rescheduleRequest) {
      return res.status(404).json({ success: false, message: 'Reschedule request not found' });
    }

    const requestedByStudent = rescheduleRequest.requestedBy.toString() === booking.studentId.toString();
    const isAuthorized = (requestedByStudent && booking.tutorId.toString() === req.user.userId) ||
                        (!requestedByStudent && booking.studentId.toString() === req.user.userId);

    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    rescheduleRequest.status = response === 'accept' ? 'accepted' : 'rejected';
    rescheduleRequest.respondedAt = new Date();

    if (response === 'accept') {
      booking.sessionDate = rescheduleRequest.newDate;
      booking.startTime = rescheduleRequest.newStartTime;
      booking.endTime = rescheduleRequest.newEndTime;
      booking.isRescheduled = true;
    }

    await booking.save();

    res.json({
      success: true,
      message: `Reschedule request ${response}ed`,
      data: { booking },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Session completion and rating
router.post('/:bookingId/complete', protect, authorize('tutor'), async (req, res) => {
  try {
    const { sessionNotes } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.tutorId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await booking.completeSession(sessionNotes);
    await notificationService.sendRatingRequest(booking);

    res.json({
      success: true,
      message: 'Session completed',
      data: { booking },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/:bookingId/rating', protect, async (req, res) => {
  try {
    const { score, review } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const isStudent = booking.studentId.toString() === req.user.userId;
    const isTutor = booking.tutorId.toString() === req.user.userId;

    if (!isStudent && !isTutor) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const userRole = isStudent ? 'student' : 'tutor';
    await booking.addRating(req.user.userId, score, review, userRole);

    // Update tutor's average rating
    if (isStudent) {
      const TutorProfile = require('../models/TutorProfile');
      const completedBookings = await Booking.find({
        tutorId: booking.tutorId,
        status: 'completed',
        'rating.studentRating.score': { $exists: true }
      });

      const totalRating = completedBookings.reduce((sum, b) => sum + (b.rating.studentRating?.score || 0), 0);
      const avgRating = totalRating / completedBookings.length;

      await TutorProfile.findOneAndUpdate(
        { userId: booking.tutorId },
        { 
          rating: avgRating,
          totalReviews: completedBookings.length
        }
      );
    }

    res.json({
      success: true,
      message: 'Rating added',
      data: { rating: booking.rating },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Refund routes
router.post('/:bookingId/refund', protect, async (req, res) => {
  try {
    const { reason } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.studentId.toString() !== req.user.userId) {
      return res.status(403).json({ success: false, message: 'Only student can request refund' });
    }

    if (booking.status !== 'cancelled') {
      return res.status(400).json({ success: false, message: 'Only cancelled bookings can be refunded' });
    }

    booking.refundReason = reason;
    await booking.processRefund();

    const refundResult = await paymentService.createRefund({
      paymentIntentId: booking.paymentIntentId,
      amount: booking.refundAmount * 100, // Convert to cents
      reason,
    });

    if (refundResult.success) {
      booking.refundId = refundResult.refund.id;
      booking.refundStatus = 'completed';
      booking.refundedAt = new Date();
      await booking.save();

      await notificationService.sendRefundNotification(booking, refundResult.refund);
    }

    res.json({
      success: true,
      message: 'Refund processed',
      data: { 
        refundAmount: booking.refundAmount,
        refundStatus: booking.refundStatus,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Dispute routes
router.post('/:bookingId/dispute', protect, async (req, res) => {
  try {
    const { reason, description } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const isAuthorized = booking.studentId.toString() === req.user.userId || 
                        booking.tutorId.toString() === req.user.userId;

    if (!isAuthorized) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await booking.createDispute(req.user.userId, reason, description);
    await notificationService.sendDisputeNotification(booking, booking.dispute);

    res.json({
      success: true,
      message: 'Dispute created',
      data: { dispute: booking.dispute },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/disputes', protect, authorize('admin'), async (req, res) => {
  try {
    const { status } = req.query;
    const query = { 'dispute.isDisputed': true };
    
    if (status) {
      query['dispute.disputeStatus'] = status;
    }

    const bookings = await Booking.find(query)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email')
      .populate('dispute.disputedBy', 'firstName lastName email')
      .sort({ 'dispute.disputedAt': -1 });

    res.json({
      success: true,
      data: { disputes: bookings },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/:bookingId/dispute/resolve', protect, authorize('admin'), async (req, res) => {
  try {
    const { resolution, refundPercentage } = req.body;
    const booking = await Booking.findById(req.params.bookingId);
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    booking.dispute.disputeStatus = 'resolved';
    booking.dispute.resolution = resolution;
    booking.dispute.resolvedAt = new Date();
    booking.dispute.resolvedBy = req.user.userId;

    if (refundPercentage && refundPercentage > 0) {
      booking.refundAmount = (booking.totalAmount * refundPercentage) / 100;
      booking.refundStatus = 'completed';
      booking.paymentStatus = refundPercentage === 100 ? 'refunded' : 'partially_refunded';
      booking.refundedAt = new Date();
    }

    await booking.save();

    res.json({
      success: true,
      message: 'Dispute resolved',
      data: { booking },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Earnings routes
router.get('/earnings', protect, authorize('tutor'), async (req, res) => {
  try {
    const { period, startDate, endDate } = req.query;
    let start, end;

    if (period) {
      const now = new Date();
      switch (period) {
        case 'week':
          start = new Date(now.setDate(now.getDate() - 7));
          end = new Date();
          break;
        case 'month':
          start = new Date(now.setMonth(now.getMonth() - 1));
          end = new Date();
          break;
        case 'year':
          start = new Date(now.setFullYear(now.getFullYear() - 1));
          end = new Date();
          break;
        default:
          start = new Date(now.setMonth(now.getMonth() - 1));
          end = new Date();
      }
    } else {
      start = startDate ? new Date(startDate) : new Date(new Date().setMonth(new Date().getMonth() - 1));
      end = endDate ? new Date(endDate) : new Date();
    }

    const summary = await Booking.getEarningsSummary(req.user.userId, start, end);

    res.json({
      success: true,
      data: { summary, period: { start, end } },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Dashboard stats
router.get('/dashboard-stats', protect, async (req, res) => {
  try {
    const userId = req.user.userId;
    const userRole = req.user.role;
    const now = new Date();

    let stats = {};

    if (userRole === 'tutor') {
      const [totalBookings, completedSessions, upcomingSessions] = await Promise.all([
        Booking.countDocuments({ tutorId: userId }),
        Booking.countDocuments({ tutorId: userId, status: 'completed' }),
        Booking.countDocuments({ 
          tutorId: userId, 
          status: { $in: ['confirmed', 'pending'] },
          sessionDate: { $gte: now }
        }),
      ]);

      stats = { totalBookings, completedSessions, upcomingSessions };
    } else if (userRole === 'student') {
      const [totalBookings, completedSessions, upcomingSessions] = await Promise.all([
        Booking.countDocuments({ studentId: userId }),
        Booking.countDocuments({ studentId: userId, status: 'completed' }),
        Booking.countDocuments({ 
          studentId: userId, 
          status: { $in: ['confirmed', 'pending'] },
          sessionDate: { $gte: now }
        }),
      ]);

      stats = { totalBookings, completedSessions, upcomingSessions };
    }

    res.json({ success: true, data: stats });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
