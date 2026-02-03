const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['payment', 'withdrawal', 'refund', 'platform_fee'],
    required: true,
    index: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  fee: {
    type: Number,
    default: 0,
    min: 0
  },
  netAmount: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'pending',
    index: true
  },
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    index: true
  },
  // Chapa specific fields
  chapaReference: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  chapaTransactionId: String,
  chapaStatus: String,
  // Bank account details (for withdrawals)
  bankAccount: {
    accountNumber: String,
    accountName: String,
    bankName: String
  },
  description: {
    type: String,
    required: true
  },
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  },
  // For payment tracking
  paidAt: Date,
  processedAt: Date,
  failedAt: Date,
  failureReason: String,
  // Idempotency
  idempotencyKey: {
    type: String,
    unique: true,
    sparse: true
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ type: 1, status: 1 });
transactionSchema.index({ chapaReference: 1 });
transactionSchema.index({ bookingId: 1 });

// Virtual for display amount
transactionSchema.virtual('displayAmount').get(function() {
  return `ETB ${this.amount.toFixed(2)}`;
});

// Method to mark as completed
transactionSchema.methods.markCompleted = async function() {
  this.status = 'completed';
  this.processedAt = new Date();
  return await this.save();
};

// Method to mark as failed
transactionSchema.methods.markFailed = async function(reason) {
  this.status = 'failed';
  this.failedAt = new Date();
  this.failureReason = reason;
  return await this.save();
};

// Static method to get user transaction history
transactionSchema.statics.getUserTransactions = async function(userId, filters = {}) {
  const query = { userId };
  
  if (filters.type) query.type = filters.type;
  if (filters.status) query.status = filters.status;
  if (filters.startDate || filters.endDate) {
    query.createdAt = {};
    if (filters.startDate) query.createdAt.$gte = new Date(filters.startDate);
    if (filters.endDate) query.createdAt.$lte = new Date(filters.endDate);
  }
  
  return await this.find(query)
    .populate('bookingId', 'sessionDate startTime endTime subject')
    .sort({ createdAt: -1 })
    .limit(filters.limit || 50);
};

// Static method to get transaction summary
transactionSchema.statics.getTransactionSummary = async function(userId, startDate, endDate) {
  const transactions = await this.find({
    userId,
    status: 'completed',
    createdAt: { $gte: startDate, $lte: endDate }
  });
  
  const summary = {
    totalPayments: 0,
    totalWithdrawals: 0,
    totalFees: 0,
    totalRefunds: 0,
    transactionCount: transactions.length
  };
  
  transactions.forEach(txn => {
    switch(txn.type) {
      case 'payment':
        summary.totalPayments += txn.amount;
        break;
      case 'withdrawal':
        summary.totalWithdrawals += txn.netAmount;
        summary.totalFees += txn.fee;
        break;
      case 'refund':
        summary.totalRefunds += txn.amount;
        break;
    }
  });
  
  return summary;
};

module.exports = mongoose.model('Transaction', transactionSchema);
