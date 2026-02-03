require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function resetPasswords() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Reset tutor password
    console.log('\n🔐 Resetting tutor password...');
    const tutorEmail = 'bubuam13@gmail.com';
    const tutorUser = await User.findOne({ email: tutorEmail });
    
    if (tutorUser) {
      tutorUser.password = '123abc'; // Will be hashed by pre-save hook
      await tutorUser.save();
      console.log('✅ Tutor password reset to: 123abc');
    } else {
      console.log('❌ Tutor user not found');
    }

    // Reset student password
    console.log('\n🔐 Resetting student password...');
    const studentEmail = 'etsebruk@example.com';
    const studentUser = await User.findOne({ email: studentEmail });
    
    if (studentUser) {
      studentUser.password = '123abc'; // Will be hashed by pre-save hook
      await studentUser.save();
      console.log('✅ Student password reset to: 123abc');
    } else {
      console.log('❌ Student user not found');
    }

    console.log('\n🎉 Password reset complete!');
    console.log('\n📱 Test Accounts:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('👨‍🏫 TUTOR ACCOUNT:');
    console.log(`   Email: ${tutorEmail}`);
    console.log('   Password: 123abc');
    console.log('');
    console.log('👨‍🎓 STUDENT ACCOUNT:');
    console.log(`   Email: ${studentEmail}`);
    console.log('   Password: 123abc');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

resetPasswords();
