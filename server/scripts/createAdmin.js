const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor-booking', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// User schema (simplified)
const userSchema = new mongoose.Schema({
  firstName: String,
  lastName: String,
  email: { type: String, unique: true },
  password: String,
  phone: String,
  role: String,
  isEmailVerified: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  profileCompleted: { type: Boolean, default: false },
}, { timestamps: true });

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

const User = mongoose.model('User', userSchema);

async function createAdminUser() {
  try {
    console.log('🔧 Creating admin user...');
    
    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@tutorbooking.com' });
    if (existingAdmin) {
      console.log('✅ Admin user already exists');
      process.exit(0);
    }
    
    // Create admin user
    const adminUser = new User({
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@tutorbooking.com',
      password: 'admin123',
      phone: '+1234567890',
      role: 'admin',
      isEmailVerified: true,
      isActive: true,
      profileCompleted: true,
    });
    
    await adminUser.save();
    console.log('✅ Admin user created successfully!');
    console.log('📧 Email: admin@tutorbooking.com');
    console.log('🔑 Password: admin123');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
    process.exit(1);
  }
}

// Wait for MongoDB connection
mongoose.connection.once('open', () => {
  console.log('✅ Connected to MongoDB');
  createAdminUser();
});

mongoose.connection.on('error', (error) => {
  console.error('❌ MongoDB connection error:', error);
  process.exit(1);
});