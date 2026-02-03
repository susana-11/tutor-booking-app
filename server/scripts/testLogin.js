require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

async function testLogin() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const email = 'bubuam13@gmail.com';
    const password = '123abc';

    console.log(`\n🔍 Looking for user: ${email}`);
    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      console.log('❌ User not found!');
      process.exit(1);
    }

    console.log('✅ User found!');
    console.log('User details:');
    console.log('  - ID:', user._id);
    console.log('  - Name:', user.firstName, user.lastName);
    console.log('  - Email:', user.email);
    console.log('  - Role:', user.role);
    console.log('  - Email Verified:', user.isEmailVerified);
    console.log('  - Profile Completed:', user.profileCompleted);
    console.log('  - Is Active:', user.isActive);
    console.log('  - Password Hash:', user.password.substring(0, 20) + '...');

    console.log(`\n🔐 Testing password: "${password}"`);
    const isMatch = await bcrypt.compare(password, user.password);
    
    if (isMatch) {
      console.log('✅ Password matches!');
    } else {
      console.log('❌ Password does NOT match!');
      
      // Try to create a new hash and compare
      console.log('\n🔧 Creating new hash for comparison...');
      const newHash = await bcrypt.hash(password, 10);
      console.log('New hash:', newHash.substring(0, 20) + '...');
      const newMatch = await bcrypt.compare(password, newHash);
      console.log('New hash matches:', newMatch);
    }

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testLogin();
