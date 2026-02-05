require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Notification = require('../models/Notification');

async function testNotifications() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find a recent booking
    const booking = await Booking.findOne({ status: { $in: ['confirmed', 'pending'] } })
      .populate('studentId', 'firstName lastName email')
      .populate('tutorId', 'firstName lastName email')
      .sort({ createdAt: -1 });

    if (!booking) {
      console.log('❌ No bookings found');
      process.exit(0);
    }

    console.log('📋 Found booking:');
    console.log('  ID:', booking._id.toString());
    console.log('  Student:', booking.studentId?.firstName, booking.studentId?.lastName);
    console.log('  Tutor:', booking.tutorId?.firstName, booking.tutorId?.lastName);
    console.log('  Status:', booking.status);
    console.log('  Date:', booking.sessionDate);
    console.log('');

    // Check notifications for both users
    console.log('📧 Checking notifications for student:', booking.studentId._id.toString());
    const studentNotifications = await Notification.find({ 
      userId: booking.studentId._id 
    }).sort({ createdAt: -1 }).limit(5);
    
    console.log(`  Found ${studentNotifications.length} recent notifications:`);
    studentNotifications.forEach(notif => {
      console.log(`    - ${notif.type}: ${notif.title} (${notif.createdAt.toISOString()})`);
    });
    console.log('');

    console.log('📧 Checking notifications for tutor:', booking.tutorId._id.toString());
    const tutorNotifications = await Notification.find({ 
      userId: booking.tutorId._id 
    }).sort({ createdAt: -1 }).limit(5);
    
    console.log(`  Found ${tutorNotifications.length} recent notifications:`);
    tutorNotifications.forEach(notif => {
      console.log(`    - ${notif.type}: ${notif.title} (${notif.createdAt.toISOString()})`);
    });
    console.log('');

    // Check for cancel/reschedule notifications specifically
    console.log('🔍 Checking for cancel/reschedule notifications:');
    const cancelRescheduleNotifs = await Notification.find({
      userId: { $in: [booking.studentId._id, booking.tutorId._id] },
      type: { $in: ['booking_cancelled', 'reschedule_request', 'reschedule_accepted', 'reschedule_rejected'] }
    }).sort({ createdAt: -1 }).limit(10);

    if (cancelRescheduleNotifs.length === 0) {
      console.log('  ❌ No cancel/reschedule notifications found');
    } else {
      console.log(`  ✅ Found ${cancelRescheduleNotifs.length} cancel/reschedule notifications:`);
      cancelRescheduleNotifs.forEach(notif => {
        const user = notif.userId.toString() === booking.studentId._id.toString() ? 'Student' : 'Tutor';
        console.log(`    - [${user}] ${notif.type}: ${notif.title}`);
        console.log(`      Body: ${notif.body}`);
        console.log(`      Created: ${notif.createdAt.toISOString()}`);
        console.log(`      Read: ${notif.read ? 'Yes' : 'No'}`);
        console.log('');
      });
    }

    console.log('✅ Test complete');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testNotifications();
