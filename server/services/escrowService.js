const Booking = require('../models/Booking');
const notificationService = require('./notificationService');
const cron = require('node-cron');

class EscrowService {
  constructor() {
    this.startScheduler();
  }

  // Start the escrow release scheduler
  startScheduler() {
    // Run every hour
    cron.schedule('0 * * * *', async () => {
      console.log('🔄 Running escrow release check...');
      await this.processScheduledReleases();
    });

    console.log('✅ Escrow scheduler started');
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

  // Refund escrow (for cancelled bookings)
  async refundEscrow(bookingId, reason) {
    try {
      const booking = await Booking.findById(bookingId)
        .populate('studentId', 'firstName lastName email');

      if (!booking) {
        throw new Error('Booking not found');
      }

      if (booking.escrow.status !== 'held') {
        throw new Error('Escrow is not in held status');
      }

      // Update escrow status
      booking.escrow.status = 'refunded';
      booking.escrow.releasedAt = new Date();
      await booking.save();

      // Notify student about refund
      await notificationService.createNotification({
        userId: booking.studentId._id,
        type: 'payment_refunded',
        title: 'Payment Refunded',
        body: `Your payment of ETB ${booking.totalAmount} has been refunded.`,
        data: { bookingId: booking._id, reason },
        priority: 'normal'
      });

      // In a real implementation, process actual refund here
      // Examples:
      // - Stripe refund
      // - Chapa refund
      // - Add to student's wallet balance

      console.log(`💸 Escrow refunded: ETB ${booking.totalAmount} to student ${booking.studentId._id}`);

      return {
        success: true,
        bookingId: booking._id,
        amount: booking.totalAmount,
        refundedAt: booking.escrow.releasedAt
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
