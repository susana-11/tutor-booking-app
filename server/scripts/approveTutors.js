const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');

async function approveTutors() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Update all pending tutors to approved
    const result = await TutorProfile.updateMany(
      { status: 'pending' },
      { $set: { status: 'approved', isActive: true } }
    );

    console.log(`✅ Updated ${result.modifiedCount} tutor(s) to approved status`);

    // Show all tutors
    const tutors = await TutorProfile.find({}).populate('userId', 'firstName lastName email');
    console.log('\n📊 All tutors:');
    tutors.forEach((tutor, index) => {
      console.log(`${index + 1}. ${tutor.userId?.firstName} ${tutor.userId?.lastName} - Status: ${tutor.status}, Active: ${tutor.isActive}`);
    });

    await mongoose.disconnect();
    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

approveTutors();
