const chapaService = require('./chapaService');
const escrowService = require('./escrowService');
const Booking = require('../models/Booking');
const Transaction = require('../models/Transaction');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');
const mongoose = require('mongoose');

class PaymentService {
  // Initialize payment for booking
  async initializeBookingPayment(bookingId, userId) {
    try {
      console.log('🔍 Initializing payment for booking:', bookingId, 'User:', userId);
      
      // Validate bookingId format
      if (!bookingId || !mongoose.Types.ObjectId.isValid(bookingId)) {
        console.error('❌ Invalid booking ID format:', bookingId);
        return { success: false, error: 'Invalid booking ID format' };
      }

      const booking = await Booking.findById(bookingId)
        .populate('studentId', 'firstName lastName email')
        .populate('tutorId');

      console.log('📦 Booking found:', booking ? 'Yes' : 'No');
      
      if (!booking) {
        console.error('❌ Booking not found:', bookingId);
        return { success: false, error: 'Booking not found' };
      }

      console.log('👤 Student ID:', booking.studentId?._id, 'Expected:', userId);
      console.log('📧 Student email:', booking.studentId?.email);
      console.log('📧 Student email type:', typeof booking.studentId?.email);
      
      if (!booking.studentId) {
        console.error('❌ Student not found in booking');
        return { success: false, error: 'Student information not found' };
      }
      
      if (!booking.studentId.email) {
        console.error('❌ Student email not found');
        return { success: false, error: 'Student email not found' };
      }
      
      if (booking.studentId._id.toString() !== userId.toString()) {
        return { success: false, error: 'Unauthorized' };
      }

      if (booking.payment?.status === 'paid') {
        return { success: false, error: 'Booking already paid' };
      }

      // Generate transaction reference
      const txRef = chapaService.generateTxRef('booking');

      // Ensure email is a string
      const studentEmail = String(booking.studentId.email).trim();
      const studentFirstName = String(booking.studentId.firstName || 'Student').trim();
      const studentLastName = String(booking.studentId.lastName || '').trim();

      console.log('📧 Sending to Chapa - Email:', studentEmail, 'Name:', studentFirstName, studentLastName);

      // Initialize Chapa payment
      const result = await chapaService.initializePayment({
        amount: booking.totalAmount,
        email: studentEmail,
        firstName: studentFirstName,
        lastName: studentLastName,
        txRef,
        bookingId: booking._id.toString(),
        customization: {
          title: 'Tutor Session',
          description: `${booking.subject?.name || 'Tutoring'} session`
        }
      });

      if (result.success) {
        // Update booking with payment reference
        booking.payment = {
          amount: booking.totalAmount,
          status: 'pending',
          method: 'chapa',
          chapaReference: txRef
        };
        await booking.save();

        // Create transaction record
        // Handle tutorId whether it's populated or just an ObjectId
        const tutorIdString = booking.tutorId?._id 
          ? booking.tutorId._id.toString() 
          : booking.tutorId.toString();

        await Transaction.create({
          userId: booking.studentId._id,
          type: 'payment',
          amount: booking.totalAmount,
          fee: 0,
          netAmount: booking.totalAmount,
          status: 'pending',
          bookingId: booking._id,
          chapaReference: txRef,
          description: `Payment for ${booking.subject?.name || 'tutoring'} session`,
          metadata: {
            tutorId: tutorIdString,
            sessionDate: booking.sessionDate
          }
        });

        return {
          success: true,
          data: {
            checkoutUrl: result.data.checkoutUrl,
            reference: txRef,
            amount: booking.totalAmount
          }
        };
      }

      return result;
    } catch (error) {
      console.error('Payment initialization error:', error);
      return { success: false, error: error.message };
    }
  }

  // Verify and process payment
  async verifyPayment(txRef) {
    try {
      // Verify with Chapa
      const result = await chapaService.verifyPayment(txRef);

      if (!result.success) {
        return result;
      }

      // Find booking and transaction
      const booking = await Booking.findOne({ 'payment.chapaReference': txRef })
        .populate('tutorId');
      const transaction = await Transaction.findOne({ chapaReference: txRef });

      if (!booking || !transaction) {
        return { success: false, error: 'Booking or transaction not found' };
      }

      if (result.data.status === 'success') {
        // Calculate fees
        const fees = chapaService.calculateFees(booking.totalAmount);

        // Update booking payment status
        booking.payment.status = 'paid';
        booking.payment.paidAt = new Date();
        booking.payment.chapaTransactionId = result.data.transactionId;
        booking.payment.tutorShare = fees.tutorShare;
        booking.payment.platformFee = fees.platformFee;
        booking.paymentStatus = 'paid';
        booking.status = 'confirmed';
        
        // Hold payment in escrow using the booking method
        await booking.holdInEscrow();
        
        await booking.save();
        
        const releaseDelayMinutes = booking.escrow.releaseDelayMinutes || 10;
        console.log(`🔒 Payment held in escrow for booking ${booking._id}`);
        console.log(`   Amount: ETB ${fees.tutorShare}`);
        console.log(`   Will be released ${releaseDelayMinutes} minutes after session completion`);

        // Update transaction
        transaction.status = 'completed';
        transaction.paidAt = new Date();
        transaction.chapaTransactionId = result.data.transactionId;
        transaction.chapaStatus = result.data.status;
        await transaction.markCompleted();

        // Update tutor balance - ADD TO PENDING, NOT AVAILABLE!
        const tutorProfileId = booking.tutorProfileId || booking.tutorId?._id || booking.tutorId;
        await this.updateTutorBalance(tutorProfileId, fees.tutorShare, 'add', 'pending');

        // Update tutor profile stats
        const tutorProfile = await TutorProfile.findById(tutorProfileId);
        if (tutorProfile) {
          tutorProfile.stats.totalEarnings += fees.tutorShare;
          await tutorProfile.save();
        }

        // Send notifications to both parties
        const notificationService = require('./notificationService');
        await notificationService.sendBookingConfirmedNotification(booking);

        return {
          success: true,
          data: {
            bookingId: booking._id,
            amount: booking.totalAmount,
            tutorShare: fees.tutorShare,
            platformFee: fees.platformFee,
            status: 'paid',
            escrowStatus: 'held',
            releaseDelayMinutes: releaseDelayMinutes
          }
        };
      } else {
        // Payment failed
        booking.payment.status = 'failed';
        transaction.status = 'failed';
        transaction.failureReason = 'Payment verification failed';
        await booking.save();
        await transaction.save();

        return { success: false, error: 'Payment verification failed' };
      }
    } catch (error) {
      console.error('Payment verification error:', error);
      return { success: false, error: error.message };
    }
  }

