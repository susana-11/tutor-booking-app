const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  tutorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // ← Changed to User (was TutorProfile)
    required: true,
  },
  tutorProfileId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'TutorProfile',
    required: true,
  },
  slotId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AvailabilitySlot',
  },
  subject: {
    name: {
      type: String,
      required: true,
    },
    grades: [String],
  },
  sessionDate: {
    type: Date,
    required: true,
  },
  timeSlot: {
    startTime: String,
    endTime: String,
    durationMinutes: Number,
  },
  startTime: {
    type: String, // Format: "HH:MM"
    required: true,
  },
  endTime: {
    type: String, // Format: "HH:MM"
    required: true,
  },
  duration: {
    type: Number, // Duration in minutes
    required: true,
  },
  sessionType: {
    type: String,
    enum: ['online', 'inPerson'],
    required: true,
  },
  location: {
    type: String,
    required: function () {
      return this.sessionType === 'inPerson';
    },
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'cancelled', 'completed', 'rejected', 'declined', 'no-show'],
    default: 'pending',
  },
  pricePerHour: {
    type: Number,
    required: true,
  },
  totalAmount: {
    type: Number,
    required: true,
  },
  // Payment Information
  payment: {
    amount: {
      type: Number,
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'refunded', 'partially_refunded', 'failed', 'processing'],
      default: 'pending'
    },
    method: {
      type: String,
      enum: ['chapa', 'card', 'paypal', 'wallet', 'bank_transfer'],
      default: 'chapa'
    },
    chapaReference: String,
    chapaTransactionId: String,
    paidAt: Date,
    tutorShare: {
      type: Number,
      default: 0
    },
    platformFee: {
      type: Number,
      default: 0
    }
  },
  // Legacy fields (kept for backward compatibility)
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'refunded', 'partially_refunded', 'failed', 'processing'],
    default: 'pending',
  },
  paymentId: {
    type: String,
    default: null,
  },
  paymentMethod: {
    type: String,
    enum: ['card', 'paypal', 'wallet', 'bank_transfer', 'chapa'],
  },
  paymentIntentId: String,
  transactionId: String,
  paidAt: Date,
  // Refund Information
  refundAmount: {
    type: Number,
    default: 0,
  },
  refundReason: String,
  refundStatus: {
    type: String,
    enum: ['none', 'requested', 'processing', 'completed', 'rejected'],
    default: 'none',
  },
  refundId: String,
  refundedAt: Date,
  // Platform Fee
  platformFee: {
    type: Number,
    default: 0,
  },
  platformFeePercentage: {
    type: Number,
    default: 15, // 15% platform fee
  },
  tutorEarnings: {
    type: Number,
    default: 0,
  },
  // Session Notes
  notes: {
    student: String,
    tutor: String,
  },
  sessionNotes: {
    type: String, // Notes added after session completion
  },
  // Meeting Information
  meetingLink: String,
  meetingId: String,
  meetingPassword: String,
  // Cancellation Information
  cancellationReason: String,
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  cancelledAt: Date,
  cancellationPolicy: {
    type: String,
    default: '24_hours', // Can cancel 24 hours before
  },
  // Rejection Information
  rejectionReason: String,
  rejectedAt: Date,
  // Rescheduling
  rescheduleRequests: [{
    requestedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    requestedAt: Date,
    newDate: Date,
    newStartTime: String,
    newEndTime: String,
    reason: String,
    status: {
      type: String,
      enum: ['pending', 'accepted', 'rejected'],
      default: 'pending',
    },
    respondedAt: Date,
  }],
  originalBookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
  },
  isRescheduled: {
    type: Boolean,
    default: false,
  },
  // Session Completion
  completedAt: Date,
  sessionStartedAt: Date,
  sessionEndedAt: Date,
  actualDuration: Number, // Actual duration in minutes
  // Session Management
  session: {
    canStart: {
      type: Boolean,
      default: false
    },
    isActive: {
      type: Boolean,
      default: false
    },
    startedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    endedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    agoraChannelName: String,
    agoraToken: String,
    agoraUid: Number,
    sessionUrl: String,
    attendanceConfirmed: {
      student: {
        type: Boolean,
        default: false
      },
      tutor: {
        type: Boolean,
        default: false
      }
    }
  },
  // Escrow Management
  escrow: {
    status: {
      type: String,
      enum: ['none', 'held', 'released', 'refunded'],
      default: 'none'
    },
    heldAt: Date,
    releasedAt: Date,
    releaseScheduledFor: Date,
    autoReleaseEnabled: {
      type: Boolean,
      default: true
    },
    releaseDelayHours: {
      type: Number,
      default: 24 // Release 24 hours after session completion
    }
  },
  // Rating and Review
  rating: {
    studentRating: {
      score: {
        type: Number,
        min: 1,
        max: 5,
      },
      review: String,
      ratedAt: Date,
    },
    tutorRating: {
      score: {
        type: Number,
        min: 1,
        max: 5,
      },
      review: String,
      ratedAt: Date,
    },
  },
  // Dispute Management
  dispute: {
    isDisputed: {
      type: Boolean,
      default: false,
    },
    disputedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    disputeReason: String,
    disputeDescription: String,
    disputedAt: Date,
    disputeStatus: {
      type: String,
      enum: ['open', 'investigating', 'resolved', 'closed'],
    },
    resolution: String,
    resolvedAt: Date,
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  // Reminders
  remindersSent: [{
    type: {
      type: String,
      enum: ['24_hours', '1_hour', '15_minutes', 'rating_request'],
    },
    sentAt: Date,
  }],
  // Slot locking mechanism
  isSlotLocked: {
    type: Boolean,
    default: false,
  },
  lockExpiresAt: {
    type: Date,
    default: null,
  },
  lockedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  // Student Info (for quick access)
  studentInfo: {
    name: String,
    email: String,
    phone: String,
  },
  // Response tracking
  respondedAt: Date,
  tutorResponse: String,
}, {
  timestamps: true,
});

