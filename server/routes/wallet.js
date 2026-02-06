const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// Get wallet balance
router.get('/balance', walletController.getWalletBalance);

// Initialize wallet top-up
router.post('/topup', walletController.initializeTopUp);

// Verify wallet top-up
router.get('/topup/verify/:reference', walletController.verifyTopUp);

// Get wallet transactions
router.get('/transactions', walletController.getTransactions);

// Get wallet statistics
router.get('/statistics', walletController.getStatistics);

// Check sufficient balance
router.get('/check-balance', walletController.checkBalance);

// Request withdrawal (tutors only)
router.post('/withdraw', walletController.requestWithdrawal);

// Get withdrawal history
router.get('/withdrawals', walletController.getWithdrawals);

// Pay for booking with wallet
router.post('/pay-booking', walletController.payBookingWithWallet);

module.exports = router;
