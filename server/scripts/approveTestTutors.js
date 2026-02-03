const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');

async function approveTestTutors() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get all pending tutors
    const pendingTutors = await TutorProfile.find({ status: 'pending' })
      .populate('userId', 'firstName lastName email');

    console.log(`Found ${pendingTutors.length} pending tutors:\n`);

    if (pendingTutors.length === 0) {
      console.log('✅ No pending tutors to approve!');
      return;
    }

    // Approve each tutor
    for (const tutor of pendingTutors) {
      console.log(`Approving: ${tutor.userId.firstName} ${tutor.userId.lastName} (${tutor.userId.email})`);
      
      tutor.status = 'approved';
      tutor.isActive = true;
      tutor.isAvailable = true;
      await tutor.save();
      
      console.log(`✅ Approved!`);
      console.log(`   Profile ID: ${tutor._id}`);
      console.log(`   User ID: ${tutor.userId._id}`);
      console.log(`   Status: ${tutor.status}`);
      console.log(`   Is Active: ${tutor.isActive}`);
      console.log(`   Is Available: ${tutor.isAvailable}\n`);
    }

    console.log(`\n✅ Successfully approved ${pendingTutors.length} tutors!`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

approveTestTutors();