// Index for efficient queries
bookingSchema.index({ studentId: 1, createdAt: -1 });
bookingSchema.index({ tutorId: 1, createdAt: -1 });
bookingSchema.index({ sessionDate: 1, startTime: 1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ lockExpiresAt: 1 });
bookingSchema.index({ paymentStatus: 1 });
bookingSchema.index({ 'dispute.isDisputed': 1 });
bookingSchema.index({ completedAt: 1 });

// Virtual fields
bookingSchema.virtual('canBeCancelled').get(function () {
  if (!['pending', 'confirmed'].includes(this.status)) return false;

  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));

  // Check if more than 24 hours before session
  const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);
  return hoursUntilSession >= 24;
});

bookingSchema.virtual('canBeRescheduled').get(function () {
  if (!['pending', 'confirmed'].includes(this.status)) return false;

  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));

  // Check if more than 48 hours before session
  const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);
  return hoursUntilSession >= 48;
});

bookingSchema.virtual('canBeRated').get(function () {
  return this.status === 'completed' && !this.rating?.studentRating?.score;
});

bookingSchema.virtual('isUpcoming').get(function () {
  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));

  return sessionDateTime > now && ['confirmed', 'pending'].includes(this.status);
});

bookingSchema.virtual('refundEligibility').get(function () {
  if (this.status !== 'cancelled') return { eligible: false, percentage: 0 };

  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));

  const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);

  // Refund policy
  if (hoursUntilSession >= 48) return { eligible: true, percentage: 100 };
  if (hoursUntilSession >= 24) return { eligible: true, percentage: 50 };
  return { eligible: false, percentage: 0 };
});

// Middleware to calculate total amount and earnings
bookingSchema.pre('save', function (next) {
  // Calculate total amount
  if (this.isModified('duration') || this.isModified('pricePerHour')) {
    this.totalAmount = (this.duration / 60) * this.pricePerHour;
  }

  // Calculate platform fee and tutor earnings
  if (this.isModified('totalAmount') || this.isModified('platformFeePercentage')) {
    this.platformFee = (this.totalAmount * this.platformFeePercentage) / 100;
    this.tutorEarnings = this.totalAmount - this.platformFee;
  }

  next();
});

// Method to check if slot is available
bookingSchema.statics.isSlotAvailable = async function (tutorId, sessionDate, startTime, endTime, excludeBookingId = null) {
  const query = {
    tutorId,
    sessionDate,
    $or: [
      {
        startTime: { $lt: endTime },
        endTime: { $gt: startTime }
      }
    ],
    status: { $in: ['pending', 'confirmed'] }
  };

  if (excludeBookingId) {
    query._id = { $ne: excludeBookingId };
  }

  const conflictingBooking = await this.findOne(query);
  return !conflictingBooking;
};

