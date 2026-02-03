const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  participants: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    role: {
      type: String,
      enum: ['student', 'tutor'],
      required: true
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    lastReadAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  subject: {
    type: String,
    trim: true
  },
  
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message'
  },
  
  lastActivity: {
    type: Date,
    default: Date.now
  },
  
  // Conversation settings
  isArchived: {
    type: Boolean,
    default: false
  },
  
  isPinned: {
    type: Boolean,
    default: false
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Metadata
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Related booking/session
  relatedBooking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking'
  }
}, {
  timestamps: true
});

// Indexes for better performance
conversationSchema.index({ 'participants.userId': 1 });
conversationSchema.index({ lastActivity: -1 });
conversationSchema.index({ createdAt: -1 });

// Virtual for unread count per user
conversationSchema.virtual('unreadCount').get(function() {
  // This will be calculated in the query
  return this._unreadCount || 0;
});

// Methods
conversationSchema.methods.getParticipant = function(userId) {
  return this.participants.find(p => p.userId.toString() === userId.toString());
};

conversationSchema.methods.getOtherParticipant = function(userId) {
  const userIdStr = userId.toString();
  return this.participants.find(p => {
    const participantIdStr = p.userId._id ? p.userId._id.toString() : p.userId.toString();
    return participantIdStr !== userIdStr;
  });
};

conversationSchema.methods.updateLastActivity = function() {
  this.lastActivity = new Date();
  return this.save();
};

conversationSchema.methods.markAsRead = function(userId) {
  const participant = this.getParticipant(userId);
  if (participant) {
    participant.lastReadAt = new Date();
    return this.save();
  }
  return Promise.resolve(this);
};

// Static methods
conversationSchema.statics.findByParticipants = function(userId1, userId2) {
  return this.findOne({
    'participants.userId': { $all: [userId1, userId2] },
    isActive: true
  });
};

conversationSchema.statics.findUserConversations = function(userId, options = {}) {
  const {
    page = 1,
    limit = 20,
    includeArchived = false
  } = options;

  const filter = {
    'participants.userId': userId,
    isActive: true
  };

  if (!includeArchived) {
    filter.isArchived = false;
  }

  return this.find(filter)
    .populate('participants.userId', 'firstName lastName email profilePicture role')
    .populate('lastMessage')
    .sort({ isPinned: -1, lastActivity: -1 })
    .limit(limit)
    .skip((page - 1) * limit);
};

// Pre-save middleware
conversationSchema.pre('save', function(next) {
  if (this.isModified('lastMessage')) {
    this.lastActivity = new Date();
  }
  next();
});

module.exports = mongoose.model('Conversation', conversationSchema);