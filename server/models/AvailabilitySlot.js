const mongoose = require('mongoose');

const timeSlotSchema = new mongoose.Schema({
  startTime: {
    type: String,
    required: true,
    match: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/ // HH:MM format
  },
  endTime: {
    type: String,
    required: true,
    match: /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/ // HH:MM format
  },
  durationMinutes: {
    type: Number,
    required: true,
    min: 15,
    max: 480 // 8 hours max
  }
});

const bookingInfoSchema = new mongoose.Schema({
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  studentName: {
    type: String,
    required: true
  },
  studentEmail: {
    type: String,
    required: true
  },
  studentPhone: String,
  subject: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'completed', 'cancelled', 'no-show'],
    default: 'pending'
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  notes: String,
  meetingLink: String,
  bookedAt: {
    type: Date,
    default: Date.now
  }
});

const availabilitySlotSchema = new mongoose.Schema({
  tutorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  timeSlot: {
    type: timeSlotSchema,
    required: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  isRecurring: {
    type: Boolean,
    default: false
  },
  recurringPattern: {
    type: String,
    enum: ['weekly', 'daily', 'monthly'],
    required: function() {
      return this.isRecurring;
    }
  },
  recurringEndDate: {
    type: Date,
    required: function() {
      return this.isRecurring;
    }
  },
  booking: bookingInfoSchema,
  // Metadata
  createdBy: {
    type: String,
    enum: ['tutor', 'admin'],
    default: 'tutor'
  },
  lastModifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  notes: String,
  // Status tracking
  isActive: {
    type: Boolean,
    default: true
  },
  cancelledAt: Date,
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  cancellationReason: String
}, {
  timestamps: true
});

// Indexes for better query performance
availabilitySlotSchema.index({ tutorId: 1, date: 1 });
availabilitySlotSchema.index({ tutorId: 1, date: 1, 'timeSlot.startTime': 1 });
availabilitySlotSchema.index({ date: 1, isAvailable: 1 });
availabilitySlotSchema.index({ 'booking.studentId': 1 });
availabilitySlotSchema.index({ 'booking.status': 1 });

// Virtual fields
availabilitySlotSchema.virtual('isBooked').get(function() {
  return !!this.booking;
});

availabilitySlotSchema.virtual('isPast').get(function() {
  const now = new Date();
  const slotDateTime = new Date(this.date);
  const [hours, minutes] = this.timeSlot.endTime.split(':');
  slotDateTime.setHours(parseInt(hours), parseInt(minutes));
  return slotDateTime < now;
});

availabilitySlotSchema.virtual('isToday').get(function() {
  const today = new Date();
  const slotDate = new Date(this.date);
  return today.toDateString() === slotDate.toDateString();
});

availabilitySlotSchema.virtual('isUpcoming').get(function() {
  const now = new Date();
  const slotDateTime = new Date(this.date);
  const [hours, minutes] = this.timeSlot.startTime.split(':');
  slotDateTime.setHours(parseInt(hours), parseInt(minutes));
  return slotDateTime > now;
});

// Methods
availabilitySlotSchema.methods.canBeBooked = function() {
  return this.isAvailable && 
         !this.isBooked && 
         this.isUpcoming && 
         this.isActive;
};

availabilitySlotSchema.methods.canBeCancelled = function() {
  return this.isBooked && 
         this.isUpcoming && 
         this.booking.status !== 'cancelled';
};

availabilitySlotSchema.methods.canBeModified = function() {
  return !this.isBooked && 
         this.isUpcoming && 
         this.isActive;
};

// Static methods
availabilitySlotSchema.statics.findAvailableSlots = function(tutorId, startDate, endDate) {
  return this.find({
    tutorId,
    date: { $gte: startDate, $lte: endDate },
    isAvailable: true,
    booking: { $exists: false },
    isActive: true
  }).sort({ date: 1, 'timeSlot.startTime': 1 });
};

availabilitySlotSchema.statics.findBookedSlots = function(tutorId, startDate, endDate) {
  return this.find({
    tutorId,
    date: { $gte: startDate, $lte: endDate },
    booking: { $exists: true },
    isActive: true
  }).populate('booking.studentId', 'firstName lastName email phone')
    .sort({ date: 1, 'timeSlot.startTime': 1 });
};

availabilitySlotSchema.statics.findUpcomingSessions = function(tutorId) {
  const now = new Date();
  return this.find({
    tutorId,
    date: { $gte: now },
    booking: { $exists: true },
    'booking.status': { $in: ['confirmed', 'pending'] },
    isActive: true
  }).populate('booking.studentId', 'firstName lastName email phone')
    .sort({ date: 1, 'timeSlot.startTime': 1 })
    .limit(10);
};

availabilitySlotSchema.statics.getWeeklySchedule = function(tutorId, weekStart) {
  const weekEnd = new Date(weekStart);
  weekEnd.setDate(weekEnd.getDate() + 6);
  
  return this.find({
    tutorId,
    date: { $gte: weekStart, $lte: weekEnd },
    isActive: true
  }).populate('booking.studentId', 'firstName lastName email phone')
    .sort({ date: 1, 'timeSlot.startTime': 1 });
};

// Pre-save middleware
availabilitySlotSchema.pre('save', function(next) {
  // Calculate duration if not provided
  if (!this.timeSlot.durationMinutes) {
    const start = this.timeSlot.startTime.split(':');
    const end = this.timeSlot.endTime.split(':');
    const startMinutes = parseInt(start[0]) * 60 + parseInt(start[1]);
    const endMinutes = parseInt(end[0]) * 60 + parseInt(end[1]);
    this.timeSlot.durationMinutes = endMinutes - startMinutes;
  }
  
  // Validate that end time is after start time
  if (this.timeSlot.durationMinutes <= 0) {
    return next(new Error('End time must be after start time'));
  }
  
  next();
});

// Pre-remove middleware
availabilitySlotSchema.pre('remove', function(next) {
  // Check if slot is booked before allowing deletion
  if (this.isBooked && this.booking.status === 'confirmed') {
    return next(new Error('Cannot delete a confirmed booking'));
  }
  next();
});

module.exports = mongoose.model('AvailabilitySlot', availabilitySlotSchema);