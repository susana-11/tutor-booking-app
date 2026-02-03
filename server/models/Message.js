const mongoose = require('mongoose');

const attachmentSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  url: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['image', 'document', 'audio', 'video'],
    required: true
  },
  size: {
    type: Number,
    required: true
  },
  mimeType: String,
  thumbnail: String,
  duration: Number // Duration in seconds for audio/voice messages
});

const messageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  content: {
    type: String,
    required: true,
    trim: true
  },
  
  type: {
    type: String,
    enum: ['text', 'image', 'document', 'audio', 'video', 'voice', 'system', 'booking', 'payment'],
    default: 'text'
  },
  
  attachments: [attachmentSchema],
  
  // Reply functionality
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message'
  },
  
  // Message status
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read'],
    default: 'sent'
  },
  
  // Read receipts
  readBy: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Edit functionality
  isEdited: {
    type: Boolean,
    default: false
  },
  
  editedAt: Date,
  
  originalContent: String,
  
  // Deletion
  isDeleted: {
    type: Boolean,
    default: false
  },
  
  deletedAt: Date,
  
  deletedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  
  // System message data
  systemData: {
    type: mongoose.Schema.Types.Mixed
  },
  
  // Booking/Payment related data
  relatedBooking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking'
  },
  
  relatedPayment: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment'
  }
}, {
  timestamps: true
});

// Indexes for better performance
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1 });
messageSchema.index({ createdAt: -1 });
messageSchema.index({ 'readBy.userId': 1 });

// Virtual fields
messageSchema.virtual('isRead').get(function() {
  return this.readBy && this.readBy.length > 0;
});

// Methods
messageSchema.methods.markAsRead = function(userId) {
  const existingRead = this.readBy.find(r => r.userId.toString() === userId.toString());
  
  if (!existingRead) {
    this.readBy.push({
      userId: userId,
      readAt: new Date()
    });
    this.status = 'read';
    return this.save();
  }
  
  return Promise.resolve(this);
};

messageSchema.methods.editContent = function(newContent, editedBy) {
  if (this.senderId.toString() !== editedBy.toString()) {
    throw new Error('Only the sender can edit this message');
  }
  
  this.originalContent = this.content;
  this.content = newContent;
  this.isEdited = true;
  this.editedAt = new Date();
  
  return this.save();
};

messageSchema.methods.softDelete = function(deletedBy) {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.deletedBy = deletedBy;
  
  return this.save();
};

// Static methods
messageSchema.statics.findConversationMessages = function(conversationId, options = {}) {
  const {
    page = 1,
    limit = 50,
    before = null
  } = options;

  const filter = {
    conversationId,
    isDeleted: false
  };

  if (before) {
    filter.createdAt = { $lt: new Date(before) };
  }

  return this.find(filter)
    .populate('senderId', 'firstName lastName profilePicture')
    .populate('replyTo')
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip((page - 1) * limit);
};

messageSchema.statics.getUnreadCount = function(userId, conversationId = null) {
  const filter = {
    'readBy.userId': { $ne: userId },
    senderId: { $ne: userId },
    isDeleted: false
  };

  if (conversationId) {
    filter.conversationId = conversationId;
  }

  return this.countDocuments(filter);
};

messageSchema.statics.markConversationAsRead = function(conversationId, userId) {
  return this.updateMany(
    {
      conversationId,
      senderId: { $ne: userId },
      'readBy.userId': { $ne: userId },
      isDeleted: false
    },
    {
      $push: {
        readBy: {
          userId: userId,
          readAt: new Date()
        }
      },
      $set: {
        status: 'read'
      }
    }
  );
};

messageSchema.statics.searchMessages = function(query, userId, options = {}) {
  const {
    conversationId = null,
    page = 1,
    limit = 20
  } = options;

  const filter = {
    $text: { $search: query },
    isDeleted: false
  };

  // Only search in conversations where user is a participant
  if (conversationId) {
    filter.conversationId = conversationId;
  }

  return this.find(filter)
    .populate('senderId', 'firstName lastName profilePicture')
    .populate('conversationId')
    .sort({ score: { $meta: 'textScore' }, createdAt: -1 })
    .limit(limit)
    .skip((page - 1) * limit);
};

// Text index for search
messageSchema.index({ content: 'text' });

// Pre-save middleware
messageSchema.pre('save', async function(next) {
  if (this.isNew) {
    // Update conversation's last message and activity
    const Conversation = mongoose.model('Conversation');
    await Conversation.findByIdAndUpdate(this.conversationId, {
      lastMessage: this._id,
      lastActivity: new Date()
    });
  }
  next();
});

// Post-save middleware
messageSchema.post('save', async function(doc) {
  // Emit socket event for real-time updates
  const io = require('../socket/socketHandler');
  if (io && io.emit) {
    io.emit('new_message', {
      conversationId: doc.conversationId,
      message: doc
    });
  }
});

module.exports = mongoose.model('Message', messageSchema);