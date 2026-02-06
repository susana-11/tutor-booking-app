const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  balance: {
    type: Number,
    default: 0,
    min: 0
  },
  currency: {
    type: String,
    default: 'ETB',
    enum: ['ETB']
  },
  escrowBalance: {
    type: Number,
    default: 0,
    min: 0
  },
  // Lifetime statistics
  totalDeposited: {
    type: Number,
    default: 0,
    min: 0
  },
  totalSpent: {
    type: Number,
    default: 0,
    min: 0
  },
  totalWithdrawn: {
    type: Number,
    default: 0,
    min: 0
  },
  totalRefunded: {
    type: Number,
    default: 0,
    min: 0
  },
  totalEarned: {
    type: Number,
    default: 0,
    min: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isFrozen: {
    type: Boolean,
    default: false
  },
  frozenReason: String,
  frozenAt: Date,
  lastTransactionAt: Date,
  // Metadata
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

// Indexes
walletSchema.index({ userId: 1 });
walletSchema.index({ isActive: 1 });
walletSchema.index({ isFrozen: 1 });

// Virtual for available balance (balance - escrow)
walletSchema.virtual('availableBalance').get(function() {
  return this.balance;
});

// Virtual for total balance (balance + escrow)
walletSchema.virtual('totalBalance').get(function() {
  return this.balance + this.escrowBalance;
});

// Method to check if wallet has sufficient balance
walletSchema.methods.hasSufficientBalance = function(amount) {
  return this.balance >= amount && !this.isFrozen;
};

// Method to add balance
walletSchema.methods.addBalance = async function(amount, description = 'Balance added') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  this.balance += amount;
  this.totalDeposited += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to deduct balance
walletSchema.methods.deductBalance = async function(amount, description = 'Balance deducted') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  if (!this.hasSufficientBalance(amount)) {
    throw new Error('Insufficient balance');
  }
  
  this.balance -= amount;
  this.totalSpent += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to move balance to escrow
walletSchema.methods.moveToEscrow = async function(amount, description = 'Moved to escrow') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  if (!this.hasSufficientBalance(amount)) {
    throw new Error('Insufficient balance');
  }
  
  this.balance -= amount;
  this.escrowBalance += amount;
  this.totalSpent += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to release from escrow
walletSchema.methods.releaseFromEscrow = async function(amount, description = 'Released from escrow') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  if (this.escrowBalance < amount) {
    throw new Error('Insufficient escrow balance');
  }
  
  this.escrowBalance -= amount;
  this.balance += amount;
  this.totalEarned += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to refund to balance
walletSchema.methods.refundToBalance = async function(amount, description = 'Refund') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  this.balance += amount;
  this.totalRefunded += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to refund from escrow
walletSchema.methods.refundFromEscrow = async function(amount, description = 'Refund from escrow') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  if (this.escrowBalance < amount) {
    throw new Error('Insufficient escrow balance');
  }
  
  this.escrowBalance -= amount;
  this.balance += amount;
  this.totalRefunded += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to withdraw
walletSchema.methods.withdraw = async function(amount, description = 'Withdrawal') {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  if (!this.hasSufficientBalance(amount)) {
    throw new Error('Insufficient balance');
  }
  
  this.balance -= amount;
  this.totalWithdrawn += amount;
  this.lastTransactionAt = new Date();
  
  return await this.save();
};

// Method to freeze wallet
walletSchema.methods.freeze = async function(reason) {
  this.isFrozen = true;
  this.frozenReason = reason;
  this.frozenAt = new Date();
  
  return await this.save();
};

// Method to unfreeze wallet
walletSchema.methods.unfreeze = async function() {
  this.isFrozen = false;
  this.frozenReason = undefined;
  this.frozenAt = undefined;
  
  return await this.save();
};

// Static method to get or create wallet
walletSchema.statics.getOrCreate = async function(userId) {
  let wallet = await this.findOne({ userId });
  
  if (!wallet) {
    wallet = await this.create({ userId });
  }
  
  return wallet;
};

// Static method to get wallet with user details
walletSchema.statics.getWalletWithUser = async function(userId) {
  return await this.findOne({ userId })
    .populate('userId', 'firstName lastName email phone role profilePicture');
};

module.exports = mongoose.model('Wallet', walletSchema);
