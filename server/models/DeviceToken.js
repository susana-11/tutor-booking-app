const mongoose = require('mongoose');

const deviceTokenSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  token: {
    type: String,
    required: true,
    unique: true
  },
  platform: {
    type: String,
    enum: ['android', 'ios', 'web'],
    required: true
  },
  deviceId: String,
  deviceName: String,
  appVersion: String,
  isActive: {
    type: Boolean,
    default: true
  },
  lastUsedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for efficient queries
deviceTokenSchema.index({ userId: 1, isActive: 1 });
deviceTokenSchema.index({ token: 1 }, { unique: true });

// Update last used timestamp
deviceTokenSchema.methods.updateLastUsed = function() {
  this.lastUsedAt = new Date();
  return this.save();
};

module.exports = mongoose.model('DeviceToken', deviceTokenSchema);