// Method to lock a time slot
bookingSchema.statics.lockSlot = async function (tutorId, sessionDate, startTime, endTime, userId, lockDurationMinutes = 10) {
  const lockExpiresAt = new Date(Date.now() + lockDurationMinutes * 60 * 1000);

  // Check if slot is already locked by someone else
  const existingLock = await this.findOne({
    tutorId,
    sessionDate,
    startTime,
    endTime,
    isSlotLocked: true,
    lockExpiresAt: { $gt: new Date() },
    lockedBy: { $ne: userId }
  });

  if (existingLock) {
    throw new Error('Slot is currently locked by another user');
  }

  // Create or update lock
  const lockData = {
    tutorId,
    sessionDate,
    startTime,
    endTime,
    isSlotLocked: true,
    lockExpiresAt,
    lockedBy: userId,
    status: 'pending'
  };

  const existingBooking = await this.findOne({
    tutorId,
    sessionDate,
    startTime,
    endTime,
    lockedBy: userId,
    status: 'pending'
  });

  if (existingBooking) {
    existingBooking.lockExpiresAt = lockExpiresAt;
    return await existingBooking.save();
  }

  return await this.create(lockData);
};

// Method to release expired locks
bookingSchema.statics.releaseExpiredLocks = async function () {
  return await this.deleteMany({
    isSlotLocked: true,
    lockExpiresAt: { $lt: new Date() },
    status: 'pending'
  });
};

// Method to process refund
bookingSchema.methods.processRefund = async function () {
  if (this.paymentStatus !== 'paid') {
    throw new Error('Cannot refund unpaid booking');
  }

  const refundEligibility = this.refundEligibility;
  if (!refundEligibility.eligible) {
    throw new Error('Booking is not eligible for refund');
  }

  this.refundAmount = (this.totalAmount * refundEligibility.percentage) / 100;
  this.refundStatus = 'processing';
  this.paymentStatus = refundEligibility.percentage === 100 ? 'refunded' : 'partially_refunded';

  // In a real app, integrate with payment gateway here
  // e.g., Stripe refund API

  return await this.save();
};

// Method to complete session
bookingSchema.methods.completeSession = async function (sessionNotes) {
  if (this.status !== 'confirmed') {
    throw new Error('Only confirmed bookings can be completed');
  }

  this.status = 'completed';
  this.completedAt = new Date();
  this.sessionNotes = sessionNotes;

  // Calculate actual duration if session times are tracked
  if (this.sessionStartedAt && this.sessionEndedAt) {
    this.actualDuration = Math.floor((this.sessionEndedAt - this.sessionStartedAt) / (1000 * 60));
  }

  // Schedule escrow release
  if (this.escrow.status === 'held' && this.escrow.autoReleaseEnabled) {
    const releaseDate = new Date();
    releaseDate.setHours(releaseDate.getHours() + this.escrow.releaseDelayHours);
    this.escrow.releaseScheduledFor = releaseDate;
  }

  return await this.save();
};

// Method to start session
bookingSchema.methods.startSession = async function (userId, agoraChannelName, agoraToken, agoraUid) {
  if (this.status !== 'confirmed') {
    throw new Error('Only confirmed bookings can be started');
  }

  if (this.session.isActive) {
    throw new Error('Session is already active');
  }

  // Check if session time has arrived (allow starting 5 minutes early)
  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));
  sessionDateTime.setMinutes(sessionDateTime.getMinutes() - 5); // Allow 5 min early

  if (now < sessionDateTime) {
    throw new Error('Session cannot be started yet. Please wait until the scheduled time.');
  }

  this.session.isActive = true;
  this.session.startedBy = userId;
  this.session.agoraChannelName = agoraChannelName;
  this.session.agoraToken = agoraToken;
  this.session.agoraUid = agoraUid;
  this.sessionStartedAt = new Date();

  return await this.save();
};

// Method to end session
bookingSchema.methods.endSession = async function (userId) {
  if (!this.session.isActive) {
    throw new Error('Session is not active');
  }

  this.session.isActive = false;
  this.session.endedBy = userId;
  this.sessionEndedAt = new Date();

  // Calculate actual duration
  if (this.sessionStartedAt && this.sessionEndedAt) {
    this.actualDuration = Math.floor((this.sessionEndedAt - this.sessionStartedAt) / (1000 * 60));
  }

  // Auto-complete the booking
  this.status = 'completed';
  this.completedAt = new Date();

  // Schedule escrow release
  if (this.escrow.status === 'held' && this.escrow.autoReleaseEnabled) {
    const releaseDate = new Date();
    releaseDate.setHours(releaseDate.getHours() + this.escrow.releaseDelayHours);
    this.escrow.releaseScheduledFor = releaseDate;
  }

  return await this.save();
};

