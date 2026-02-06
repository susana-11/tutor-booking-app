require('dotenv').config({ path: __dirname + '/../.env' });
const mongoose = require('mongoose');
const User = require('../models/User');
const Booking = require('../models/Booking');

async function checkRescheduleRequests() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all bookings with reschedule requests
    const bookingsWithReschedule = await Booking.find({
      'rescheduleRequests.0': { $exists: true }
    })
    .populate('studentId', 'firstName lastName email')
    .populate('tutorId', 'firstName lastName email')
    .populate('rescheduleRequests.requestedBy', 'firstName lastName');

    console.log(`\n📊 Found ${bookingsWithReschedule.length} bookings with reschedule requests\n`);

    for (const booking of bookingsWithReschedule) {
      console.log('─'.repeat(60));
      console.log(`Booking ID: ${booking._id}`);
      console.log(`Student: ${booking.studentId?.firstName} ${booking.studentId?.lastName}`);
      console.log(`Tutor: ${booking.tutorId?.firstName} ${booking.tutorId?.lastName}`);
      console.log(`Status: ${booking.status}`);
      console.log(`Payment Status: ${booking.paymentStatus}`);
      console.log(`Session Date: ${booking.sessionDate}`);
      console.log(`\nReschedule Requests (${booking.rescheduleRequests.length}):`);
      
      booking.rescheduleRequests.forEach((req, index) => {
        console.log(`\n  Request #${index + 1}:`);
        console.log(`    Requested By: ${req.requestedBy?.firstName} ${req.requestedBy?.lastName}`);
        console.log(`    Status: ${req.status}`);
        console.log(`    New Date: ${req.newDate}`);
        console.log(`    New Time: ${req.newStartTime} - ${req.newEndTime}`);
        console.log(`    Reason: ${req.reason}`);
        console.log(`    Requested At: ${req.requestedAt}`);
      });
      console.log('');
    }

    // Check for bookings with pending reschedule requests specifically
    const pendingReschedules = await Booking.find({
      'rescheduleRequests': {
        $elemMatch: { status: 'pending' }
      }
    })
    .populate('studentId', 'firstName lastName email')
    .populate('tutorId', 'firstName lastName email');

    console.log('\n' + '='.repeat(60));
    console.log(`📋 Bookings with PENDING reschedule requests: ${pendingReschedules.length}`);
    console.log('='.repeat(60));

    for (const booking of pendingReschedules) {
      const pendingReqs = booking.rescheduleRequests.filter(r => r.status === 'pending');
      console.log(`\nBooking ${booking._id}:`);
      console.log(`  Student: ${booking.studentId?.firstName} ${booking.studentId?.lastName} (${booking.studentId?._id})`);
      console.log(`  Tutor: ${booking.tutorId?.firstName} ${booking.tutorId?.lastName} (${booking.tutorId?._id})`);
      console.log(`  Booking Status: ${booking.status}`);
      console.log(`  Payment Status: ${booking.paymentStatus}`);
      console.log(`  Pending Requests: ${pendingReqs.length}`);
    }

    // Check all bookings for a specific student (if you know the student ID)
    console.log('\n' + '='.repeat(60));
    console.log('📝 All bookings (showing rescheduleRequests field):');
    console.log('='.repeat(60));

    const allBookings = await Booking.find({})
      .select('_id studentId tutorId status paymentStatus rescheduleRequests')
      .populate('studentId', 'firstName lastName')
      .populate('tutorId', 'firstName lastName')
      .limit(10);

    for (const booking of allBookings) {
      console.log(`\nBooking ${booking._id}:`);
      console.log(`  Student: ${booking.studentId?.firstName} ${booking.studentId?.lastName}`);
      console.log(`  Tutor: ${booking.tutorId?.firstName} ${booking.tutorId?.lastName}`);
      console.log(`  Status: ${booking.status}`);
      console.log(`  Payment: ${booking.paymentStatus}`);
      console.log(`  Reschedule Requests: ${JSON.stringify(booking.rescheduleRequests, null, 2)}`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  }
}

checkRescheduleRequests();
