const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: [
      'booking_request',
      'booking_accepted',
      'booking_declined',
      'booking_cancelled',
      'booking_confirmed',
      'booking_reminder',
      'reschedule_request',
      'reschedule_accepted',
      'reschedule_rejected',
      'session_started',
      'session_ended',
      'rating_request',
      'new_message',
      'new_review',
      'call_incoming',
      'call_missed',
      'payment_received',
      'payment_pending',
      'profile_approved',
      'profile_rejected',
      'system_announcement'
    ],
    required: true
  },
  title: {
    type: String,
    required: true
  },
  body: {
    type: String,
    required: true
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  read: {
    type: Boolean,
    default: false
  },
  readAt: Date,
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  actionUrl: String,
  imageUrl: String,
  expiresAt: Date
}, {
  timestamps: true
});

// Index for efficient queries
notificationSchema.index({ userId: 1, read: 1, createdAt: -1 });
notificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 2592000 }); // Auto-delete after 30 days

// Mark as read
notificationSchema.methods.markAsRead = function() {
  this.read = true;
  this.readAt = new Date();
  return this.save();
};

// Check if expired
notificationSchema.virtual('isExpired').get(function() {
  return this.expiresAt && this.expiresAt < new Date();
});

module.exports = mongoose.model('Notification', notificationSchema);
