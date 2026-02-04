require('dotenv').config();
const mongoose = require('mongoose');

async function checkEmails() {
  try {
    console.log('🔧 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const User = require('../models/User');

    console.log('\n🔍 Checking for all student users...\n');

    // Find all students
    const students = await User.find({ role: 'student' });

    console.log(`Found ${students.length} student(s):\n`);

    students.forEach((student, index) => {
      console.log(`${index + 1}. ${student.firstName} ${student.lastName}`);
      console.log(`   Email: ${student.email}`);
      console.log(`   ID: ${student._id}`);
      console.log(`   Email Verified: ${student.isEmailVerified}`);
      console.log(`   Active: ${student.isActive}`);
      console.log('');
    });

    // Check for old email
    console.log('🔍 Checking for old email (etsebruk@example.com)...');
    const oldEmail = await User.findOne({ email: 'etsebruk@example.com' });
    if (oldEmail) {
      console.log('⚠️  OLD EMAIL STILL EXISTS!');
      console.log('   ID:', oldEmail._id);
      console.log('   Name:', oldEmail.firstName, oldEmail.lastName);
    } else {
      console.log('✅ Old email not found (good!)');
    }

    // Check for new email
    console.log('\n🔍 Checking for new email (etsebruk.test@gmail.com)...');
    const newEmail = await User.findOne({ email: 'etsebruk.test@gmail.com' });
    if (newEmail) {
      console.log('✅ NEW EMAIL EXISTS!');
      console.log('   ID:', newEmail._id);
      console.log('   Name:', newEmail.firstName, newEmail.lastName);
      console.log('   Email Verified:', newEmail.isEmailVerified);
      console.log('   Active:', newEmail.isActive);
    } else {
      console.log('❌ New email not found!');
    }

    await mongoose.connection.close();
    console.log('\n✅ Done!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkEmails();
