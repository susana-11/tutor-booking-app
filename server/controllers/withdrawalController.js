const paymentService = require('../services/paymentService');
const TutorProfile = require('../models/TutorProfile');
const Transaction = require('../models/Transaction');

// Request withdrawal
exports.requestWithdrawal = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid amount is required'
      });
    }

    // Minimum withdrawal amount
    const minWithdrawal = parseFloat(process.env.MIN_WITHDRAWAL_AMOUNT || '100');
    if (amount < minWithdrawal) {
      return res.status(400).json({
        success: false,
        message: `Minimum withdrawal amount is ETB ${minWithdrawal}`
      });
    }

    const result = await paymentService.processWithdrawal(userId, amount);

    if (result.success) {
      return res.status(200).json({
        success: true,
        message: 'Withdrawal processed successfully',
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Request withdrawal error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process withdrawal',
      error: error.message
    });
  }
};

// Get withdrawal history
exports.getWithdrawals = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { status, limit } = req.query;

    const filters = { type: 'withdrawal' };
    if (status) filters.status = status;
    if (limit) filters.limit = parseInt(limit);

    const withdrawals = await Transaction.getUserTransactions(userId, filters);

    return res.status(200).json({
      success: true,
      data: withdrawals
    });
  } catch (error) {
    console.error('Get withdrawals error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch withdrawals',
      error: error.message
    });
  }
};

// Get tutor balance
exports.getBalance = async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await paymentService.getTutorBalance(userId);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(404).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Get balance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch balance',
      error: error.message
    });
  }
};

// Update bank account
exports.updateBankAccount = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { accountNumber, accountName, bankName } = req.body;

    if (!accountNumber || !accountName || !bankName) {
      return res.status(400).json({
        success: false,
        message: 'All bank account fields are required'
      });
    }

    const tutorProfile = await TutorProfile.findOne({ userId });

    if (!tutorProfile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    tutorProfile.bankAccount = {
      accountNumber,
      accountName,
      bankName,
      isVerified: false // Will be verified by admin or automated process
    };

    await tutorProfile.save();

    return res.status(200).json({
      success: true,
      message: 'Bank account updated successfully',
      data: {
        accountNumber: tutorProfile.bankAccount.accountNumber,
        accountName: tutorProfile.bankAccount.accountName,
        bankName: tutorProfile.bankAccount.bankName,
        isVerified: tutorProfile.bankAccount.isVerified
      }
    });
  } catch (error) {
    console.error('Update bank account error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update bank account',
      error: error.message
    });
  }
};

// Get bank account
exports.getBankAccount = async (req, res) => {
  try {
    const userId = req.user.userId;

    const tutorProfile = await TutorProfile.findOne({ userId });

    if (!tutorProfile) {
      return res.status(404).json({
        success: false,
        message: 'Tutor profile not found'
      });
    }

    if (!tutorProfile.bankAccount || !tutorProfile.bankAccount.accountNumber) {
      return res.status(404).json({
        success: false,
        message: 'Bank account not set up'
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        accountNumber: tutorProfile.bankAccount.accountNumber,
        accountName: tutorProfile.bankAccount.accountName,
        bankName: tutorProfile.bankAccount.bankName,
        isVerified: tutorProfile.bankAccount.isVerified
      }
    });
  } catch (error) {
    console.error('Get bank account error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch bank account',
      error: error.message
    });
  }
};

// Get withdrawal fees info
exports.getWithdrawalFees = async (req, res) => {
  try {
    const { amount } = req.query;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid amount is required'
      });
    }

    const chapaService = require('../services/chapaService');
    const fees = chapaService.calculateFees(parseFloat(amount));

    return res.status(200).json({
      success: true,
      data: {
        amount: parseFloat(amount),
        platformFee: fees.platformFee,
        platformFeePercentage: fees.platformFeePercentage,
        netAmount: fees.tutorShare
      }
    });
  } catch (error) {
    console.error('Get withdrawal fees error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to calculate fees',
      error: error.message
    });
  }
};
