require('dotenv').config();
const mongoose = require('mongoose');
const notificationService = require('../services/notificationService');
const User = require('../models/User');

async function createTestNotifications() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find a student and tutor
    const student = await User.findOne({ role: 'student' });
    const tutor = await User.findOne({ role: 'tutor' });

    if (!student) {
      console.log('❌ No student found. Please create a student account first.');
      process.exit(1);
    }

    if (!tutor) {
      console.log('❌ No tutor found. Please create a tutor account first.');
      process.exit(1);
    }

    console.log(`\n📧 Creating test notifications...`);
    console.log(`Student: ${student.email}`);
    console.log(`Tutor: ${tutor.email}\n`);

    // Create notifications for student
    await notificationService.createNotification({
      userId: student._id,
      type: 'booking_accepted',
      title: 'Booking Confirmed',
      body: 'Your booking with John Doe has been confirmed for tomorrow at 2:00 PM',
      data: { bookingId: 'test123' },
      priority: 'high'
    });

    await notificationService.createNotification({
      userId: student._id,
      type: 'new_message',
      title: 'New Message',
      body: 'You have a new message from your tutor',
      data: { conversationId: 'conv123' },
      priority: 'normal'
    });

    await notificationService.createNotification({
      userId: student._id,
      type: 'booking_reminder',
      title: 'Session Reminder',
      body: 'Your session starts in 1 hour',
      data: { bookingId: 'test123' },
      priority: 'high'
    });

    // Create notifications for tutor
    await notificationService.createNotification({
      userId: tutor._id,
      type: 'booking_request',
      title: 'New Booking Request',
      body: 'Sarah Johnson wants to book a session with you for Mathematics',
      data: { bookingId: 'test456' },
      priority: 'high'
    });

    await notificationService.createNotification({
      userId: tutor._id,
      type: 'payment_received',
      title: 'Payment Received',
      body: 'You received ETB 500 for your session',
      data: { bookingId: 'test789' },
      priority: 'normal'
    });

    await notificationService.createNotification({
      userId: tutor._id,
      type: 'new_message',
      title: 'New Message',
      body: 'You have a new message from a student',
      data: { conversationId: 'conv456' },
      priority: 'normal'
    });

    await notificationService.createNotification({
      userId: tutor._id,
      type: 'booking_reminder',
      title: 'Session Reminder',
      body: 'Your session starts in 30 minutes',
      data: { bookingId: 'test456' },
      priority: 'urgent'
    });

    console.log('✅ Test notifications created successfully!');
    console.log('\n📱 You can now check the notifications in the mobile app');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createTestNotifications();
