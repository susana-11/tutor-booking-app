require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../models/User');
const Booking = require('../models/Booking');

async function testRescheduleData() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find bookings with reschedule requests
    const bookings = await Booking.find({
      'rescheduleRequests.0': { $exists: true }
    })
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email')
      .populate('rescheduleRequests.requestedBy', 'firstName lastName')
      .limit(5);

    console.log(`\n📋 Found ${bookings.length} bookings with reschedule requests:\n`);

    for (const booking of bookings) {
      console.log(`Booking ID: ${booking._id}`);
      console.log(`Student: ${booking.studentId.firstName} ${booking.studentId.lastName}`);
      console.log(`Tutor: ${booking.tutorId.firstName} ${booking.tutorId.lastName}`);
      console.log(`Status: ${booking.status}`);
      console.log(`Payment Status: ${booking.paymentStatus}`);
      console.log(`\nReschedule Requests (${booking.rescheduleRequests.length}):`);
      
      booking.rescheduleRequests.forEach((req, index) => {
        console.log(`  ${index + 1}. Status: ${req.status}`);
        console.log(`     Requested By: ${req.requestedBy}`);
        console.log(`     New Date: ${req.newDate}`);
        console.log(`     New Time: ${req.newStartTime} - ${req.newEndTime}`);
        console.log(`     Reason: ${req.reason || 'N/A'}`);
      });
      
      // Check if there are pending requests
      const hasPending = booking.rescheduleRequests.some(req => req.status === 'pending');
      console.log(`\n✅ Has Pending Requests: ${hasPending}`);
      console.log('─'.repeat(60));
    }

    // Test the formatted response
    console.log('\n\n📤 Testing Formatted Response:\n');
    
    const testBooking = bookings[0];
    if (testBooking) {
      const formatted = {
        _id: testBooking._id,
        id: testBooking._id,
        studentId: testBooking.studentId._id,
        tutorId: testBooking.tutorId._id,
        status: testBooking.status,
        paymentStatus: testBooking.paymentStatus,
        rescheduleRequests: testBooking.rescheduleRequests || [],
      };
      
      console.log('Formatted Booking:');
      console.log(JSON.stringify(formatted, null, 2));
      
      // Test the mobile app logic
      const hasPendingRescheduleRequests = (formatted.rescheduleRequests)
        .some(req => req.status === 'pending');
      
      console.log(`\n🔍 Mobile App Check:`);
      console.log(`   rescheduleRequests exists: ${!!formatted.rescheduleRequests}`);
      console.log(`   rescheduleRequests is array: ${Array.isArray(formatted.rescheduleRequests)}`);
      console.log(`   rescheduleRequests length: ${formatted.rescheduleRequests.length}`);
      console.log(`   Has pending: ${hasPendingRescheduleRequests}`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  }
}

testRescheduleData();