// Method to confirm attendance
bookingSchema.methods.confirmAttendance = async function (userId, userRole) {
  if (!this.session.isActive) {
    throw new Error('Session is not active');
  }

  if (userRole === 'student') {
    this.session.attendanceConfirmed.student = true;
  } else if (userRole === 'tutor') {
    this.session.attendanceConfirmed.tutor = true;
  }

  return await this.save();
};

// Method to hold payment in escrow
bookingSchema.methods.holdInEscrow = async function () {
  if (this.payment.status !== 'paid') {
    throw new Error('Payment must be completed before holding in escrow');
  }

  this.escrow.status = 'held';
  this.escrow.heldAt = new Date();

  return await this.save();
};

// Method to release escrow
bookingSchema.methods.releaseEscrow = async function () {
  if (this.escrow.status !== 'held') {
    throw new Error('Escrow is not in held status');
  }

  if (this.status !== 'completed') {
    throw new Error('Booking must be completed before releasing escrow');
  }

  this.escrow.status = 'released';
  this.escrow.releasedAt = new Date();

  // In real implementation, trigger payout to tutor here
  // e.g., Stripe transfer, bank transfer, etc.

  return await this.save();
};

// Method to check if session can start
bookingSchema.methods.canStartSession = function () {
  if (this.status !== 'confirmed') return false;
  if (this.session.isActive) return false;

  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));
  
  // Allow starting 24 hours before scheduled time (for testing)
  sessionDateTime.setHours(sessionDateTime.getHours() - 24);
  
  // Allow starting up to 24 hours after scheduled time (for testing)
  const lateStartTime = new Date(sessionDateTime);
  lateStartTime.setHours(lateStartTime.getHours() + 48); // 24 hours before + 24 hours after

  return now >= sessionDateTime && now <= lateStartTime;
};

// Method to add rating
bookingSchema.methods.addRating = async function (userId, score, review, userRole) {
  if (this.status !== 'completed') {
    throw new Error('Can only rate completed sessions');
  }

  if (userRole === 'student') {
    this.rating.studentRating = {
      score,
      review,
      ratedAt: new Date(),
    };
  } else if (userRole === 'tutor') {
    this.rating.tutorRating = {
      score,
      review,
      ratedAt: new Date(),
    };
  }

  return await this.save();
};

// Method to create dispute
bookingSchema.methods.createDispute = async function (userId, reason, description) {
  if (this.dispute.isDisputed) {
    throw new Error('Dispute already exists for this booking');
  }

  this.dispute = {
    isDisputed: true,
    disputedBy: userId,
    disputeReason: reason,
    disputeDescription: description,
    disputedAt: new Date(),
    disputeStatus: 'open',
  };

  return await this.save();
};

// Static method to get earnings summary
bookingSchema.statics.getEarningsSummary = async function (tutorId, startDate, endDate) {
  const bookings = await this.find({
    tutorId,
    status: 'completed',
    completedAt: { $gte: startDate, $lte: endDate },
    paymentStatus: 'paid',
  });

  const totalEarnings = bookings.reduce((sum, booking) => sum + booking.tutorEarnings, 0);
  const totalSessions = bookings.length;
  const totalHours = bookings.reduce((sum, booking) => sum + (booking.actualDuration || booking.duration) / 60, 0);

  return {
    totalEarnings,
    totalSessions,
    totalHours,
    averagePerSession: totalSessions > 0 ? totalEarnings / totalSessions : 0,
    bookings,
  };
};

// Static method to get upcoming sessions
bookingSchema.statics.getUpcomingSessions = async function (userId, userRole) {
  const query = {
    status: { $in: ['confirmed', 'pending'] },
    sessionDate: { $gte: new Date() },
  };

  if (userRole === 'student') {
    query.studentId = userId;
  } else {
    query.tutorId = userId;
  }

  return await this.find(query)
    .populate('studentId', 'firstName lastName email phone')
    .populate('tutorId', 'firstName lastName email phone')
    .sort({ sessionDate: 1, startTime: 1 })
    .limit(10);
};

module.exports = mongoose.model('Booking', bookingSchema);