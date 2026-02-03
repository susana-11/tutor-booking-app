const mongoose = require('mongoose');

const tutorProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  // Basic Info
  bio: {
    type: String,
    required: [true, 'Bio is required'],
    maxlength: [1000, 'Bio cannot exceed 1000 characters']
  },
  headline: {
    type: String,
    maxlength: [200, 'Headline cannot exceed 200 characters']
  },
  experience: {
    years: {
      type: Number,
      min: 0,
      max: 50
    },
    description: {
      type: String,
      maxlength: [500, 'Experience description cannot exceed 500 characters']
    }
  },

  // Education
  education: [{
    degree: {
      type: String,
      required: true
    },
    institution: {
      type: String,
      required: true
    },
    year: {
      type: Number,
      min: 1950,
      max: new Date().getFullYear() + 10
    },
    field: String
  }],

  // Subjects and Teaching
  subjects: [{
    name: {
      type: String,
      required: true
    },
    category: String,
    gradelevels: [String],
    experience: String,
    isSpecialty: {
      type: Boolean,
      default: false
    }
  }],

  // Pricing
  pricing: {
    hourlyRate: {
      type: Number,
      required: [true, 'Hourly rate is required'],
      min: [1, 'Hourly rate must be at least $1']
    },
    currency: {
      type: String,
      default: 'USD'
    },
    packageDeals: [{
      sessions: Number,
      totalPrice: Number,
      discount: Number,
      description: String
    }]
  },

  // Teaching Preferences
  teachingMode: {
    online: {
      type: Boolean,
      default: true
    },
    inPerson: {
      type: Boolean,
      default: false
    }
  },

  // Location (for in-person sessions)
  location: {
    address: String,
    city: String,
    state: String,
    country: String,
    zipCode: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    travelRadius: {
      type: Number,
      default: 0 // in miles/km
    }
  },

  // Availability
  timezone: {
    type: String,
    default: 'UTC'
  },

  // Media
  profilePhoto: String,
  introVideo: String,
  gallery: [String],

  // Certifications and Documents
  certifications: [{
    name: {
      type: String,
      required: true
    },
    issuer: String,
    issueDate: Date,
    expiryDate: Date,
    credentialId: String,
    documentUrl: String,
    isVerified: {
      type: Boolean,
      default: false
    }
  }],

  // Languages
  languages: [{
    language: {
      type: String,
      required: true
    },
    proficiency: {
      type: String,
      enum: ['Native', 'Fluent', 'Conversational', 'Basic'],
      required: true
    }
  }],

  // Status and Verification
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended'],
    default: 'pending'
  },
  verificationStatus: {
    identity: {
      type: Boolean,
      default: false
    },
    education: {
      type: Boolean,
      default: false
    },
    background: {
      type: Boolean,
      default: false
    }
  },
  rejectionReason: String,

  // Activity
  isActive: {
    type: Boolean,
    default: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  lastActive: {
    type: Date,
    default: Date.now
  },

  // Statistics
  stats: {
    totalSessions: {
      type: Number,
      default: 0
    },
    completedSessions: {
      type: Number,
      default: 0
    },
    cancelledSessions: {
      type: Number,
      default: 0
    },
    totalEarnings: {
      type: Number,
      default: 0
    },
    averageRating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    totalReviews: {
      type: Number,
      default: 0
    },
    responseTime: {
      type: Number,
      default: 0 // in minutes
    },
    completionRate: {
      type: Number,
      default: 0 // percentage
    }
  },

  // Settings
  settings: {
    instantBooking: {
      type: Boolean,
      default: false
    },
    requireApproval: {
      type: Boolean,
      default: true
    },
    advanceBookingDays: {
      type: Number,
      default: 30
    },
    cancellationPolicy: {
      type: String,
      enum: ['flexible', 'moderate', 'strict'],
      default: 'moderate'
    },
    autoAcceptBookings: {
      type: Boolean,
      default: false
    }
  },

  // Balance Management
  balance: {
    available: {
      type: Number,
      default: 0,
      min: 0
    },
    pending: {
      type: Number,
      default: 0,
      min: 0
    },
    total: {
      type: Number,
      default: 0,
      min: 0
    },
    withdrawn: {
      type: Number,
      default: 0,
      min: 0
    }
  },

  // Bank Account for Withdrawals
  bankAccount: {
    accountNumber: String,
    accountName: String,
    bankName: String,
    isVerified: {
      type: Boolean,
      default: false
    }
  }
}, {
  timestamps: true
});

