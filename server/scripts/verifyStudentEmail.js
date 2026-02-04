require('dotenv').config();
const mongoose = require('mongoose');

async function verifyEmail() {
  try {
    console.log('🔧 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const User = require('../models/User');

    const email = 'posuzi23@gmail.com';

    console.log(`\n🔍 Looking for user: ${email}`);
    const user = await User.findOne({ email });

    if (!user) {
      console.log('❌ User not found!');
      process.exit(1);
    }

    console.log('✅ User found:');
    console.log('   ID:', user._id);
    console.log('   Name:', user.firstName, user.lastName);
    console.log('   Email Verified:', user.isEmailVerified);

    if (user.isEmailVerified) {
      console.log('\n✅ Email already verified!');
    } else {
      console.log('\n🔧 Verifying email...');
      user.isEmailVerified = true;
      user.emailOTP = undefined;
      await user.save();
      console.log('✅ Email verified successfully!');
    }

    console.log('\n📱 You can now login with:');
    console.log('   Email:', email);
    console.log('   Password: abcdef');

    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

verifyEmail();
