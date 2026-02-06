const walletService = require('../services/walletService');
const chapaService = require('../services/chapaService');
const notificationService = require('../services/notificationService');

// Get wallet balance
exports.getWalletBalance = async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await walletService.getWalletBalance(userId);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Get wallet balance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch wallet balance',
      error: error.message
    });
  }
};

// Initialize wallet top-up
exports.initializeTopUp = async (req, res) => {
  try {
    const { amount } = req.body;
    const userId = req.user.userId;
    const user = req.user;

    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount'
      });
    }

    const minTopUp = parseFloat(process.env.WALLET_MIN_TOPUP || '10');
    const maxTopUp = parseFloat(process.env.WALLET_MAX_TOPUP || '10000');

    if (amount < minTopUp) {
      return res.status(400).json({
        success: false,
        message: `Minimum top-up amount is ${minTopUp} ETB`
      });
    }

    if (amount > maxTopUp) {
      return res.status(400).json({
        success: false,
        message: `Maximum top-up amount is ${maxTopUp} ETB`
      });
    }

    // Generate transaction reference
    const txRef = chapaService.generateTxRef('wallet_topup');

    // Initialize Chapa payment
    const chapaResult = await chapaService.initializePayment({
      amount,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      txRef,
      bookingId: userId, // Use userId for wallet top-ups
      customization: {
        title: 'Wallet Top-Up',
        description: `Add ${amount} ETB to your wallet`,
        logo: ''
      }
    });

    if (chapaResult.success) {
      return res.status(200).json({
        success: true,
        message: 'Top-up initialized successfully',
        data: {
          checkoutUrl: chapaResult.data.checkoutUrl,
          reference: txRef,
          amount
        }
      });
    } else {
      return res.status(400).json({
        success: false,
        message: chapaResult.error
      });
    }
  } catch (error) {
    console.error('Initialize top-up error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to initialize top-up',
      error: error.message
    });
  }
};

// Verify wallet top-up (called by webhook or manually)
exports.verifyTopUp = async (req, res) => {
  try {
    const { reference } = req.params;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: 'Payment reference is required'
      });
    }

    // Verify payment with Chapa
    const chapaResult = await chapaService.verifyPayment(reference);

    if (!chapaResult.success) {
      return res.status(400).json({
        success: false,
        message: chapaResult.error
      });
    }

    const paymentData = chapaResult.data;

    // Check if payment is successful
    if (paymentData.status !== 'success') {
      return res.status(400).json({
        success: false,
        message: 'Payment not successful'
      });
    }

    // Extract userId from reference or booking_id
    // For wallet top-ups, we stored userId in bookingId field
    const userId = req.user?.userId || req.body.userId;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID not found'
      });
    }

    // Add balance to wallet
    const walletResult = await walletService.addBalance(userId, paymentData.amount, {
      description: 'Wallet top-up via Chapa',
      chapaReference: reference,
      chapaTransactionId: paymentData.transactionId,
      metadata: {
        email: paymentData.email,
        firstName: paymentData.firstName,
        lastName: paymentData.lastName
      }
    });

    if (walletResult.success) {
      // Send notification
      await notificationService.createNotification({
        userId,
        type: 'payment_received',
        title: 'Wallet Top-Up Successful',
        body: `Your wallet has been credited with ${paymentData.amount} ETB`,
        data: {
          amount: paymentData.amount,
          reference
        }
      });

      return res.status(200).json({
        success: true,
        message: 'Wallet top-up successful',
        data: {
          balance: walletResult.data.wallet.balance,
          amount: paymentData.amount,
          transaction: walletResult.data.transaction
        }
      });
    } else {
      return res.status(400).json({
        success: false,
        message: walletResult.error
      });
    }
  } catch (error) {
    console.error('Verify top-up error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to verify top-up',
      error: error.message
    });
  }
};

// Webhook handler for wallet top-ups
exports.topUpWebhook = async (req, res) => {
  try {
    const signature = req.headers['chapa-signature'];
    const payload = req.body;

    console.log('📥 Wallet top-up webhook received:', payload);

    // Process webhook
    const result = await chapaService.processWebhook(payload, signature);

    if (result.success && result.event === 'payment_success') {
      const { reference, amount } = result.data;

      // Extract userId from the transaction
      // You may need to store reference-to-userId mapping in database
      // For now, we'll handle this in the verify endpoint

      console.log('✅ Wallet top-up webhook processed:', reference);
    }

    // Always return 200 to acknowledge webhook
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Wallet webhook error:', error);
    return res.status(200).json({ success: true }); // Still acknowledge
  }
};

// Get wallet transactions
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

    const result = await walletService.getWalletTransactions(userId, filters);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Get transactions error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch transactions',
      error: error.message
    });
  }
};

// Get wallet statistics
exports.getStatistics = async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await walletService.getWalletStatistics(userId);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Get statistics error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message
    });
  }
};

// Check sufficient balance
exports.checkBalance = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { amount } = req.query;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount'
      });
    }

    const result = await walletService.checkSufficientBalance(userId, parseFloat(amount));

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Check balance error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to check balance',
      error: error.message
    });
  }
};

