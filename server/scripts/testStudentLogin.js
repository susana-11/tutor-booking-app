require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function testLogin() {
  try {
    console.log('🔧 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const User = require('../models/User');

    const email = 'etsebruk.test@gmail.com';
    const password = '123abc';

    console.log(`\n🔍 Testing login for: ${email}`);
    console.log(`   Password: ${password}`);

    // Find user with password field
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      console.log('❌ User not found!');
      process.exit(1);
    }

    console.log('\n✅ User found:');
    console.log('   ID:', user._id);
    console.log('   Name:', user.firstName, user.lastName);
    console.log('   Email:', user.email);
    console.log('   Role:', user.role);
    console.log('   Email Verified:', user.isEmailVerified);
    console.log('   Is Active:', user.isActive);
    console.log('   Password Hash:', user.password.substring(0, 20) + '...');

    // Test password comparison
    console.log('\n🔐 Testing password comparison...');
    const isValid = await user.comparePassword(password);

    if (isValid) {
      console.log('✅ Password is CORRECT!');
      console.log('\n📱 Login should work with:');
      console.log('   Email:', email);
      console.log('   Password:', password);
    } else {
      console.log('❌ Password is INCORRECT!');
      console.log('\n🔧 Let me check the password hash...');
      
      // Try direct bcrypt compare
      const directCompare = await bcrypt.compare(password, user.password);
      console.log('   Direct bcrypt.compare result:', directCompare);
      
      if (directCompare) {
        console.log('   ✅ Direct comparison works! Issue might be with comparePassword method');
      } else {
        console.log('   ❌ Direct comparison also fails! Password hash is wrong');
        console.log('\n🔧 Regenerating password...');
        
        const salt = await bcrypt.genSalt(12);
        const newHash = await bcrypt.hash(password, salt);
        
        await User.updateOne(
          { _id: user._id },
          { $set: { password: newHash } }
        );
        
        console.log('✅ Password regenerated!');
        
        // Test again
        const updatedUser = await User.findById(user._id).select('+password');
        const finalTest = await bcrypt.compare(password, updatedUser.password);
        console.log('   Final test result:', finalTest ? '✅ SUCCESS' : '❌ FAILED');
      }
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testLogin();
