const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');

async function testTutorAPI() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Simulate the API query
    console.log('📡 Simulating GET /api/tutors API call...\n');

    const filter = {
      status: 'approved',
      isActive: true,
    };

    console.log('🔍 Query filter:', JSON.stringify(filter, null, 2));

    const tutors = await TutorProfile.find(filter)
      .populate('userId', 'firstName lastName email phone profilePicture')
      .sort({ rating: -1, totalReviews: -1, createdAt: -1 });

    console.log(`\n✅ Found ${tutors.length} tutors\n`);

    if (tutors.length === 0) {
      console.log('❌ No tutors found with the filter!');
      console.log('\nLet\'s check all tutors in database:');
      
      const allTutors = await TutorProfile.find({})
        .populate('userId', 'firstName lastName email phone');
      
      console.log(`\nTotal tutors in database: ${allTutors.length}\n`);
      
      allTutors.forEach((tutor, idx) => {
        console.log(`${idx + 1}. ${tutor.userId.firstName} ${tutor.userId.lastName}`);
        console.log(`   Status: ${tutor.status}`);
        console.log(`   Is Active: ${tutor.isActive}`);
        console.log(`   Is Available: ${tutor.isAvailable}`);
        console.log('');
      });
    } else {
      // Format response like the API does
      const formattedTutors = tutors.map(tutor => ({
        id: tutor._id,
        userId: tutor.userId._id,
        name: `${tutor.userId.firstName} ${tutor.userId.lastName}`,
        email: tutor.userId.email,
        profilePhoto: tutor.profilePhoto || tutor.userId.profilePicture,
        bio: tutor.bio,
        subjects: tutor.subjects,
        pricePerHour: tutor.pricing?.hourlyRate,
        hourlyRate: tutor.pricing?.hourlyRate,
        rating: tutor.stats?.averageRating || 0,
        totalReviews: tutor.stats?.totalReviews || 0,
        totalSessions: tutor.stats?.totalSessions || 0,
        teachingMode: tutor.teachingMode,
        location: tutor.location,
        isActive: tutor.isActive,
        status: tutor.status,
        createdAt: tutor.createdAt,
      }));

      console.log('📋 API Response (formatted):');
      console.log(JSON.stringify(formattedTutors, null, 2));
    }

    console.log('\n✅ Test complete!');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

testTutorAPI();
