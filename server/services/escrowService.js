const Booking = require('../models/Booking');
const notificationService = require('./notificationService');
const cron = require('node-cron');

class EscrowService {
  constructor() {
    // Escrow configuration (can be overridden by environment variables)
    this.config = {
      // Release delay after session completion (in minutes for testing, hours for production)
      releaseDelayMinutes: parseInt(process.env.ESCROW_RELEASE_DELAY_MINUTES) || 10, // Default 10 minutes for testing
      
      // Cancellation refund rules (hours before session)
      // For testing: 1 hour threshold (production: 24 hours)
      refundRules: {
        full: parseInt(process.env.ESCROW_REFUND_FULL_HOURS) || 1,      // 100% refund if cancelled 1+ hours before (testing)
        partial: parseInt(process.env.ESCROW_REFUND_PARTIAL_HOURS) || 0.5, // 50% refund if cancelled 0.5-1 hours before (testing)
        partialPercentage: parseInt(process.env.ESCROW_REFUND_PARTIAL_PERCENT) || 50, // 50% refund
        none: parseInt(process.env.ESCROW_REFUND_NONE_HOURS) || 0.5        // 0% refund if less than 0.5 hours (30 min) before
      },
      
      // Scheduler frequency (in minutes)
      schedulerFrequency: parseInt(process.env.ESCROW_SCHEDULER_FREQUENCY) || 5 // Check every 5 minutes for testing
    };
    
    console.log('⚙️ Escrow Service Configuration:', this.config);
    console.log(`   Dispute window: ${this.config.releaseDelayMinutes} minutes`);
    console.log(`   Scheduler runs every: ${this.config.schedulerFrequency} minutes`);
    this.startScheduler();
  }

  // Start the escrow release scheduler
  startScheduler() {
    // Run every X minutes (configurable for testing)
    const cronExpression = `*/${this.config.schedulerFrequency} * * * *`;
    
    cron.schedule(cronExpression, async () => {
      console.log('🔄 Running escrow release check...');
      await this.processScheduledReleases();
    });

    console.log(`✅ Escrow scheduler started (runs every ${this.config.schedulerFrequency} minutes)`);
  }

