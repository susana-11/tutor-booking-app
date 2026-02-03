const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor-booking', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const User = require('../models/User');

async function fixEmailVerification() {
  try {
    console.log('🔍 Checking user email verification status...');
    
    // Find all users
    const users = await User.find({});
    console.log(`📊 Found ${users.length} users`);
    
    for (const user of users) {
      console.log(`👤 User: ${user.email}`);
      console.log(`   - Email Verified: ${user.isEmailVerified}`);
      console.log(`   - Role: ${user.role}`);
      console.log(`   - Active: ${user.isActive}`);
      console.log(`   - Profile Completed: ${user.profileCompleted}`);
      
      if (user.emailOTP) {
        console.log(`   - Has pending OTP: ${user.emailOTP.code} (expires: ${user.emailOTP.expiresAt})`);
      }
      
      console.log('');
    }
    
    // Ask if you want to verify all users for testing
    console.log('🤔 Do you want to mark all users as email verified for testing?');
    console.log('   This will allow them to login without OTP verification.');
    console.log('   Run with --verify-all flag to proceed');
    
    if (process.argv.includes('--verify-all')) {
      console.log('✅ Marking all users as email verified...');
      
      const result = await User.updateMany(
        { isEmailVerified: false },
        { 
          $set: { isEmailVerified: true },
          $unset: { emailOTP: 1 }
        }
      );
      
      console.log(`✅ Updated ${result.modifiedCount} users`);
    }
    
    console.log('🎉 Email verification check completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error checking email verification:', error);
    process.exit(1);
  }
}

fixEmailVerification();