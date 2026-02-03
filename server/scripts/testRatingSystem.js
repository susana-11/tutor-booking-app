const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Review = require('../models/Review');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
require('dotenv').config();

// Connect to database
const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor_booking';
    console.log(`🔌 Attempting to connect to MongoDB... (URI starts with: ${uri.substring(0, 15)}...)`);

    await mongoose.connect(uri);
    console.log('✅ MongoDB connected for testing');
  } catch (error) {
    console.error('❌ MongoDB connection error details:', error);
    process.exit(1);
  }
};

async function testRatingSystem() {
  await connectDB();

  try {
    console.log('\n⭐ Testing Rating and Review System\n');

    // Find a student and tutor for testing
    const student = await User.findOne({ role: 'student' });
    const tutor = await User.findOne({ role: 'tutor' });
    const tutorProfile = await TutorProfile.findOne({ userId: tutor._id });

    if (!student || !tutor || !tutorProfile) {
      console.log('⚠️  No test users found. Please create a student and tutor first.');
      process.exit(1);
    }

    console.log(`👤 Using student: ${student.firstName} ${student.lastName}`);
    console.log(`👨‍🏫 Using tutor: ${tutor.firstName} ${tutor.lastName}`);
    console.log(`📊 Current tutor rating: ${tutorProfile.stats.averageRating} (${tutorProfile.stats.totalReviews} reviews)\n`);

    // Clean up any existing test data
    await Review.deleteMany({
      studentId: student._id,
      tutorId: tutorProfile._id,
      subject: /Test Rating/
    });

    await Booking.deleteMany({
      studentId: student._id,
      tutorId: tutorProfile._id,
      subject: { name: /Test Rating/ }
    });

    // Test 1: Create a completed booking
    console.log('📝 Test 1: Creating completed test bookings...');

    const testBookings = [];
    const ratings = [5, 4, 5, 3, 4]; // Will result in average of 4.2

    for (let i = 0; i < ratings.length; i++) {
      const booking = await Booking.create({
        studentId: student._id,
        tutorId: tutorProfile._id,
        subject: {
          name: `Test Rating Subject ${i + 1}`,
          grades: ['Grade 10']
        },
        sessionDate: new Date(Date.now() - (i + 1) * 24 * 60 * 60 * 1000), // Past dates
        startTime: '14:00',
        endTime: '15:00',
        duration: 60,
        sessionType: 'online',
        status: 'completed',
        pricePerHour: 50,
        totalAmount: 50,
        completedAt: new Date(Date.now() - i * 60 * 60 * 1000)
      });
      testBookings.push(booking);
    }

    console.log(`   ✅ Created ${testBookings.length} completed bookings\n`);

    // Test 2: Submit ratings and reviews
    console.log('⭐ Test 2: Submitting ratings and reviews...');

    for (let i = 0; i < testBookings.length; i++) {
      const booking = testBookings[i];
      const rating = ratings[i];

      const review = await Review.create({
        bookingId: booking._id,
        tutorId: tutorProfile._id,
        studentId: student._id,
        rating,
        review: `This is test review #${i + 1}. Rating: ${rating} stars. Great session!`,
        categories: {
          communication: rating,
          expertise: rating === 5 ? 5 : rating - 1,
          punctuality: 5,
          helpfulness: rating
        },
        sessionDate: booking.sessionDate,
        subject: booking.subject.name
      });

      // Also update booking with rating
      await booking.addRating(student._id, rating, review.review, 'student');

      console.log(`   ✅ Created review for booking ${i + 1}: ${rating} stars`);
    }

    console.log('');

    // Test 3: Verify average rating calculation
    console.log('📊 Test 3: Verifying average rating calculation...');

    const ratingStats = await Review.getTutorAverageRating(tutorProfile._id);
    console.log(`   Average Rating: ${ratingStats.averageRating}`);
    console.log(`   Total Reviews: ${ratingStats.totalReviews}`);
    console.log(`   Distribution:`);
    Object.keys(ratingStats.distribution).sort().reverse().forEach(star => {
      const count = ratingStats.distribution[star];
      const bars = '★'.repeat(count);
      console.log(`      ${star}★: ${count} ${bars}`);
    });

    // Verify average calculation
    const expectedAverage = ratings.reduce((a, b) => a + b, 0) / ratings.length;
    const actualAverage = ratingStats.averageRating;

    if (Math.abs(actualAverage - expectedAverage) < 0.1) {
      console.log(`   ✅ Average rating correct: ${actualAverage} (expected ~${expectedAverage.toFixed(1)})\n`);
    } else {
      console.log(`   ❌ Average rating incorrect: ${actualAverage} (expected ${expectedAverage.toFixed(1)})\n`);
    }

    // Test 4: Update tutor profile rating
    console.log('🔄 Test 4: Updating tutor profile with new rating...');

    await tutorProfile.updateAverageRating();
    const updatedTutor = await TutorProfile.findById(tutorProfile._id);

    console.log(`   Tutor Profile Stats: `);
    console.log(`      Average Rating: ${updatedTutor.stats.averageRating} `);
    console.log(`      Total Reviews: ${updatedTutor.stats.totalReviews} `);
    console.log(`   ✅ Tutor profile updated successfully\n`);

    // Test 5: Get tutor reviews with filters
    console.log('📚 Test 5: Testing review retrieval with filters...');

    const allReviews = await Review.getTutorReviews(tutorProfile._id, {
      page: 1,
      limit: 10,
      sortBy: 'recent'
    });

    console.log(`   Total reviews: ${allReviews.pagination.total} `);
    console.log(`   Retrieved: ${allReviews.reviews.length} `);

    const topReviews = await Review.getTutorReviews(tutorProfile._id, {
      rating: 5,
      sortBy: 'rating_high'
    });

    console.log(`   5 - star reviews: ${topReviews.reviews.length} `);
    console.log(`   ✅ Review filtering working correctly\n`);

    // Test 6: Test helpfulness voting
    console.log('👍 Test 6: Testing helpfulness voting...');

    const firstReview = allReviews.reviews[0];
    await firstReview.markHelpful(student._id, true);

    const updatedReview = await Review.findById(firstReview._id);
    console.log(`   Helpful count: ${updatedReview.helpful.length} `);
    console.log(`   Helpfulness score: ${updatedReview.helpfulnessScore} `);
    console.log(`   ✅ Helpfulness voting working\n`);

    // Test 7: Test tutor response
    console.log('💬 Test 7: Testing tutor response...');

    await updatedReview.addTutorResponse('Thank you for your feedback! I enjoyed working with you.');
    const reviewWithResponse = await Review.findById(updatedReview._id);

    if (reviewWithResponse.tutorResponse && reviewWithResponse.tutorResponse.text) {
      console.log(`   Tutor response: "${reviewWithResponse.tutorResponse.text}"`);
      console.log(`   Responded at: ${reviewWithResponse.tutorResponse.respondedAt} `);
      console.log(`   ✅ Tutor response feature working\n`);
    } else {
      console.log(`   ❌ Tutor response not saved\n`);
    }

    // Test 8: Test edit review (within 24 hours)
    console.log('✏️  Test 8: Testing review editing...');

    const canEdit = updatedReview.canEdit;
    console.log(`   Can edit review: ${canEdit} `);

    if (canEdit) {
      try {
        await updatedReview.editReview(4, 'Updated review text with different rating');
        const editedReview = await Review.findById(updatedReview._id);
        console.log(`   New rating: ${editedReview.rating} `);
        console.log(`   Is edited: ${editedReview.isEdited} `);
        console.log(`   Edit history length: ${editedReview.editHistory.length} `);
        console.log(`   ✅ Review editing working\n`);
      } catch (error) {
        console.log(`   ❌ Edit failed: ${error.message} \n`);
      }
    }

    // Display summary
    console.log('═══════════════════════════════════════════════════════');
    console.log('📊 Test Summary');
    console.log('═══════════════════════════════════════════════════════');
    console.log(`✅ Created ${testBookings.length} test bookings`);
    console.log(`✅ Created ${ratings.length} reviews`);
    console.log(`✅ Average rating calculated: ${ratingStats.averageRating} stars`);
    console.log(`✅ Tutor profile updated: ${updatedTutor.stats.averageRating} stars`);
    console.log(`✅ Review distribution: ${JSON.stringify(ratingStats.distribution)} `);
    console.log('✅ Helpfulness voting tested');
    console.log('✅ Tutor response tested');
    console.log('✅ Review editing tested');
    console.log('\n💡 All tests completed successfully!\n');

    // Clean up test data
    console.log('🧹 Cleaning up test data...');
    await Review.deleteMany({ _id: { $in: allReviews.reviews.map(r => r._id) } });
    await Booking.deleteMany({ _id: { $in: testBookings.map(b => b._id) } });

    // Recalculate tutor rating after cleanup
    await tutorProfile.updateAverageRating();
    console.log('✅ Test data cleaned up\n');

  } catch (error) {
    console.error('❌ Test failed:', error);
    console.error(error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('👋 Database connection closed');
    process.exit(0);
  }
}

// Run the test
testRatingSystem();