  // Process all scheduled escrow releases
  async processScheduledReleases() {
    try {
      const now = new Date();

      // Find bookings with escrow ready to be released
      const bookings = await Booking.find({
        'escrow.status': 'held',
        'escrow.releaseScheduledFor': { $lte: now },
        'escrow.autoReleaseEnabled': true,
        status: 'completed'
      }).populate('tutorId', 'firstName lastName email');

      console.log(`📦 Found ${bookings.length} escrow releases to process`);

      for (const booking of bookings) {
        try {
          await this.releaseEscrow(booking);
          console.log(`✅ Released escrow for booking ${booking._id}`);
        } catch (error) {
          console.error(`❌ Failed to release escrow for booking ${booking._id}:`, error);
        }
      }

      return {
        success: true,
        processed: bookings.length
      };
    } catch (error) {
      console.error('Escrow release processing error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Release escrow for a specific booking
  async releaseEscrow(booking) {
    try {
      // Release the escrow
      await booking.releaseEscrow();

      // Notify tutor about payment
      await notificationService.notifyPaymentReceived({
        userId: booking.tutorId._id || booking.tutorId,
        amount: `ETB ${booking.tutorEarnings}`,
        bookingId: booking._id
      });

      // In a real implementation, trigger actual payout here
      // Examples:
      // - Stripe transfer to tutor's connected account
      // - Bank transfer via payment gateway
      // - Add to tutor's wallet balance for withdrawal

      console.log(`💰 Escrow released: ETB ${booking.tutorEarnings} to tutor ${booking.tutorId._id}`);

      return {
        success: true,
        bookingId: booking._id,
        amount: booking.tutorEarnings
      };
    } catch (error) {
      console.error('Release escrow error:', error);
      throw error;
    }
  }

  // Manual escrow release (for admin or dispute resolution)
  async manualRelease(bookingId, adminId, reason) {
    try {
      const booking = await Booking.findById(bookingId)
        .populate('tutorId', 'firstName lastName email');

      if (!booking) {
        throw new Error('Booking not found');
      }

      if (booking.escrow.status !== 'held') {
        throw new Error('Escrow is not in held status');
      }

      // Release escrow
      await this.releaseEscrow(booking);

      // Log the manual release
      console.log(`🔓 Manual escrow release by admin ${adminId} for booking ${bookingId}. Reason: ${reason}`);

      return {
        success: true,
        bookingId: booking._id,
        amount: booking.tutorEarnings,
        releasedBy: adminId,
        reason
      };
    } catch (error) {
      console.error('Manual release error:', error);
      throw error;
    }
  }

  // Hold escrow for a booking (called after payment)
  async holdEscrow(bookingId) {
    try {
      const booking = await Booking.findById(bookingId);

      if (!booking) {
        throw new Error('Booking not found');
      }

      await booking.holdInEscrow();

      console.log(`🔒 Escrow held for booking ${bookingId}: ETB ${booking.totalAmount}`);

      return {
        success: true,
        bookingId: booking._id,
        amount: booking.totalAmount,
        heldAt: booking.escrow.heldAt
      };
    } catch (error) {
      console.error('Hold escrow error:', error);
      throw error;
    }
  }

  // Calculate refund amount based on cancellation timing
  calculateRefundAmount(booking) {
    const now = new Date();
    const sessionDateTime = new Date(booking.sessionDate);
    const [hours, minutes] = booking.startTime.split(':');
    sessionDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);

    // Calculate hours until session
    const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);

    let refundPercentage = 0;
    let refundReason = '';

    if (hoursUntilSession >= this.config.refundRules.full) {
      // Full refund (100%)
      refundPercentage = 100;
      refundReason = `Cancelled ${Math.floor(hoursUntilSession)} hours before session`;
    } else if (hoursUntilSession >= this.config.refundRules.partial) {
      // Partial refund (50% or configured percentage)
      refundPercentage = this.config.refundRules.partialPercentage;
      refundReason = `Cancelled ${Math.floor(hoursUntilSession)} hours before session`;
    } else if (hoursUntilSession >= 0) {
      // No refund (less than 12 hours before session)
      refundPercentage = 0;
      refundReason = `Cancelled less than ${this.config.refundRules.none} hours before session`;
    } else {
      // Session already passed - no refund
      refundPercentage = 0;
      refundReason = 'Session time has passed';
    }

    const refundAmount = (booking.totalAmount * refundPercentage) / 100;
    const platformFeeRetained = booking.totalAmount - refundAmount;

    return {
      refundAmount,
      refundPercentage,
      platformFeeRetained,
      hoursUntilSession: Math.max(0, hoursUntilSession),
      refundReason,
      eligible: refundPercentage > 0
    };
  }

  // Refund escrow (for cancelled bookings with refund rules)
  async refundEscrow(bookingId, reason) {
    try {
      const booking = await Booking.findById(bookingId)
        .populate('studentId', 'firstName lastName email')
        .populate('tutorId', 'firstName lastName email');

      if (!booking) {
        throw new Error('Booking not found');
      }

      if (booking.escrow.status !== 'held') {
        throw new Error('Escrow is not in held status');
      }

      // Calculate refund amount based on cancellation timing
      const refundCalculation = this.calculateRefundAmount(booking);

      // Update booking with refund information
      booking.refundAmount = refundCalculation.refundAmount;
      booking.refundReason = reason || refundCalculation.refundReason;
      booking.refundStatus = refundCalculation.refundAmount > 0 ? 'processing' : 'none';
      
      // Update payment status
      if (refundCalculation.refundPercentage === 100) {
        booking.payment.status = 'refunded';
        booking.paymentStatus = 'refunded';
      } else if (refundCalculation.refundPercentage > 0) {
        booking.payment.status = 'partially_refunded';
        booking.paymentStatus = 'partially_refunded';
      }

      // Update escrow status
      booking.escrow.status = 'refunded';
      booking.escrow.releasedAt = new Date();
      await booking.save();

      // If partial refund, release remaining amount to tutor
      if (refundCalculation.refundPercentage > 0 && refundCalculation.refundPercentage < 100) {
        const tutorAmount = booking.tutorEarnings * (1 - refundCalculation.refundPercentage / 100);
        
        // Update tutor balance (move from pending to available)
        const TutorProfile = require('../models/TutorProfile');
        const tutorProfile = await TutorProfile.findById(booking.tutorProfileId);
        if (tutorProfile) {
          tutorProfile.balance.pending -= booking.tutorEarnings;
          tutorProfile.balance.available += tutorAmount;
          await tutorProfile.save();
        }

        // Notify tutor about partial payment
        await notificationService.createNotification({
          userId: booking.tutorId._id,
          type: 'payment_received',
          title: 'Partial Payment Received',
          body: `You received ETB ${tutorAmount.toFixed(2)} for cancelled session (${refundCalculation.refundPercentage}% refunded to student)`,
          data: { bookingId: booking._id, amount: tutorAmount },
          priority: 'normal'
        });
      } else if (refundCalculation.refundPercentage === 0) {
        // No refund - release full amount to tutor
        await this.releaseEscrow(booking);
      }

      // Notify student about refund
      if (refundCalculation.refundAmount > 0) {
        await notificationService.createNotification({
          userId: booking.studentId._id,
          type: 'payment_refunded',
          title: refundCalculation.refundPercentage === 100 ? 'Full Refund Processed' : 'Partial Refund Processed',
          body: `ETB ${refundCalculation.refundAmount.toFixed(2)} (${refundCalculation.refundPercentage}%) has been refunded to your account.`,
          data: { 
            bookingId: booking._id, 
            reason: refundCalculation.refundReason,
            refundAmount: refundCalculation.refundAmount,
            refundPercentage: refundCalculation.refundPercentage
          },
          priority: 'high'
        });
      } else {
        await notificationService.createNotification({
          userId: booking.studentId._id,
          type: 'cancellation_no_refund',
          title: 'Booking Cancelled - No Refund',
          body: `Your booking was cancelled less than ${this.config.refundRules.none} hours before the session. No refund is available.`,
          data: { 
            bookingId: booking._id, 
            reason: refundCalculation.refundReason
          },
          priority: 'normal'
        });
      }

      // In a real implementation, process actual refund here
      // Examples:
      // - Stripe refund
      // - Chapa refund
      // - Add to student's wallet balance

      console.log(`💸 Escrow refunded: ETB ${refundCalculation.refundAmount} (${refundCalculation.refundPercentage}%) to student ${booking.studentId._id}`);
      console.log(`   Platform retained: ETB ${refundCalculation.platformFeeRetained}`);

      return {
        success: true,
        bookingId: booking._id,
        refundAmount: refundCalculation.refundAmount,
        refundPercentage: refundCalculation.refundPercentage,
        platformFeeRetained: refundCalculation.platformFeeRetained,
        refundedAt: booking.escrow.releasedAt,
        refundReason: refundCalculation.refundReason
      };
    } catch (error) {
      console.error('Refund escrow error:', error);
      throw error;
    }
  }

  // Get escrow statistics
  async getEscrowStats() {
    try {
      const held = await Booking.aggregate([
        { $match: { 'escrow.status': 'held' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' }, count: { $sum: 1 } } }
      ]);

      const released = await Booking.aggregate([
        { $match: { 'escrow.status': 'released' } },
        { $group: { _id: null, total: { $sum: '$tutorEarnings' }, count: { $sum: 1 } } }
      ]);

      const refunded = await Booking.aggregate([
        { $match: { 'escrow.status': 'refunded' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' }, count: { $sum: 1 } } }
      ]);

      return {
        held: {
          amount: held[0]?.total || 0,
          count: held[0]?.count || 0
        },
        released: {
          amount: released[0]?.total || 0,
          count: released[0]?.count || 0
        },
        refunded: {
          amount: refunded[0]?.total || 0,
          count: refunded[0]?.count || 0
        }
      };
    } catch (error) {
      console.error('Get escrow stats error:', error);
      throw error;
    }
  }
}

module.exports = new EscrowService();
