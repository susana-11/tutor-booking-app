const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

class WalletService {
  // Get or create wallet for user
  async getOrCreateWallet(userId) {
    try {
      let wallet = await Wallet.findOne({ userId });
      
      if (!wallet) {
        wallet = await Wallet.create({ userId });
        console.log(`✅ Created new wallet for user ${userId}`);
      }
      
      return {
        success: true,
        data: wallet
      };
    } catch (error) {
      console.error('Get or create wallet error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Get wallet balance
  async getWalletBalance(userId) {
    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      return {
        success: true,
        data: {
          balance: wallet.balance,
          escrowBalance: wallet.escrowBalance,
          availableBalance: wallet.availableBalance,
          totalBalance: wallet.totalBalance,
          currency: wallet.currency,
          isFrozen: wallet.isFrozen
        }
      };
    } catch (error) {
      console.error('Get wallet balance error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Add balance to wallet (after successful top-up)
  async addBalance(userId, amount, transactionData = {}) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const wallet = await Wallet.getOrCreate(userId);
      const balanceBefore = wallet.balance;

      // Add balance to wallet
      await wallet.addBalance(amount, transactionData.description || 'Wallet top-up');

      // Create transaction record
      const transaction = await Transaction.create([{
        userId,
        walletId: wallet._id,
        type: 'wallet_topup',
        amount,
        netAmount: amount,
        status: 'completed',
        description: transactionData.description || 'Wallet top-up via Chapa',
        chapaReference: transactionData.chapaReference,
        chapaTransactionId: transactionData.chapaTransactionId,
        balanceBefore,
        balanceAfter: wallet.balance,
        metadata: transactionData.metadata || {},
        paidAt: new Date()
      }], { session });

      await session.commitTransaction();

      console.log(`✅ Added ${amount} ETB to wallet for user ${userId}`);

      return {
        success: true,
        data: {
          wallet,
          transaction: transaction[0]
        }
      };
    } catch (error) {
      await session.abortTransaction();
      console.error('Add balance error:', error);
      return {
        success: false,
        error: error.message
      };
    } finally {
      session.endSession();
    }
  }

  // Deduct balance from wallet (for booking)
  async deductBalance(userId, amount, description, metadata = {}) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      if (!wallet.hasSufficientBalance(amount)) {
        throw new Error('Insufficient wallet balance');
      }

      const balanceBefore = wallet.balance;

      // Deduct balance
      await wallet.deductBalance(amount, description);

      // Create transaction record
      const transaction = await Transaction.create([{
        userId,
        walletId: wallet._id,
        type: 'wallet_deduction',
        amount,
        netAmount: amount,
        status: 'completed',
        description,
        balanceBefore,
        balanceAfter: wallet.balance,
        bookingId: metadata.bookingId,
        metadata,
        processedAt: new Date()
      }], { session });

      await session.commitTransaction();

      console.log(`✅ Deducted ${amount} ETB from wallet for user ${userId}`);

      return {
        success: true,
        data: {
          wallet,
          transaction: transaction[0]
        }
      };
    } catch (error) {
      await session.abortTransaction();
      console.error('Deduct balance error:', error);
      return {
        success: false,
        error: error.message
      };
    } finally {
      session.endSession();
    }
  }

  // Move balance to escrow (for booking)
  async moveToEscrow(userId, amount, bookingId, description) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      if (!wallet.hasSufficientBalance(amount)) {
        throw new Error('Insufficient wallet balance');
      }

      const balanceBefore = wallet.balance;
      const escrowBefore = wallet.escrowBalance;

      // Move to escrow
      await wallet.moveToEscrow(amount, description);

      // Create transaction record
      const transaction = await Transaction.create([{
        userId,
        walletId: wallet._id,
        type: 'escrow_hold',
        amount,
        netAmount: amount,
        status: 'completed',
        description,
        bookingId,
        balanceBefore,
        balanceAfter: wallet.balance,
        metadata: {
          escrowBefore,
          escrowAfter: wallet.escrowBalance
        },
        processedAt: new Date()
      }], { session });

      await session.commitTransaction();

      console.log(`✅ Moved ${amount} ETB to escrow for booking ${bookingId}`);

      return {
        success: true,
        data: {
          wallet,
          transaction: transaction[0]
        }
      };
    } catch (error) {
      await session.abortTransaction();
      console.error('Move to escrow error:', error);
      return {
        success: false,
        error: error.message
      };
    } finally {
      session.endSession();
    }
  }

  // Release from escrow to tutor (after session completion)
  async releaseFromEscrow(studentUserId, tutorUserId, amount, bookingId, description) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Get student wallet (has escrow)
      const studentWallet = await Wallet.getOrCreate(studentUserId);
      
      if (studentWallet.escrowBalance < amount) {
        throw new Error('Insufficient escrow balance');
      }

      // Get or create tutor wallet
      const tutorWallet = await Wallet.getOrCreate(tutorUserId);

      const studentEscrowBefore = studentWallet.escrowBalance;
      const tutorBalanceBefore = tutorWallet.balance;

      // Release from student escrow
      studentWallet.escrowBalance -= amount;
      await studentWallet.save({ session });

      // Add to tutor balance
      await tutorWallet.addBalance(amount, description);

      // Create transaction records
      const transactions = await Transaction.create([
        // Student escrow release
        {
          userId: studentUserId,
          walletId: studentWallet._id,
          type: 'escrow_release',
          amount,
          netAmount: amount,
          status: 'completed',
          description: `Escrow released for ${description}`,
          bookingId,
          metadata: {
            escrowBefore: studentEscrowBefore,
            escrowAfter: studentWallet.escrowBalance,
            releasedTo: tutorUserId
          },
          processedAt: new Date()
        },
        // Tutor earnings
        {
          userId: tutorUserId,
          walletId: tutorWallet._id,
          type: 'wallet_topup',
          amount,
          netAmount: amount,
          status: 'completed',
          description: `Earnings from ${description}`,
          bookingId,
          balanceBefore: tutorBalanceBefore,
          balanceAfter: tutorWallet.balance,
          metadata: {
            receivedFrom: studentUserId
          },
          paidAt: new Date()
        }
      ], { session });

      await session.commitTransaction();

      console.log(`✅ Released ${amount} ETB from escrow to tutor ${tutorUserId}`);

      return {
        success: true,
        data: {
          studentWallet,
          tutorWallet,
          transactions
        }
      };
    } catch (error) {
      await session.abortTransaction();
      console.error('Release from escrow error:', error);
      return {
        success: false,
        error: error.message
      };
    } finally {
      session.endSession();
    }
  }

  // Refund from escrow to student wallet
  async refundFromEscrow(userId, amount, bookingId, description) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      if (wallet.escrowBalance < amount) {
        throw new Error('Insufficient escrow balance');
      }

      const escrowBefore = wallet.escrowBalance;
      const balanceBefore = wallet.balance;

      // Refund from escrow
      await wallet.refundFromEscrow(amount, description);

      // Create transaction record
      const transaction = await Transaction.create([{
        userId,
        walletId: wallet._id,
        type: 'wallet_refund',
        amount,
        netAmount: amount,
        status: 'completed',
        description,
        bookingId,
        balanceBefore,
        balanceAfter: wallet.balance,
        metadata: {
          escrowBefore,
          escrowAfter: wallet.escrowBalance,
          refundType: 'escrow_refund'
        },
        processedAt: new Date()
      }], { session });

      await session.commitTransaction();

      console.log(`✅ Refunded ${amount} ETB from escrow to wallet for user ${userId}`);

      return {
        success: true,
        data: {
          wallet,
          transaction: transaction[0]
        }
      };
    } catch (error) {
      await session.abortTransaction();
      console.error('Refund from escrow error:', error);
      return {
        success: false,
        error: error.message
      };
    } finally {
      session.endSession();
    }
  }

  // Check if user has sufficient balance
  async checkSufficientBalance(userId, amount) {
    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      return {
        success: true,
        data: {
          hasSufficientBalance: wallet.hasSufficientBalance(amount),
          currentBalance: wallet.balance,
          requiredAmount: amount,
          shortfall: Math.max(0, amount - wallet.balance)
        }
      };
    } catch (error) {
      console.error('Check sufficient balance error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Get wallet transactions
  async getWalletTransactions(userId, filters = {}) {
    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      const query = { walletId: wallet._id };
      
      if (filters.type) query.type = filters.type;
      if (filters.status) query.status = filters.status;
      if (filters.startDate || filters.endDate) {
        query.createdAt = {};
        if (filters.startDate) query.createdAt.$gte = new Date(filters.startDate);
        if (filters.endDate) query.createdAt.$lte = new Date(filters.endDate);
      }
      
      const transactions = await Transaction.find(query)
        .populate('bookingId', 'sessionDate startTime endTime subject')
        .sort({ createdAt: -1 })
        .limit(filters.limit || 50);

      return {
        success: true,
        data: transactions
      };
    } catch (error) {
      console.error('Get wallet transactions error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Get wallet statistics
  async getWalletStatistics(userId) {
    try {
      const wallet = await Wallet.getOrCreate(userId);
      
      return {
        success: true,
        data: {
          currentBalance: wallet.balance,
          escrowBalance: wallet.escrowBalance,
          totalBalance: wallet.totalBalance,
          totalDeposited: wallet.totalDeposited,
          totalSpent: wallet.totalSpent,
          totalWithdrawn: wallet.totalWithdrawn,
          totalRefunded: wallet.totalRefunded,
          totalEarned: wallet.totalEarned,
          lastTransactionAt: wallet.lastTransactionAt,
          currency: wallet.currency
        }
      };
    } catch (error) {
      console.error('Get wallet statistics error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = new WalletService();
