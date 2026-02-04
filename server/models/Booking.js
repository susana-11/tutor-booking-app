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
    type: {
      type: String,
      enum: ['student_location', 'tutor_location', 'public_place', 'custom'],
      default: 'public_place'
    },
    address: String,
    city: String,
    state: String,
    zipCode: String,
    country: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    placeId: String, // Google Places ID
    placeName: String, // e.g., "Starbucks Downtown"
    instructions: String, // e.g., "Meet at the entrance"
    fullAddress: String // Complete formatted address
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
  
  // Offline/In-Person Session Management
  checkIn: {
    student: {
      checkedIn: {
        type: Boolean,
        default: false
      },
      checkedInAt: Date,
      location: {
        latitude: Number,
        longitude: Number
      },
      verified: {
        type: Boolean,
        default: false
      },
      distanceFromMeetingPoint: Number // in meters
    },
    tutor: {
      checkedIn: {
        type: Boolean,
        default: false
      },
      checkedInAt: Date,
      location: {
        latitude: Number,
        longitude: Number
      },
      verified: {
        type: Boolean,
        default: false
      },
      distanceFromMeetingPoint: Number // in meters
    },
    bothCheckedIn: {
      type: Boolean,
      default: false
    },
    bothCheckedInAt: Date
  },
  
  checkOut: {
    student: {
      checkedOut: {
        type: Boolean,
        default: false
      },
      checkedOutAt: Date
    },
    tutor: {
      checkedOut: {
        type: Boolean,
        default: false
      },
      checkedOutAt: Date
    },
    bothCheckedOut: {
      type: Boolean,
      default: false
    },
    bothCheckedOutAt: Date
  },
  
  // Offline Session Status
  offlineSession: {
    status: {
      type: String,
      enum: ['scheduled', 'student_checked_in', 'tutor_checked_in', 
             'both_checked_in', 'in_progress', 'completed', 'no_show'],
      default: 'scheduled'
    },
    studentArrived: {
      type: Boolean,
      default: false
    },
    tutorArrived: {
      type: Boolean,
      default: false
    },
    runningLate: {
      student: {
        isLate: {
          type: Boolean,
          default: false
        },
        estimatedArrival: Date,
        notifiedAt: Date,
        reason: String
      },
      tutor: {
        isLate: {
          type: Boolean,
          default: false
        },
        estimatedArrival: Date,
        notifiedAt: Date,
        reason: String
      }
    },
    actualStartTime: Date,
    actualEndTime: Date,
    actualDuration: Number, // in minutes
    waitingTime: Number // time between first and second check-in (minutes)
  },
  
  // Safety Features
  safety: {
    emergencyContact: {
      name: String,
      phone: String,
      relationship: String
    },
    sessionShared: {
      type: Boolean,
      default: false
    },
    sharedWith: [{
      name: String,
      phone: String,
      email: String,
      sharedAt: Date
    }],
    issues: [{
      reportedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      issueType: {
        type: String,
        enum: ['safety_concern', 'harassment', 'no_show', 'location_issue', 'other']
      },
      description: String,
      reportedAt: Date,
      resolved: {
        type: Boolean,
        default: false
      },
      resolvedAt: Date,
      resolution: String
    }]
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

  // Schedule escrow release based on configured delay
  if (this.escrow.status === 'held' && this.escrow.autoReleaseEnabled) {
    const releaseDate = new Date();
    const releaseDelayHours = this.escrow.releaseDelayHours || 1; // Default 1 hour if not set
    releaseDate.setHours(releaseDate.getHours() + releaseDelayHours);
    this.escrow.releaseScheduledFor = releaseDate;
    
    console.log(`📅 Escrow release scheduled for: ${releaseDate.toISOString()}`);
    console.log(`   (${releaseDelayHours} hours from now)`);
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

  // Check if session time has arrived (allow starting 24 hours early for testing)
  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes));
  sessionDateTime.setHours(sessionDateTime.getHours() - 24); // Allow 24 hours early for testing

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

  // Schedule escrow release based on configured delay
  if (this.escrow.status === 'held' && this.escrow.autoReleaseEnabled) {
    const releaseDate = new Date();
    const releaseDelayHours = this.escrow.releaseDelayHours || 1; // Default 1 hour if not set
    releaseDate.setHours(releaseDate.getHours() + releaseDelayHours);
    this.escrow.releaseScheduledFor = releaseDate;
    
    console.log(`📅 Escrow release scheduled for: ${releaseDate.toISOString()}`);
    console.log(`   (${releaseDelayHours} hours from now)`);
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
  if (this.status !== 'confirmed') {
    console.log('❌ Cannot start: status is not confirmed:', this.status);
    return false;
  }
  if (this.session.isActive) {
    console.log('❌ Cannot start: session is already active');
    return false;
  }

  const now = new Date();
  const sessionDateTime = new Date(this.sessionDate);
  const [hours, minutes] = this.startTime.split(':');
  sessionDateTime.setHours(parseInt(hours), parseInt(minutes), 0, 0);
  
  console.log('⏰ Session timing check:', {
    now: now.toISOString(),
    sessionDate: this.sessionDate,
    startTime: this.startTime,
    calculatedSessionDateTime: sessionDateTime.toISOString(),
    bookingId: this._id
  });
  
  // Allow starting 24 hours before scheduled time (for testing)
  const earlyStartTime = new Date(sessionDateTime);
  earlyStartTime.setHours(earlyStartTime.getHours() - 24);
  
  // Allow starting up to 24 hours after scheduled time (for testing)
  const lateStartTime = new Date(sessionDateTime);
  lateStartTime.setHours(lateStartTime.getHours() + 24);

  console.log('⏰ Time window:', {
    earlyStartTime: earlyStartTime.toISOString(),
    lateStartTime: lateStartTime.toISOString(),
    canStart: now >= earlyStartTime && now <= lateStartTime
  });

  return now >= earlyStartTime && now <= lateStartTime;
};

