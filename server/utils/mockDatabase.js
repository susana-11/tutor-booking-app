// Simple in-memory mock database for development when MongoDB is not available
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

class MockDatabase {
  constructor() {
    this.users = new Map();
    this.isConnected = false;
    this.initializeAdminUser();
  }

  async initializeAdminUser() {
    // Create default admin user
    const adminEmail = 'admin@tutorbooking.com';
    const adminPassword = 'admin123';
    
    if (!this.users.has(adminEmail)) {
      const hashedPassword = await bcrypt.hash(adminPassword, 12);
      const adminUser = {
        _id: crypto.randomUUID(),
        firstName: 'Admin',
        lastName: 'User',
        email: adminEmail,
        password: hashedPassword,
        phone: '+1234567890',
        role: 'admin',
        profilePicture: null,
        isEmailVerified: true,
        isPhoneVerified: false,
        isActive: true,
        profileCompleted: true,
        lastLogin: null,
        emailOTP: null,
        emailOTPExpires: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        
        // Mock methods
        setEmailOTP() {
          const otp = Math.floor(100000 + Math.random() * 900000).toString();
          this.emailOTP = otp;
          this.emailOTPExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
          return otp;
        },
        
        verifyEmailOTP(otp) {
          if (!this.emailOTP || !this.emailOTPExpires) return false;
          if (new Date() > this.emailOTPExpires) return false;
          return this.emailOTP === otp;
        },
        
        async comparePassword(candidatePassword) {
          return await bcrypt.compare(candidatePassword, this.password);
        },
        
        clearOTPs() {
          this.emailOTP = null;
          this.emailOTPExpires = null;
        },
        
        save() {
          mockDB.users.set(this.email, this);
          return Promise.resolve(this);
        }
      };
      
      this.users.set(adminEmail, adminUser);
      console.log('🔧 Admin user created:', adminEmail);
    }
  }

  connect() {
    this.isConnected = true;
    console.log('🔧 Using mock database (MongoDB not available)');
    return Promise.resolve();
  }

  // Mock User model
  async createUser(userData) {
    // Hash password if provided
    if (userData.password) {
      userData.password = await bcrypt.hash(userData.password, 12);
    }
    
    const user = {
      _id: crypto.randomUUID(),
      ...userData,
      createdAt: new Date(),
      updatedAt: new Date(),
      isEmailVerified: false,
      isPhoneVerified: false,
      isActive: true,
      profileCompleted: false,
      emailOTP: null,
      emailOTPExpires: null,
      
      // Mock methods
      setEmailOTP() {
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        this.emailOTP = otp;
        this.emailOTPExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
        return otp;
      },
      
      verifyEmailOTP(otp) {
        if (!this.emailOTP || !this.emailOTPExpires) return false;
        if (new Date() > this.emailOTPExpires) return false;
        return this.emailOTP === otp;
      },
      
      async comparePassword(candidatePassword) {
        return await bcrypt.compare(candidatePassword, this.password);
      },
      
      clearOTPs() {
        this.emailOTP = null;
        this.emailOTPExpires = null;
      },
      
      save() {
        mockDB.users.set(this.email, this);
        return Promise.resolve(this);
      }
    };
    
    return user;
  }

  findUserByEmail(email) {
    return Promise.resolve(this.users.get(email) || null);
  }

  findUserById(id) {
    for (const user of this.users.values()) {
      if (user._id === id) {
        return Promise.resolve(user);
      }
    }
    return Promise.resolve(null);
  }
}

const mockDB = new MockDatabase();

// Mock User model that mimics Mongoose
const MockUser = {
  findOne: ({ email }) => mockDB.findUserByEmail(email),
  findById: (id) => mockDB.findUserById(id),
  create: async (userData) => {
    const user = await mockDB.createUser(userData);
    return user.save();
  }
};

// Constructor function to mimic Mongoose model
async function User(userData) {
  return await mockDB.createUser(userData);
}

// Add static methods
Object.assign(User, MockUser);

module.exports = { mockDB, User };