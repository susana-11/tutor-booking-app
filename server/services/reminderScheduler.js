const Booking = require('../models/Booking');
const notificationService = require('./notificationService');

class ReminderScheduler {
  constructor() {
    this.intervals = [];
  }

  // Start the reminder scheduler
  start() {
    console.log('📅 Starting booking reminder scheduler...');
    
    // Wait 10 seconds before first check to allow database connection
    setTimeout(() => {
      console.log('📅 Booking reminder scheduler started');
      
      // Check every 5 minutes for upcoming sessions
      const interval = setInterval(() => {
        this.checkUpcomingBookings();
      }, 5 * 60 * 1000); // 5 minutes

      this.intervals.push(interval);
      
      // Run first check
      this.checkUpcomingBookings();
    }, 10000); // Wait 10 seconds
  }

  // Stop the scheduler
  stop() {
    this.intervals.forEach(interval => clearInterval(interval));
    this.intervals = [];
    console.log('📅 Reminder scheduler stopped');
  }

  // Check for upcoming bookings and send reminders
  async checkUpcomingBookings() {
    try {
      const mongoose = require('mongoose');
      
      // Check if database is connected
      if (mongoose.connection.readyState !== 1) {
        console.log('⏳ Database not ready yet, skipping reminder check...');
        return;
      }

      const now = new Date();
      
      // Find confirmed bookings that haven't been completed
      const bookings = await Booking.find({
        status: 'confirmed',
        sessionDate: { $gte: now },
      }).populate('studentId tutorId', 'firstName lastName email');

      for (const booking of bookings) {
        const sessionDateTime = new Date(booking.sessionDate);
        const [hours, minutes] = booking.startTime.split(':');
        sessionDateTime.setHours(parseInt(hours), parseInt(minutes));

        const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);

        // Send 24-hour reminder
        if (hoursUntilSession <= 24 && hoursUntilSession > 23.75) {
          const sent24h = booking.remindersSent.find(r => r.type === '24_hours');
          if (!sent24h) {
            await this.sendReminder(booking, '24_hours');
          }
        }

        // Send 1-hour reminder
        if (hoursUntilSession <= 1 && hoursUntilSession > 0.75) {
          const sent1h = booking.remindersSent.find(r => r.type === '1_hour');
          if (!sent1h) {
            await this.sendReminder(booking, '1_hour');
          }
        }

        // Send 15-minute reminder
        if (hoursUntilSession <= 0.25 && hoursUntilSession > 0.20) {
          const sent15m = booking.remindersSent.find(r => r.type === '15_minutes');
          if (!sent15m) {
            await this.sendReminder(booking, '15_minutes');
          }
        }
      }

      // Check for completed sessions that need rating reminders
      await this.checkCompletedSessions();

    } catch (error) {
      console.error('Error checking upcoming bookings:', error);
    }
  }

  // Send reminder for a booking
  async sendReminder(booking, type) {
    try {
      await notificationService.sendBookingReminder(booking, type);
      
      booking.remindersSent.push({
        type,
        sentAt: new Date(),
      });
      
      await booking.save();
      
      console.log(`✅ Sent ${type} reminder for booking ${booking._id}`);
    } catch (error) {
      console.error(`Error sending ${type} reminder:`, error);
    }
  }

  // Check completed sessions for rating reminders
  async checkCompletedSessions() {
    try {
      const mongoose = require('mongoose');
      
      // Check if database is connected
      if (mongoose.connection.readyState !== 1) {
        return;
      }

      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      
      const completedBookings = await Booking.find({
        status: 'completed',
        completedAt: { $gte: oneDayAgo },
        $or: [
          { 'rating.studentRating.score': { $exists: false } },
          { 'rating.tutorRating.score': { $exists: false } },
        ],
      });

      for (const booking of completedBookings) {
        // Check if rating reminder was already sent
        const ratingReminderSent = booking.remindersSent.find(r => r.type === 'rating_request');
        
        if (!ratingReminderSent) {
          await notificationService.sendRatingRequest(booking);
          
          booking.remindersSent.push({
            type: 'rating_request',
            sentAt: new Date(),
          });
          
          await booking.save();
        }
      }
    } catch (error) {
      console.error('Error checking completed sessions:', error);
    }
  }

  // Clean up expired slot locks
  async cleanupExpiredLocks() {
    try {
      const mongoose = require('mongoose');
      
      // Check if database is connected
      if (mongoose.connection.readyState !== 1) {
        return;
      }

      const result = await Booking.releaseExpiredLocks();
      if (result.deletedCount > 0) {
        console.log(`🧹 Cleaned up ${result.deletedCount} expired slot locks`);
      }
    } catch (error) {
      console.error('Error cleaning up expired locks:', error);
    }
  }
}

module.exports = new ReminderScheduler();
