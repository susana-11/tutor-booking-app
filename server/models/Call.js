const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  callId: {
    type: String,
    required: true,
    unique: true
  },
  
  channelName: {
    type: String,
    required: true
  },
  
  callType: {
    type: String,
    enum: ['voice', 'video'],
    required: true
  },
  
  initiatorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  receiverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking'
  },
  
  status: {
    type: String,
    enum: ['initiated', 'ringing', 'answered', 'ended', 'missed', 'rejected', 'failed', 'busy'],
    default: 'initiated'
  },
  
  startTime: Date,
  endTime: Date,
  
  duration: {
    type: Number, // in seconds
    default: 0
  },
  
  // Agora tokens (stored for reference, regenerated if needed)
  initiatorToken: String,
  receiverToken: String,
  
  // Call quality metrics
  quality: {
    networkType: String,
    avgBitrate: Number,
    packetLoss: Number
  },
  
  // Recording info (if enabled)
  recordingId: String,
  recordingUrl: String,
  
  // Metadata
  metadata: {
    initiatorDevice: String,
    receiverDevice: String,
    endReason: String // 'normal', 'timeout', 'error', 'rejected'
  }
}, {
  timestamps: true
});

// Indexes
callSchema.index({ initiatorId: 1, createdAt: -1 });
callSchema.index({ receiverId: 1, createdAt: -1 });
callSchema.index({ callId: 1 });
callSchema.index({ status: 1 });
callSchema.index({ bookingId: 1 });

// Virtual for call participants
callSchema.virtual('participants', {
  ref: 'User',
  localField: '_id',
  foreignField: '_id'
});

// Methods
callSchema.methods.calculateDuration = function() {
  if (this.startTime && this.endTime) {
    this.duration = Math.floor((this.endTime - this.startTime) / 1000);
  }
  return this.duration;
};

// Static methods
callSchema.statics.getCallHistory = function(userId, options = {}) {
  const {
    page = 1,
    limit = 20,
    callType = null,
    status = null
  } = options;

  const filter = {
    $or: [
      { initiatorId: userId },
      { receiverId: userId }
    ]
  };

  if (callType) filter.callType = callType;
  if (status) filter.status = status;

  return this.find(filter)
    .populate('initiatorId', 'firstName lastName profilePicture')
    .populate('receiverId', 'firstName lastName profilePicture')
    .populate('bookingId', 'subject scheduledTime')
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip((page - 1) * limit);
};

callSchema.statics.getMissedCalls = function(userId) {
  return this.find({
    receiverId: userId,
    status: 'missed'
  })
    .populate('initiatorId', 'firstName lastName profilePicture')
    .sort({ createdAt: -1 })
    .limit(10);
};

callSchema.statics.getCallStats = async function(userId, period = 'month') {
  const startDate = new Date();
  
  switch(period) {
    case 'week':
      startDate.setDate(startDate.getDate() - 7);
      break;
    case 'month':
      startDate.setMonth(startDate.getMonth() - 1);
      break;
    case 'year':
      startDate.setFullYear(startDate.getFullYear() - 1);
      break;
  }

  const stats = await this.aggregate([
    {
      $match: {
        $or: [
          { initiatorId: new mongoose.Types.ObjectId(userId) },
          { receiverId: new mongoose.Types.ObjectId(userId) }
        ],
        createdAt: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalDuration: { $sum: '$duration' }
      }
    }
  ]);

  return stats;
};

module.exports = mongoose.model('Call', callSchema);
