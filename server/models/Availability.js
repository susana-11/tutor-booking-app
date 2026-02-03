const mongoose = require('mongoose');

const timeSlotSchema = new mongoose.Schema({
  startTime: {
    type: String, // Format: "HH:MM" (24-hour format)
    required: true,
  },
  endTime: {
    type: String, // Format: "HH:MM" (24-hour format)
    required: true,
  },
  isAvailable: {
    type: Boolean,
    default: true,
  },
  isBooked: {
    type: Boolean,
    default: false,
  },
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    default: null,
  },
});

const dailyAvailabilitySchema = new mongoose.Schema({
  dayOfWeek: {
    type: Number, // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    required: true,
    min: 0,
    max: 6,
  },
  isAvailable: {
    type: Boolean,
    default: true,
  },
  timeSlots: [timeSlotSchema],
});

const availabilitySchema = new mongoose.Schema({
  tutorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'TutorProfile',
    required: true,
  },
  weeklySchedule: [dailyAvailabilitySchema],
  blockedDates: [{
    date: {
      type: Date,
      required: true,
    },
    reason: {
      type: String,
      default: 'Unavailable',
    },
  }],
  timezone: {
    type: String,
    default: 'UTC',
  },
}, {
  timestamps: true,
});

// Index for efficient queries
availabilitySchema.index({ tutorId: 1 });
availabilitySchema.index({ 'weeklySchedule.dayOfWeek': 1 });

module.exports = mongoose.model('Availability', availabilitySchema);