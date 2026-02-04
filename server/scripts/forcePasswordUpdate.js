// This script will update the password using the EXACT MongoDB connection
// Run this to ensure the password is updated in the correct database
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function forcePasswordUpdate() {
  try {
    const mongoURI = process.env.MONGODB_URI;
    console.log('🔧 MongoDB URI:', mongoURI.substring(0, 50) + '...');
    console.log('🔧 Connecting to MongoDB...');
    
    await mongoose.connect(mongoURI);
    console.log('✅ Connected to MongoDB');

    // Define User schema inline to avoid any caching issues
    const userSchema = new mongoose.Schema({
      firstName: String,
      lastName: String,
      email: String,
      password: String,
      role: String,
      isEmailVerified: Boolean,
      isActive: Boolean
    }, { collection: 'users' });

    const User = mongoose.model('UserForce', userSchema);

    const email = 'etsebruk.test@gmail.com';
    const password = '123abc';

    console.log(`\n🔍 Looking for user: ${email}`);
    
    // Find user
    let user = await User.findOne({ email });

    if (!user) {
      console.log('❌ User not found with new email!');
      console.log('🔍 Checking for old email...');
      user = await User.findOne({ email: 'etsebruk@example.com' });
      
      if (user) {
        console.log('✅ Found user with OLD email!');
        console.log('   Updating email AND password...');
        
        // Hash password
        const salt = await bcrypt.genSalt(12);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // Update both email and password
        await User.updateOne(
          { _id: user._id },
          { 
            $set: { 
              email: 'etsebruk.test@gmail.com',
              password: hashedPassword 
            } 
          }
        );
        
        console.log('✅ Email and password updated!');
      } else {
        console.log('❌ User not found with either email!');
        console.log('\n📋 All students in database:');
        const allStudents = await User.find({ role: 'student' });
        allStudents.forEach(s => {
          console.log(`   - ${s.firstName} ${s.lastName}: ${s.email}`);
        });
        process.exit(1);
      }
    } else {
      console.log('✅ User found with new email!');
      console.log('   ID:', user._id);
      console.log('   Name:', user.firstName, user.lastName);
      console.log('   Updating password only...');
      
      // Hash password
      const salt = await bcrypt.genSalt(12);
      const hashedPassword = await bcrypt.hash(password, salt);
      
      // Update password
      await User.updateOne(
        { _id: user._id },
        { $set: { password: hashedPassword } }
      );
      
      console.log('✅ Password updated!');
    }

    // Verify the update
    console.log('\n🧪 Verifying update...');
    const updatedUser = await User.findOne({ email: 'etsebruk.test@gmail.com' });
    
    if (updatedUser) {
      const isValid = await bcrypt.compare(password, updatedUser.password);
      console.log('   Email:', updatedUser.email);
      console.log('   Password test:', isValid ? '✅ CORRECT' : '❌ WRONG');
      console.log('   Email Verified:', updatedUser.isEmailVerified);
      console.log('   Active:', updatedUser.isActive);
      
      if (isValid) {
        console.log('\n✅ SUCCESS! You can now login with:');
        console.log('   Email: etsebruk.test@gmail.com');
        console.log('   Password: 123abc');
      }
    } else {
      console.log('❌ Could not verify update!');
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

forcePasswordUpdate();