// Request withdrawal (for tutors)
exports.requestWithdrawal = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { amount, accountNumber, accountName, bankName } = req.body;

    // Validate inputs
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount'
      });
    }

    if (!accountNumber || !accountName || !bankName) {
      return res.status(400).json({
        success: false,
        message: 'Bank account details are required'
      });
    }

    const minWithdrawal = parseFloat(process.env.WALLET_MIN_WITHDRAWAL || '50');
    const maxWithdrawal = parseFloat(process.env.WALLET_MAX_WITHDRAWAL || '50000');

    if (amount < minWithdrawal) {
      return res.status(400).json({
        success: false,
        message: `Minimum withdrawal amount is ${minWithdrawal} ETB`
      });
    }

    if (amount > maxWithdrawal) {
      return res.status(400).json({
        success: false,
        message: `Maximum withdrawal amount is ${maxWithdrawal} ETB`
      });
    }

    // Check balance
    const balanceCheck = await walletService.checkSufficientBalance(userId, amount);
    
    if (!balanceCheck.success || !balanceCheck.data.hasSufficientBalance) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient balance',
        data: balanceCheck.data
      });
    }

    // Deduct from wallet
    const deductResult = await walletService.deductBalance(
      userId,
      amount,
      'Withdrawal request',
      { accountNumber, accountName, bankName }
    );

    if (!deductResult.success) {
      return res.status(400).json({
        success: false,
        message: deductResult.error
      });
    }

    // Process withdrawal with Chapa (or manual)
    const reference = chapaService.generateTxRef('withdrawal');
    const withdrawalResult = await chapaService.processWithdrawal({
      amount,
      accountNumber,
      accountName,
      bankName,
      reference
    });

    if (withdrawalResult.success) {
      // Send notification
      await notificationService.createNotification({
        userId,
        type: 'payment_pending',
        title: 'Withdrawal Request Submitted',
        body: `Your withdrawal request for ${amount} ETB is being processed`,
        data: {
          amount,
          reference
        }
      });

      return res.status(200).json({
        success: true,
        message: 'Withdrawal request submitted successfully',
        data: {
          amount,
          reference,
          status: 'processing',
          transaction: deductResult.data.transaction
        }
      });
    } else {
      // Refund to wallet if withdrawal failed
      await walletService.addBalance(userId, amount, {
        description: 'Withdrawal failed - refund',
        metadata: { originalReference: reference }
      });

      return res.status(400).json({
        success: false,
        message: withdrawalResult.error
      });
    }
  } catch (error) {
    console.error('Request withdrawal error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process withdrawal request',
      error: error.message
    });
  }
};

// Get withdrawal history
exports.getWithdrawals = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { status, limit } = req.query;

    const filters = {
      type: 'withdrawal'
    };
    
    if (status) filters.status = status;
    if (limit) filters.limit = parseInt(limit);

    const result = await walletService.getWalletTransactions(userId, filters);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }
  } catch (error) {
    console.error('Get withdrawals error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch withdrawals',
      error: error.message
    });
  }
};


// Pay for booking using wallet
exports.payBookingWithWallet = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const userId = req.user.userId;

    if (!bookingId) {
      return res.status(400).json({
        success: false,
        message: 'Booking ID is required'
      });
    }

    const Booking = require('../models/Booking');
    const booking = await Booking.findById(bookingId);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Verify user is the student
    if (booking.studentId.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized'
      });
    }

    // Check if already paid
    if (booking.payment?.status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Booking already paid'
      });
    }

    const amount = booking.payment?.amount || booking.amount;

    // Check sufficient balance
    const balanceCheck = await walletService.checkSufficientBalance(userId, amount);
    
    if (!balanceCheck.success || !balanceCheck.data.hasSufficientBalance) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient wallet balance',
        data: {
          required: amount,
          available: balanceCheck.data?.currentBalance || 0,
          shortfall: balanceCheck.data?.shortfall || amount
        }
      });
    }

    // Move balance to escrow
    const escrowResult = await walletService.moveToEscrow(
      userId,
      amount,
      bookingId,
      `Payment for booking ${bookingId}`
    );

    if (!escrowResult.success) {
      return res.status(400).json({
        success: false,
        message: escrowResult.error
      });
    }

    // Update booking payment status
    booking.payment = {
      method: 'wallet',
      status: 'paid',
      amount: amount,
      paidAt: new Date(),
      walletTransactionId: escrowResult.data.transaction._id
    };
    booking.status = 'confirmed';
    booking.paymentStatus = 'paid';
    await booking.save();

    // Update availability slot status
    const AvailabilitySlot = require('../models/AvailabilitySlot');
    const slot = await AvailabilitySlot.findById(booking.slotId);
    if (slot) {
      slot.status = 'booked';
      if (slot.booking) {
        slot.booking.status = 'confirmed';
      }
      await slot.save();
    }

    // Send notifications
    await notificationService.createNotification({
      userId: booking.tutorId,
      type: 'booking_accepted',
      title: 'Booking Confirmed',
      body: `Your session has been confirmed and paid`,
      data: {
        bookingId: booking._id,
        amount
      }
    });

    await notificationService.createNotification({
      userId,
      type: 'payment_received',
      title: 'Payment Successful',
      body: `Payment of ${amount} ETB completed successfully`,
      data: {
        bookingId: booking._id,
        amount
      }
    });

    return res.status(200).json({
      success: true,
      message: 'Booking paid successfully with wallet',
      data: {
        bookingId: booking._id,
        amount,
        paymentMethod: 'wallet',
        status: 'confirmed',
        wallet: {
          balance: escrowResult.data.wallet.balance,
          escrowBalance: escrowResult.data.wallet.escrowBalance
        },
        transaction: escrowResult.data.transaction
      }
    });
  } catch (error) {
    console.error('Pay booking with wallet error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process wallet payment',
      error: error.message
    });
  }
};
