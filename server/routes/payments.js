const express = require('express');
const { authenticate } = require('../middleware/auth');
const paymentController = require('../controllers/paymentController');

const router = express.Router();

// Initialize payment for booking
router.post('/initialize', authenticate, paymentController.initializePayment);

// Verify payment
router.get('/verify/:reference', authenticate, paymentController.verifyPayment);

// Chapa webhook (no auth required)
router.post('/webhook', paymentController.chapaWebhook);

// Payment callback (no auth required)
router.get('/callback', paymentController.paymentCallback);

// Payment success redirect (no auth required)
router.get('/success', (req, res) => {
  res.send('<h1>Payment Successful!</h1><p>You can close this window.</p>');
});

// Get transaction history
router.get('/transactions', authenticate, paymentController.getTransactions);

// Get transaction summary
router.get('/transactions/summary', authenticate, paymentController.getTransactionSummary);

// Get payment status for booking
router.get('/status/:bookingId', authenticate, paymentController.getPaymentStatus);

module.exports = router;