// Method to perform check-in (for offline sessions)
bookingSchema.methods.performCheckIn = async function (userId, userRole, location) {
  if (this.sessionType !== 'inPerson') {
    throw new Error('Check-in is only available for in-person sessions');
  }

  if (this.status !== 'confirmed') {
    throw new Error('Only confirmed bookings can be checked in');
  }

  const now = new Date();
  
  // Calculate distance from meeting point if location provided
  let distanceFromMeetingPoint = null;
  if (location && this.location.coordinates) {
    distanceFromMeetingPoint = this.calculateDistance(
      location.latitude,
      location.longitude,
      this.location.coordinates.latitude,
      this.location.coordinates.longitude
    );
  }

  if (userRole === 'student') {
    if (this.checkIn.student.checkedIn) {
      throw new Error('Student already checked in');
    }
    
    this.checkIn.student.checkedIn = true;
    this.checkIn.student.checkedInAt = now;
    this.checkIn.student.location = location;
    this.checkIn.student.distanceFromMeetingPoint = distanceFromMeetingPoint;
    this.checkIn.student.verified = distanceFromMeetingPoint ? distanceFromMeetingPoint < 100 : false; // Within 100m
    
    this.offlineSession.studentArrived = true;
    this.offlineSession.status = this.checkIn.tutor.checkedIn ? 'both_checked_in' : 'student_checked_in';
    
  } else if (userRole === 'tutor') {
    if (this.checkIn.tutor.checkedIn) {
      throw new Error('Tutor already checked in');
    }
    
    this.checkIn.tutor.checkedIn = true;
    this.checkIn.tutor.checkedInAt = now;
    this.checkIn.tutor.location = location;
    this.checkIn.tutor.distanceFromMeetingPoint = distanceFromMeetingPoint;
    this.checkIn.tutor.verified = distanceFromMeetingPoint ? distanceFromMeetingPoint < 100 : false; // Within 100m
    
    this.offlineSession.tutorArrived = true;
    this.offlineSession.status = this.checkIn.student.checkedIn ? 'both_checked_in' : 'tutor_checked_in';
  }

  // If both checked in
  if (this.checkIn.student.checkedIn && this.checkIn.tutor.checkedIn) {
    this.checkIn.bothCheckedIn = true;
    this.checkIn.bothCheckedInAt = now;
    this.offlineSession.status = 'both_checked_in';
    
    // Calculate waiting time
    const firstCheckIn = this.checkIn.student.checkedInAt < this.checkIn.tutor.checkedInAt
      ? this.checkIn.student.checkedInAt
      : this.checkIn.tutor.checkedInAt;
    this.offlineSession.waitingTime = Math.floor((now - firstCheckIn) / (1000 * 60));
    
    // Auto-start session
    this.offlineSession.actualStartTime = now;
    this.offlineSession.status = 'in_progress';
    this.sessionStartedAt = now;
  }

  return await this.save();
};