// Indexes
tutorProfileSchema.index({ userId: 1 });
tutorProfileSchema.index({ status: 1 });
tutorProfileSchema.index({ isActive: 1 });
tutorProfileSchema.index({ 'subjects.name': 1 });
tutorProfileSchema.index({ 'pricing.hourlyRate': 1 });
tutorProfileSchema.index({ 'stats.averageRating': -1 });
tutorProfileSchema.index({ 'location.city': 1 });
tutorProfileSchema.index({ createdAt: -1 });

// Virtual for completion percentage
tutorProfileSchema.virtual('completionPercentage').get(function () {
  let completed = 0;
  let total = 10;

  if (this.bio) completed++;
  if (this.subjects && this.subjects.length > 0) completed++;
  if (this.pricing && this.pricing.hourlyRate) completed++;
  if (this.education && this.education.length > 0) completed++;
  if (this.experience && this.experience.years >= 0) completed++;
  if (this.profilePhoto) completed++;
  if (this.languages && this.languages.length > 0) completed++;
  if (this.location && this.location.city) completed++;
  if (this.certifications && this.certifications.length > 0) completed++;
  if (this.headline) completed++;

  return Math.round((completed / total) * 100);
});

// Method to update statistics
tutorProfileSchema.methods.updateStats = async function () {
  const Booking = mongoose.model('Booking');
  const Review = mongoose.model('Review');

  // Get booking statistics
  const bookingStats = await Booking.aggregate([
    { $match: { tutorId: this._id } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalEarnings: { $sum: '$totalAmount' }
      }
    }
  ]);

  // Get review statistics
  const reviewStats = await Review.aggregate([
    { $match: { tutorId: this._id } },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 }
      }
    }
  ]);

  // Update stats
  let totalSessions = 0;
  let completedSessions = 0;
  let cancelledSessions = 0;
  let totalEarnings = 0;

  bookingStats.forEach(stat => {
    totalSessions += stat.count;
    if (stat._id === 'completed') {
      completedSessions = stat.count;
      totalEarnings = stat.totalEarnings || 0;
    }
    if (stat._id === 'cancelled') {
      cancelledSessions = stat.count;
    }
  });

  this.stats.totalSessions = totalSessions;
  this.stats.completedSessions = completedSessions;
  this.stats.cancelledSessions = cancelledSessions;
  this.stats.totalEarnings = totalEarnings;
  this.stats.completionRate = totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0;

  if (reviewStats.length > 0) {
    this.stats.averageRating = Math.round(reviewStats[0].averageRating * 10) / 10;
    this.stats.totalReviews = reviewStats[0].totalReviews;
  }

  return this.save();
};

// Method to update average rating (called when reviews change)
tutorProfileSchema.methods.updateAverageRating = async function () {
  const Review = mongoose.model('Review');

  // Get rating statistics from Review model
  const ratingStats = await Review.getTutorAverageRating(this._id);

  // Update tutor profile stats
  this.stats.averageRating = ratingStats.averageRating;
  this.stats.totalReviews = ratingStats.totalReviews;

  return this.save();
};

// Static method to get featured tutors
tutorProfileSchema.statics.getFeatured = function (limit = 10) {
  return this.find({
    status: 'approved',
    isActive: true,
    'stats.averageRating': { $gte: 4.0 },
    'stats.totalSessions': { $gte: 5 }
  })
    .populate('userId', 'firstName lastName profilePicture')
    .sort({ 'stats.averageRating': -1, 'stats.totalReviews': -1 })
    .limit(limit);
};

// Static method to search tutors
tutorProfileSchema.statics.searchTutors = function (filters = {}) {
  const query = {
    status: 'approved',
    isActive: true
  };

  // Subject filter
  if (filters.subject) {
    query['subjects.name'] = { $regex: filters.subject, $options: 'i' };
  }

  // Price range filter
  if (filters.minPrice || filters.maxPrice) {
    query['pricing.hourlyRate'] = {};
    if (filters.minPrice) query['pricing.hourlyRate'].$gte = filters.minPrice;
    if (filters.maxPrice) query['pricing.hourlyRate'].$lte = filters.maxPrice;
  }

  // Rating filter
  if (filters.minRating) {
    query['stats.averageRating'] = { $gte: filters.minRating };
  }

  // Location filter
  if (filters.city) {
    query['location.city'] = { $regex: filters.city, $options: 'i' };
  }

  // Teaching mode filter
  if (filters.teachingMode) {
    if (filters.teachingMode === 'online') {
      query['teachingMode.online'] = true;
    } else if (filters.teachingMode === 'inPerson') {
      query['teachingMode.inPerson'] = true;
    }
  }

  return this.find(query)
    .populate('userId', 'firstName lastName profilePicture')
    .sort({ 'stats.averageRating': -1, 'stats.totalReviews': -1 });
};

module.exports = mongoose.model('TutorProfile', tutorProfileSchema);