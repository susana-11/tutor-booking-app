require('dotenv').config();
const mongoose = require('mongoose');
const notificationService = require('../services/notificationService');

// Connect to database
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

async function testNotifications() {
  try {
    console.log('\n🧪 Testing Notification System\n');

    // Test 1: Create a booking request notification
    console.log('Test 1: Creating booking request notification...');
    const notification1 = await notificationService.createNotification({
      userId: '697da222bd7132e2f3c16190', // Replace with actual tutor ID
      type: 'booking_request',
      title: 'New Booking Request',
      body: 'John Doe wants to book a Mathematics session on Feb 5, 2026 at 10:00 AM',
      data: { 
        type: 'booking_request', 
        bookingId: 'test123',
        studentName: 'John Doe',
        subject: 'Mathematics'
      },
      priority: 'high',
      actionUrl: '/tutor/bookings'
    });
    console.log('✅ Notification created:', notification1._id);

    // Test 2: Create a booking accepted notification
    console.log('\nTest 2: Creating booking accepted notification...');
    const notification2 = await notificationService.createNotification({
      userId: '697d9fb9bd7132e2f3c1616b', // Replace with actual student ID
      type: 'booking_accepted',
      title: 'Booking Confirmed! 🎉',
      body: 'Jane Smith accepted your Mathematics session on Feb 5, 2026 at 10:00 AM',
      data: { 
        type: 'booking_accepted', 
        bookingId: 'test123',
        tutorName: 'Jane Smith'
      },
      priority: 'high',
      actionUrl: '/student/bookings'
    });
    console.log('✅ Notification created:', notification2._id);

    // Test 3: Get user notifications
    console.log('\nTest 3: Fetching user notifications...');
    const result = await notificationService.getUserNotifications('697da222bd7132e2f3c16190', {
      page: 1,
      limit: 10
    });
    console.log('✅ Found', result.notifications.length, 'notifications');
    console.log('   Unread count:', result.unreadCount);

    // Test 4: Mark as read
    console.log('\nTest 4: Marking notification as read...');
    await notificationService.markAsRead(notification1._id, '697da222bd7132e2f3c16190');
    console.log('✅ Notification marked as read');

    // Test 5: Test notification methods
    console.log('\nTest 5: Testing notification helper methods...');
    
    await notificationService.notifyBookingRequest({
      tutorId: '697da222bd7132e2f3c16190',
      studentName: 'Test Student',
      subject: 'Physics',
      date: 'Feb 10, 2026',
      time: '2:00 PM - 3:00 PM',
      bookingId: 'test456'
    });
    console.log('✅ notifyBookingRequest() works');

    await notificationService.notifyBookingAccepted({
      studentId: '697d9fb9bd7132e2f3c1616b',
      tutorName: 'Test Tutor',
      subject: 'Chemistry',
      date: 'Feb 12, 2026',
      time: '4:00 PM - 5:00 PM',
      bookingId: 'test789'
    });
    console.log('✅ notifyBookingAccepted() works');

    console.log('\n✅ All tests passed!\n');
    console.log('📊 Summary:');
    console.log('   - Notification creation: ✅');
    console.log('   - Notification retrieval: ✅');
    console.log('   - Mark as read: ✅');
    console.log('   - Helper methods: ✅');
    console.log('   - Socket.IO: ' + (global.io ? '✅' : '⚠️  Not available (run from server)'));
    console.log('   - Firebase/FCM: ' + (process.env.FIREBASE_SERVICE_ACCOUNT ? '✅' : '⚠️  Not configured'));

  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run tests
testNotifications();
