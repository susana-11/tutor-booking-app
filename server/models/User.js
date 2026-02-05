const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Check if we should use mock database
let User;

try {
  // Try to use real MongoDB model
  const userSchema = new mongoose.Schema({
    firstName: {
      type: String,
      required: [true, 'First name is required'],
      trim: true,
      maxlength: [50, 'First name cannot exceed 50 characters']
    },
    lastName: {
      type: String,
      required: [true, 'Last name is required'],
      trim: true,
      maxlength: [50, 'Last name cannot exceed 50 characters']
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      match: [/^\+?[\d\s-()]+$/, 'Please enter a valid phone number']
    },
    role: {
      type: String,
      enum: ['student', 'tutor', 'admin'],
      required: [true, 'Role is required']
    },
    profilePicture: {
      type: String,
      default: null
    },
    isEmailVerified: {
      type: Boolean,
      default: false
    },
    isPhoneVerified: {
      type: Boolean,
      default: false
    },
    isActive: {
      type: Boolean,
      default: true
    },
    lastLogin: {
      type: Date,
      default: null
    },
    lastLogout: {
      type: Date,
      default: null
    },
    // OTP for verification
    emailOTP: {
      code: String,
      expiresAt: Date
    },
    phoneOTP: {
      code: String,
      expiresAt: Date
    },
    // Password reset
    passwordResetToken: String,
    passwordResetExpires: Date,
    // Profile completion
    profileCompleted: {
      type: Boolean,
      default: false
    },
    // Notification preferences
    notificationPreferences: {
      emailNotifications: {
        type: Boolean,
        default: true
      },
      pushNotifications: {
        type: Boolean,
        default: true
      },
      bookingNotifications: {
        type: Boolean,
        default: true
      },
      messageNotifications: {
        type: Boolean,
        default: true
      },
      reviewNotifications: {
        type: Boolean,
        default: true
      },
      paymentNotifications: {
        type: Boolean,
        default: true
      },
      reminderNotifications: {
        type: Boolean,
        default: true
      },
      promotionalNotifications: {
        type: Boolean,
        default: false
      }
    }
  }, {
    timestamps: true
  });

  // Indexes
  userSchema.index({ email: 1 });
  userSchema.index({ role: 1 });
  userSchema.index({ isActive: 1 });

  // Virtual for full name
  userSchema.virtual('fullName').get(function() {
    return `${this.firstName} ${this.lastName}`;
  });

  // Hash password before saving
  userSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    
    try {
      const salt = await bcrypt.genSalt(12);
      this.password = await bcrypt.hash(this.password, salt);
      next();
    } catch (error) {
      next(error);
    }
  });

  // Compare password method
  userSchema.methods.comparePassword = async function(candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
  };

  // Generate OTP
  userSchema.methods.generateOTP = function() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  };

  // Set email OTP
  userSchema.methods.setEmailOTP = function() {
    const otp = this.generateOTP();
    this.emailOTP = {
      code: otp,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    };
    return otp;
  };

  // Set phone OTP
  userSchema.methods.setPhoneOTP = function() {
    const otp = this.generateOTP();
    this.phoneOTP = {
      code: otp,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    };
    return otp;
  };

  // Verify email OTP
  userSchema.methods.verifyEmailOTP = function(otp) {
    if (!this.emailOTP || !this.emailOTP.code) return false;
    if (this.emailOTP.expiresAt < new Date()) return false;
    return this.emailOTP.code === otp;
  };

  // Verify phone OTP
  userSchema.methods.verifyPhoneOTP = function(otp) {
    if (!this.phoneOTP || !this.phoneOTP.code) return false;
    if (this.phoneOTP.expiresAt < new Date()) return false;
    return this.phoneOTP.code === otp;
  };

  // Clear OTPs
  userSchema.methods.clearOTPs = function() {
    this.emailOTP = undefined;
    this.phoneOTP = undefined;
  };

  User = mongoose.model('User', userSchema);
} catch (error) {
  // If MongoDB is not available, use mock database
  console.log('🔧 MongoDB not available, using mock database');
  const { User: MockUser } = require('../utils/mockDatabase');
  User = MockUser;
}

module.exports = User;