// Method to perform check-out (for offline sessions)
bookingSchema.methods.performCheckOut = async function (userId, userRole) {
  if (this.sessionType !== 'inPerson') {
    throw new Error('Check-out is only available for in-person sessions');
  }

  if (!this.checkIn.bothCheckedIn) {
    throw new Error('Both parties must check in before checking out');
  }

  const now = new Date();

  if (userRole === 'student') {
    if (this.checkOut.student.checkedOut) {
      throw new Error('Student already checked out');
    }
    
    this.checkOut.student.checkedOut = true;
    this.checkOut.student.checkedOutAt = now;
    
  } else if (userRole === 'tutor') {
    if (this.checkOut.tutor.checkedOut) {
      throw new Error('Tutor already checked out');
    }
    
    this.checkOut.tutor.checkedOut = true;
    this.checkOut.tutor.checkedOutAt = now;
  }

  // If both checked out
  if (this.checkOut.student.checkedOut && this.checkOut.tutor.checkedOut) {
    this.checkOut.bothCheckedOut = true;
    this.checkOut.bothCheckedOutAt = now;
    
    // Complete session
    this.status = 'completed';
    this.completedAt = now;
    this.offlineSession.status = 'completed';
    this.offlineSession.actualEndTime = now;
    this.sessionEndedAt = now;
    
    // Calculate actual duration
    if (this.offlineSession.actualStartTime) {
      this.offlineSession.actualDuration = Math.floor(
        (now - this.offlineSession.actualStartTime) / (1000 * 60)
      );
      this.actualDuration = this.offlineSession.actualDuration;
    }
    
    // Schedule escrow release based on configured delay
    if (this.escrow.status === 'held' && this.escrow.autoReleaseEnabled) {
      const releaseDate = new Date();
      const releaseDelayHours = this.escrow.releaseDelayHours || 1; // Default 1 hour if not set
      releaseDate.setHours(releaseDate.getHours() + releaseDelayHours);
      this.escrow.releaseScheduledFor = releaseDate;
      
      console.log(`📅 Escrow release scheduled for: ${releaseDate.toISOString()}`);
      console.log(`   (${releaseDelayHours} hours from now)`);
    }
  }

  return await this.save();
};

// Method to notify running late
bookingSchema.methods.notifyRunningLate = async function (userId, userRole, estimatedArrival, reason) {
  if (this.sessionType !== 'inPerson') {
    throw new Error('Running late notification is only for in-person sessions');
  }

  const now = new Date();

  if (userRole === 'student') {
    this.offlineSession.runningLate.student.isLate = true;
    this.offlineSession.runningLate.student.estimatedArrival = estimatedArrival;
    this.offlineSession.runningLate.student.notifiedAt = now;
    this.offlineSession.runningLate.student.reason = reason;
  } else if (userRole === 'tutor') {
    this.offlineSession.runningLate.tutor.isLate = true;
    this.offlineSession.runningLate.tutor.estimatedArrival = estimatedArrival;
    this.offlineSession.runningLate.tutor.notifiedAt = now;
    this.offlineSession.runningLate.tutor.reason = reason;
  }

  return await this.save();
};

// Method to report safety issue
bookingSchema.methods.reportSafetyIssue = async function (userId, issueType, description) {
  this.safety.issues.push({
    reportedBy: userId,
    issueType,
    description,
    reportedAt: new Date(),
    resolved: false
  });

  return await this.save();
};

// Method to share session details
bookingSchema.methods.shareSession = async function (contacts) {
  this.safety.sessionShared = true;
  this.safety.sharedWith = contacts.map(contact => ({
    ...contact,
    sharedAt: new Date()
  }));

  return await this.save();
};

// Helper method to calculate distance between two coordinates (Haversine formula)
bookingSchema.methods.calculateDistance = function (lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
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