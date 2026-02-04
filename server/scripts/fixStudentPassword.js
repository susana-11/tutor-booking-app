require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function fixStudentPassword() {
  try {
    console.log('🔧 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const User = require('../models/User');

    // Find the student by email
    const email = 'etsebruk.test@gmail.com';
    const newPassword = '123abc';

    console.log(`\n🔍 Looking for user with email: ${email}`);
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      console.log('❌ User not found!');
      process.exit(1);
    }

    console.log('✅ User found:');
    console.log('   ID:', user._id);
    console.log('   Name:', user.firstName, user.lastName);
    console.log('   Email:', user.email);
    console.log('   Role:', user.role);
    console.log('   Email Verified:', user.isEmailVerified);

    // Hash the new password
    console.log('\n🔐 Hashing new password...');
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update password directly (bypass the pre-save hook)
    await User.updateOne(
      { _id: user._id },
      { $set: { password: hashedPassword } }
    );

    console.log('✅ Password updated successfully!');

    // Verify the password works
    console.log('\n🧪 Testing password...');
    const updatedUser = await User.findById(user._id).select('+password');
    const isValid = await bcrypt.compare(newPassword, updatedUser.password);

    if (isValid) {
      console.log('✅ Password verification successful!');
      console.log('\n📱 You can now login with:');
      console.log('   Email:', email);
      console.log('   Password:', newPassword);
    } else {
      console.log('❌ Password verification failed!');
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixStudentPassword();
