const mongoose = require('mongoose');

const studentProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  
  // Basic Information
  dateOfBirth: {
    type: Date,
    required: [true, 'Date of birth is required']
  },
  grade: {
    type: String,
    enum: [
      'K', '1', '2', '3', '4', '5', // Elementary
      '6', '7', '8', // Middle School
      '9', '10', '11', '12', // High School
      'College Freshman', 'College Sophomore', 'College Junior', 'College Senior',
      'Graduate Student', 'Adult Learner'
    ],
    required: [true, 'Grade level is required']
  },
  
  // Academic Information
  school: {
    name: String,
    type: {
      type: String,
      enum: ['Public', 'Private', 'Charter', 'Homeschool', 'Online', 'University', 'Other']
    },
    address: {
      city: String,
      state: String,
      country: String
    }
  },
  
  // Learning Profile
  learningStyle: {
    type: String,
    enum: ['Visual', 'Auditory', 'Kinesthetic', 'Reading/Writing', 'Mixed']
  },
  academicGoals: [String],
  subjectsOfInterest: [String],
  challengingSubjects: [String],
  
  // Personal Information
  bio: {
    type: String,
    maxlength: [500, 'Bio cannot exceed 500 characters']
  },
  interests: [String],
  hobbies: [String],
  
  // Learning Preferences
  preferredTutoringMode: {
    type: String,
    enum: ['online', 'inPerson', 'both'],
    default: 'both'
  },
  preferredSessionLength: {
    type: Number,
    enum: [30, 45, 60, 90, 120], // in minutes
    default: 60
  },
  preferredTimeSlots: [{
    day: {
      type: String,
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    },
    startTime: String, // HH:MM format
    endTime: String    // HH:MM format
  }],
  timezone: {
    type: String,
    default: 'UTC'
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
    }
  },
  
  // Parent/Guardian Information (for minors)
  parentGuardian: {
    isMinor: {
      type: Boolean,
      default: function() {
        if (!this.dateOfBirth) return false;
        const age = Math.floor((Date.now() - this.dateOfBirth.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
        return age < 18;
      }
    },
    parentName: String,
    parentEmail: String,
    parentPhone: String,
    relationship: {
      type: String,
      enum: ['Parent', 'Guardian', 'Other']
    },
    canBookSessions: {
      type: Boolean,
      default: true
    },
    receiveNotifications: {
      type: Boolean,
      default: true
    }
  },
  
  // Academic Performance Tracking
  academicProgress: [{
    subject: String,
    currentLevel: String,
    targetLevel: String,
    progress: {
      type: Number,
      min: 0,
      max: 100,
      default: 0
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Session History and Statistics
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
    totalHoursLearned: {
      type: Number,
      default: 0
    },
    favoriteSubjects: [String],
    averageSessionRating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    totalSpent: {
      type: Number,
      default: 0
    }
  },
  
  // Preferences and Settings
  preferences: {
    notifications: {
      email: {
        bookingConfirmation: { type: Boolean, default: true },
        sessionReminders: { type: Boolean, default: true },
        tutorMessages: { type: Boolean, default: true },
        progressUpdates: { type: Boolean, default: true }
      },
      push: {
        bookingConfirmation: { type: Boolean, default: true },
        sessionReminders: { type: Boolean, default: true },
        tutorMessages: { type: Boolean, default: true }
      }
    },
    privacy: {
      showProfile: { type: Boolean, default: true },
      showProgress: { type: Boolean, default: false },
      allowTutorContact: { type: Boolean, default: true }
    },
    booking: {
      requireConfirmation: { type: Boolean, default: true },
      autoReschedule: { type: Boolean, default: false },
      reminderTime: { type: Number, default: 60 } // minutes before session
    }
  },
  
  // Emergency Contact
  emergencyContact: {
    name: String,
    relationship: String,
    phone: String,
    email: String
  },
  
  // Special Needs or Accommodations
  specialNeeds: {
    hasSpecialNeeds: {
      type: Boolean,
      default: false
    },
    accommodations: [String],
    notes: String
  }
}, {
  timestamps: true
});

// Indexes
studentProfileSchema.index({ userId: 1 });
studentProfileSchema.index({ grade: 1 });
studentProfileSchema.index({ 'school.name': 1 });
studentProfileSchema.index({ subjectsOfInterest: 1 });
studentProfileSchema.index({ 'location.city': 1 });

// Virtual for age
studentProfileSchema.virtual('age').get(function() {
  if (!this.dateOfBirth) return null;
  return Math.floor((Date.now() - this.dateOfBirth.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
});

// Virtual for completion percentage
studentProfileSchema.virtual('completionPercentage').get(function() {
  let completed = 0;
  let total = 8;
  
  if (this.dateOfBirth) completed++;
  if (this.grade) completed++;
  if (this.school && this.school.name) completed++;
  if (this.subjectsOfInterest && this.subjectsOfInterest.length > 0) completed++;
  if (this.learningStyle) completed++;
  if (this.location && this.location.city) completed++;
  if (this.preferredTimeSlots && this.preferredTimeSlots.length > 0) completed++;
  if (this.bio) completed++;
  
  return Math.round((completed / total) * 100);
});

// Method to update statistics
studentProfileSchema.methods.updateStats = async function() {
  const Booking = mongoose.model('Booking');
  const Review = mongoose.model('Review');
  
  // Get booking statistics
  const bookingStats = await Booking.aggregate([
    { $match: { studentId: this.userId } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalSpent: { $sum: '$totalAmount' },
        totalHours: { $sum: '$duration' }
      }
    }
  ]);
  
  // Get review statistics
  const reviewStats = await Review.aggregate([
    { $match: { studentId: this.userId } },
    {
      $group: {
        _id: null,
        averageRating: { $avg: '$rating' }
      }
    }
  ]);
  
  // Update stats
  let totalSessions = 0;
  let completedSessions = 0;
  let cancelledSessions = 0;
  let totalSpent = 0;
  let totalHours = 0;
  
  bookingStats.forEach(stat => {
    totalSessions += stat.count;
    if (stat._id === 'completed') {
      completedSessions = stat.count;
      totalSpent = stat.totalSpent || 0;
      totalHours = stat.totalHours || 0;
    }
    if (stat._id === 'cancelled') {
      cancelledSessions = stat.count;
    }
  });
  
  this.stats.totalSessions = totalSessions;
  this.stats.completedSessions = completedSessions;
  this.stats.cancelledSessions = cancelledSessions;
  this.stats.totalSpent = totalSpent;
  this.stats.totalHoursLearned = Math.round(totalHours / 60 * 100) / 100; // Convert minutes to hours
  
  if (reviewStats.length > 0) {
    this.stats.averageSessionRating = Math.round(reviewStats[0].averageRating * 10) / 10;
  }
  
  return this.save();
};

// Method to add academic progress
studentProfileSchema.methods.updateAcademicProgress = function(subject, currentLevel, targetLevel, progress) {
  const existingProgress = this.academicProgress.find(p => p.subject === subject);
  
  if (existingProgress) {
    existingProgress.currentLevel = currentLevel;
    existingProgress.targetLevel = targetLevel;
    existingProgress.progress = progress;
    existingProgress.lastUpdated = new Date();
  } else {
    this.academicProgress.push({
      subject,
      currentLevel,
      targetLevel,
      progress,
      lastUpdated: new Date()
    });
  }
  
  return this.save();
};

// Static method to get students by grade
studentProfileSchema.statics.getByGrade = function(grade) {
  return this.find({ grade }).populate('userId', 'firstName lastName profilePicture');
};

// Static method to get students needing help in specific subjects
studentProfileSchema.statics.getByChallengingSubject = function(subject) {
  return this.find({ challengingSubjects: subject })
    .populate('userId', 'firstName lastName profilePicture');
};

module.exports = mongoose.model('StudentProfile', studentProfileSchema);