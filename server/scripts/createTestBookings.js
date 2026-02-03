require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const StudentProfile = require('../models/StudentProfile');

async function createTestBookings() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find a tutor and student
    const tutor = await User.findOne({ role: 'tutor' });
    const student = await User.findOne({ role: 'student' });

    if (!tutor || !student) {
      console.log('❌ Need at least one tutor and one student');
      console.log('Please register users first');
      process.exit(1);
    }

    const tutorProfile = await TutorProfile.findOne({ userId: tutor._id });
    const studentProfile = await StudentProfile.findOne({ userId: student._id });

    console.log('👨‍🏫 Tutor:', tutor.firstName, tutor.lastName);
    console.log('👨‍🎓 Student:', student.firstName, student.lastName);
    console.log('');

    // Create test bookings with different statuses and times
    const now = new Date();
    const bookings = [];

    // 1. Pending booking (waiting for tutor response)
    bookings.push({
      student: student._id,
      tutor: tutor._id,
      tutorProfile: tutorProfile._id,
      subject: 'Mathematics',
      sessionDate: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
      startTime: '14:00',
      endTime: '15:00',
      duration: 60,
      pricePerHour: tutorProfile?.hourlyRate || 500,
      totalAmount: tutorProfile?.hourlyRate || 500,
      mode: 'Online',
      status: 'pending',
      studentMessage: 'I need help with calculus',
    });

    // 2. Confirmed booking (paid, session in 10 minutes - to test Start Session button)
    const sessionIn10Min = new Date(now.getTime() + 10 * 60 * 1000);
    bookings.push({
      student: student._id,
      tutor: tutor._id,
      tutorProfile: tutorProfile._id,
      subject: 'Physics',
      sessionDate: sessionIn10Min,
      startTime: `${sessionIn10Min.getHours()}:${String(sessionIn10Min.getMinutes()).padStart(2, '0')}`,
      endTime: `${sessionIn10Min.getHours() + 1}:${String(sessionIn10Min.getMinutes()).padStart(2, '0')}`,
      duration: 60,
      pricePerHour: tutorProfile?.hourlyRate || 500,
      totalAmount: tutorProfile?.hourlyRate || 500,
      mode: 'Online',
      status: 'confirmed',
      payment: {
        status: 'completed',
        method: 'chapa',
        transactionId: 'TEST_' + Date.now(),
        amount: tutorProfile?.hourlyRate || 500,
        paidAt: new Date(),
      },
      escrow: {
        status: 'held',
        amount: tutorProfile?.hourlyRate || 500,
        heldAt: new Date(),
      },
    });

    // 3. Confirmed booking (paid, session tomorrow)
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    bookings.push({
      student: student._id,
      tutor: tutor._id,
      tutorProfile: tutorProfile._id,
      subject: 'Chemistry',
      sessionDate: tomorrow,
      startTime: '10:00',
      endTime: '11:00',
      duration: 60,
      pricePerHour: tutorProfile?.hourlyRate || 500,
      totalAmount: tutorProfile?.hourlyRate || 500,
      mode: 'Online',
      status: 'confirmed',
      payment: {
        status: 'completed',
        method: 'chapa',
        transactionId: 'TEST_' + Date.now() + '_2',
        amount: tutorProfile?.hourlyRate || 500,
        paidAt: new Date(),
      },
      escrow: {
        status: 'held',
        amount: tutorProfile?.hourlyRate || 500,
        heldAt: new Date(),
      },
    });

    // 4. Completed booking (with escrow released)
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    bookings.push({
      student: student._id,
      tutor: tutor._id,
      tutorProfile: tutorProfile._id,
      subject: 'English',
      sessionDate: yesterday,
      startTime: '15:00',
      endTime: '16:00',
      duration: 60,
      pricePerHour: tutorProfile?.hourlyRate || 500,
      totalAmount: tutorProfile?.hourlyRate || 500,
      mode: 'Online',
      status: 'completed',
      payment: {
        status: 'completed',
        method: 'chapa',
        transactionId: 'TEST_' + Date.now() + '_3',
        amount: tutorProfile?.hourlyRate || 500,
        paidAt: new Date(yesterday.getTime() - 60 * 60 * 1000),
      },
      session: {
        isActive: false,
        startedAt: new Date(yesterday.getTime()),
        endedAt: new Date(yesterday.getTime() + 60 * 60 * 1000),
        duration: 60,
        notes: 'Great session! Student understood the concepts well.',
      },
      escrow: {
        status: 'released',
        amount: tutorProfile?.hourlyRate || 500,
        heldAt: new Date(yesterday.getTime() - 60 * 60 * 1000),
        releasedAt: new Date(yesterday.getTime() + 25 * 60 * 60 * 1000),
      },
    });

    // 5. Cancelled booking
    bookings.push({
      student: student._id,
      tutor: tutor._id,
      tutorProfile: tutorProfile._id,
      subject: 'History',
      sessionDate: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      startTime: '16:00',
      endTime: '17:00',
      duration: 60,
      pricePerHour: tutorProfile?.hourlyRate || 500,
      totalAmount: tutorProfile?.hourlyRate || 500,
      mode: 'Online',
      status: 'cancelled',
      cancellationReason: 'Student had an emergency',
      cancelledBy: 'student',
      cancelledAt: new Date(),
    });

    // Insert all bookings
    console.log('📝 Creating test bookings...\n');
    const created = await Booking.insertMany(bookings);

    console.log('✅ Created bookings:\n');
    created.forEach((booking, index) => {
      console.log(`${index + 1}. ${booking.subject}`);
      console.log(`   Status: ${booking.status}`);
      console.log(`   Date: ${booking.sessionDate.toLocaleDateString()}`);
      console.log(`   Time: ${booking.startTime} - ${booking.endTime}`);
      if (booking.status === 'confirmed') {
        const timeUntil = Math.round((new Date(booking.sessionDate).getTime() - now.getTime()) / (1000 * 60));
        console.log(`   ⏰ Starts in: ${timeUntil} minutes`);
      }
      console.log('');
    });

    console.log('🎉 Test bookings created successfully!');
    console.log('');
    console.log('📱 Now you can:');
    console.log('1. Login as tutor to see pending booking requests');
    console.log('2. Accept/decline bookings');
    console.log('3. See confirmed sessions');
    console.log('4. Wait 5 minutes and see "Start Session" button appear');
    console.log('5. View completed sessions');
    console.log('6. View cancelled sessions');
    console.log('');
    console.log('💡 Tip: The Physics session will show "Start Session" button in 5 minutes!');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

createTestBookings();
