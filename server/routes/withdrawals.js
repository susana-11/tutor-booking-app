const express = require('express');
const { authenticate } = require('../middleware/auth');
const withdrawalController = require('../controllers/withdrawalController');

const router = express.Router();

// Request withdrawal
router.post('/request', authenticate, withdrawalController.requestWithdrawal);

// Get withdrawal history
router.get('/', authenticate, withdrawalController.getWithdrawals);

// Get tutor balance
router.get('/balance', authenticate, withdrawalController.getBalance);

// Update bank account
router.put('/bank-account', authenticate, withdrawalController.updateBankAccount);

// Get bank account
router.get('/bank-account', authenticate, withdrawalController.getBankAccount);

// Get withdrawal fees calculation
router.get('/fees', authenticate, withdrawalController.getWithdrawalFees);

module.exports = router;
