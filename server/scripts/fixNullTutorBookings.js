require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');

async function fixNullTutorBookings() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all bookings with null tutorId
    const bookings = await Booking.find({ tutorId: null });
    
    console.log(`\n🔍 Found ${bookings.length} bookings with null tutorId`);

    if (bookings.length === 0) {
      console.log('✅ No bookings to fix');
      process.exit(0);
    }

    // Since we can't determine the correct tutor from a null value,
    // we'll just delete these invalid bookings
    console.log('\n⚠️  These bookings cannot be fixed automatically.');
    console.log('They will need to be recreated by the user.');
    console.log('\nBookings to delete:');
    
    bookings.forEach(b => {
      console.log(`  - ${b._id} | Student: ${b.studentId} | Date: ${b.sessionDate} | Amount: ${b.totalAmount}`);
    });

    console.log('\n🗑️  Deleting invalid bookings...');
    const result = await Booking.deleteMany({ tutorId: null });
    console.log(`✅ Deleted ${result.deletedCount} bookings`);

    console.log('\n📝 Users will need to recreate their bookings with the correct tutor.');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

fixNullTutorBookings();
