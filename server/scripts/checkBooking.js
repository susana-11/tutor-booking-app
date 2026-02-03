require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');

async function checkBooking() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const bookingId = process.argv[2];
    if (!bookingId) {
      console.log('Usage: node checkBooking.js <bookingId>');
      process.exit(1);
    }

    console.log(`\n🔍 Checking booking: ${bookingId}`);
    
    // Check if valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      console.log('❌ Invalid ObjectId format');
      process.exit(1);
    }

    const booking = await Booking.findById(bookingId)
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId');

    if (!booking) {
      console.log('❌ Booking not found');
      
      // List recent bookings
      console.log('\n📋 Recent bookings:');
      const recentBookings = await Booking.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .select('_id studentId tutorId sessionDate status createdAt');
      
      recentBookings.forEach(b => {
        console.log(`  - ${b._id} | ${b.status} | ${b.sessionDate} | Created: ${b.createdAt}`);
      });
    } else {
      console.log('✅ Booking found!');
      console.log('\n📦 Booking details:');
      console.log(`  ID: ${booking._id}`);
      console.log(`  Student: ${booking.studentId?.firstName} ${booking.studentId?.lastName} (${booking.studentId?._id})`);
      console.log(`  Tutor (populated): ${booking.tutorId?._id || booking.tutorId}`);
      
      // Get raw booking to see actual tutorId value
      const rawBooking = await Booking.findById(bookingId).lean();
      console.log(`  Tutor (raw): ${rawBooking.tutorId}`);
      
      console.log(`  Status: ${booking.status}`);
      console.log(`  Payment Status: ${booking.payment?.status || booking.paymentStatus}`);
      console.log(`  Amount: ${booking.totalAmount}`);
      console.log(`  Session Date: ${booking.sessionDate}`);
      console.log(`  Created: ${booking.createdAt}`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkBooking();