  // Process withdrawal
  async processWithdrawal(userId, amount) {
    try {
      // Get tutor profile
      const tutorProfile = await TutorProfile.findOne({ userId })
        .populate('userId', 'firstName lastName email');

      if (!tutorProfile) {
        return { success: false, error: 'Tutor profile not found' };
      }

      // Check if bank account is set up
      if (!tutorProfile.bankAccount || !tutorProfile.bankAccount.accountNumber) {
        return { success: false, error: 'Bank account not set up' };
      }

      // Check available balance
      if (tutorProfile.balance.available < amount) {
        return { success: false, error: 'Insufficient balance' };
      }

      // Calculate withdrawal fee (10%)
      const fees = chapaService.calculateFees(amount);
      const netAmount = amount - fees.platformFee;

      // Generate reference
      const reference = chapaService.generateTxRef('withdrawal');

      // Create transaction record
      const transaction = await Transaction.create({
        userId,
        type: 'withdrawal',
        amount,
        fee: fees.platformFee,
        netAmount,
        status: 'processing',
        chapaReference: reference,
        bankAccount: tutorProfile.bankAccount,
        description: `Withdrawal to ${tutorProfile.bankAccount.bankName}`,
        metadata: {
          accountNumber: tutorProfile.bankAccount.accountNumber,
          accountName: tutorProfile.bankAccount.accountName
        }
      });

      // Process withdrawal with Chapa (or bank API)
      const result = await chapaService.processWithdrawal({
        amount: netAmount,
        accountNumber: tutorProfile.bankAccount.accountNumber,
        accountName: tutorProfile.bankAccount.accountName,
        bankName: tutorProfile.bankAccount.bankName,
        reference
      });

      if (result.success) {
        // Update transaction
        transaction.status = 'completed';
        transaction.processedAt = new Date();
        transaction.chapaTransactionId = result.data.transactionId;
        await transaction.save();

        // Update tutor balance
        await this.updateTutorBalance(tutorProfile._id, amount, 'subtract', 'available');
        await this.updateTutorBalance(tutorProfile._id, amount, 'add', 'withdrawn');

        return {
          success: true,
          data: {
            transactionId: transaction._id,
            amount,
            fee: fees.platformFee,
            netAmount,
            status: 'completed'
          }
        };
      } else {
        // Withdrawal failed
        transaction.status = 'failed';
        transaction.failureReason = result.error;
        await transaction.save();

        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error('Withdrawal processing error:', error);
      return { success: false, error: error.message };
    }
  }

  // Update tutor balance
  async updateTutorBalance(tutorProfileId, amount, operation = 'add', field = 'available') {
    try {
      const tutorProfile = await TutorProfile.findById(tutorProfileId);
      if (!tutorProfile) {
        throw new Error('Tutor profile not found');
      }

      if (operation === 'add') {
        tutorProfile.balance[field] += amount;
        if (field === 'available') {
          tutorProfile.balance.total += amount;
        }
      } else if (operation === 'subtract') {
        tutorProfile.balance[field] -= amount;
      }

      await tutorProfile.save();
      return tutorProfile.balance;
    } catch (error) {
      console.error('Balance update error:', error);
      throw error;
    }
  }

  // Get tutor balance
  async getTutorBalance(userId) {
    try {
      const tutorProfile = await TutorProfile.findOne({ userId });
      if (!tutorProfile) {
        return { success: false, error: 'Tutor profile not found' };
      }

      return {
        success: true,
        data: tutorProfile.balance
      };
    } catch (error) {
      console.error('Get balance error:', error);
      return { success: false, error: error.message };
    }
  }

  // Calculate refund amount based on cancellation policy
  calculateRefundAmount(totalAmount, hoursUntilSession) {
    let refundPercentage = 0;
    
    if (hoursUntilSession >= 48) {
      refundPercentage = 100;
    } else if (hoursUntilSession >= 24) {
      refundPercentage = 50;
    } else {
      refundPercentage = 0;
    }
    
    return {
      refundAmount: (totalAmount * refundPercentage) / 100,
      refundPercentage,
      eligible: refundPercentage > 0,
    };
  }
}

module.exports = new PaymentService();
