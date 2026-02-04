const paymentService = require('../services/paymentService');
const chapaService = require('../services/chapaService');
const escrowService = require('../services/escrowService');
const Transaction = require('../models/Transaction');
const Booking = require('../models/Booking');

// Initialize payment for booking
exports.initializePayment = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const userId = req.user.userId;

    if (!bookingId) {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required'
      });
    }

    const result = await paymentService.initializeBookingPayment(bookingId, userId);

    if (result.success) {
      return res.status(200).json({
        success: true,
        message: 'Payment initialized successfully',
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Initialize payment error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to initialize payment',
      error: error.message
    });
  }
};

// Verify payment
exports.verifyPayment = async (req, res) => {
  try {
    const { reference } = req.params;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: 'Payment reference is required'
      });
    }

    const result = await paymentService.verifyPayment(reference);

    if (result.success) {
      return res.status(200).json({
        success: true,
        message: 'Payment verified successfully',
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Verify payment error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to verify payment',
      error: error.message
    });
  }
};

// Chapa webhook handler
exports.chapaWebhook = async (req, res) => {
  try {
    const signature = req.headers['chapa-signature'];
    const payload = req.body;

    const result = await chapaService.processWebhook(payload, signature);

    if (result.success && result.event === 'payment_success') {
      // Process payment verification
      await paymentService.verifyPayment(result.data.reference);
    }

    // Always return 200 to acknowledge webhook receipt
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(200).json({ success: true }); // Still acknowledge
  }
};

// Payment callback (for redirect after payment)
exports.paymentCallback = async (req, res) => {
  try {
    const { status, tx_ref, booking_id } = req.query;

    if (status === 'success' && tx_ref) {
      // Verify payment
      await paymentService.verifyPayment(tx_ref);
      
      // Redirect to success page (mobile app deep link or web page)
      return res.redirect(`tutorbooking://payment/success?booking_id=${booking_id}&reference=${tx_ref}`);
    } else {
      // Redirect to failure page
      return res.redirect(`tutorbooking://payment/failed?booking_id=${booking_id}`);
    }
  } catch (error) {
    console.error('Payment callback error:', error);
    return res.redirect(`tutorbooking://payment/error`);
  }
};

// Get transaction history
exports.getTransactions = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { type, status, startDate, endDate, limit } = req.query;

    const filters = {};
    if (type) filters.type = type;
    if (status) filters.status = status;
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (limit) filters.limit = parseInt(limit);

    const transactions = await Transaction.getUserTransactions(userId, filters);

    return res.status(200).json({
      success: true,
      data: transactions
    });
  } catch (error) {
    console.error('Get transactions error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch transactions',
      error: error.message
    });
  }
};

// Get transaction summary
exports.getTransactionSummary = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { startDate, endDate } = req.query;

    const start = startDate ? new Date(startDate) : new Date(new Date().setDate(1)); // First day of month
    const end = endDate ? new Date(endDate) : new Date(); // Today

    const summary = await Transaction.getTransactionSummary(userId, start, end);

    return res.status(200).json({
      success: true,
      data: summary
    });
  } catch (error) {
    console.error('Get transaction summary error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch transaction summary',
      error: error.message
    });
  }
};

// Get payment status for booking
exports.getPaymentStatus = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.userId;

    const booking = await Booking.findById(bookingId);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Check authorization
    if (booking.studentId.toString() !== userId && booking.tutorId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized'
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        bookingId: booking._id,
        paymentStatus: booking.payment?.status || booking.paymentStatus,
        amount: booking.payment?.amount || booking.totalAmount,
        paidAt: booking.payment?.paidAt || booking.paidAt,
        method: booking.payment?.method || booking.paymentMethod,
        reference: booking.payment?.chapaReference
      }
    });
  } catch (error) {
    console.error('Get payment status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch payment status',
      error: error.message
    });
  }
};
