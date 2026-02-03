const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const notificationService = require('../services/notificationService');
require('dotenv').config();

// Connect to database
const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor_booking');
        console.log('✅ MongoDB connected for testing');
    } catch (error) {
        console.error('❌ MongoDB connection error:', error);
        process.exit(1);
    }
};

async function testBookingReminders() {
    await connectDB();

    try {
        console.log('\n📅 Testing Booking Reminder System\n');

        // Find a student and tutor for testing
        const student = await User.findOne({ role: 'student' });
        const tutor = await User.findOne({ role: 'tutor' });
        const tutorProfile = await TutorProfile.findOne({ userId: tutor._id });

        if (!student || !tutor || !tutorProfile) {
            console.log('⚠️  No test users found. Please create a student and tutor first.');
            console.log('Run: node scripts/createAdmin.js');
            process.exit(1);
        }

        console.log(`👤 Using student: ${student.firstName} ${student.lastName}`);
        console.log(`👨‍🏫 Using tutor: ${tutor.firstName} ${tutor.lastName}\n`);

        // Clean up any existing test bookings
        await Booking.deleteMany({
            studentId: student._id,
            tutorId: tutorProfile._id,
            subject: { name: 'Test Reminder Subject' }
        });

        // Create a test booking scheduled for 1 hour from now
        const sessionDate = new Date();
        sessionDate.setHours(sessionDate.getHours() + 1);
        sessionDate.setMinutes(0);
        sessionDate.setSeconds(0);

        const testBooking = await Booking.create({
            studentId: student._id,
            tutorId: tutorProfile._id,
            subject: {
                name: 'Test Reminder Subject',
                grades: ['Grade 10']
            },
            sessionDate: sessionDate,
            startTime: sessionDate.toTimeString().slice(0, 5),
            endTime: new Date(sessionDate.getTime() + 60 * 60 * 1000).toTimeString().slice(0, 5),
            duration: 60,
            sessionType: 'online',
            status: 'confirmed',
            pricePerHour: 50,
            totalAmount: 50
        });

        console.log(`✅ Created test booking: ${testBooking._id}`);
        console.log(`   Session scheduled for: ${sessionDate.toLocaleString()}`);
        console.log(`   Time: ${testBooking.startTime} - ${testBooking.endTime}\n`);

        // Test 1: 1-hour reminder
        console.log('🔔 Test 1: Sending 1-hour reminder...');
        try {
            await notificationService.sendBookingReminder(testBooking, '1_hour');

            // Verify reminder was tracked
            const updatedBooking = await Booking.findById(testBooking._id);
            testBooking.remindersSent = updatedBooking.remindersSent;

            const reminder1h = updatedBooking.remindersSent.find(r => r.type === '1_hour');
            if (reminder1h) {
                console.log('   ✅ 1-hour reminder sent successfully');
                console.log(`   ✅ Reminder tracked in booking at ${reminder1h.sentAt.toLocaleTimeString()}`);
            } else {
                console.log('   ⚠️  Reminder sent but not tracked in booking');
            }
        } catch (error) {
            console.log(`   ❌ Failed to send 1-hour reminder: ${error.message}`);
        }

        // Test 2: 15-minute reminder
        console.log('\n🔔 Test 2: Sending 15-minute reminder...');
        try {
            await notificationService.sendBookingReminder(testBooking, '15_minutes');

            const updatedBooking = await Booking.findById(testBooking._id);
            const reminder15m = updatedBooking.remindersSent.find(r => r.type === '15_minutes');
            if (reminder15m) {
                console.log('   ✅ 15-minute reminder sent successfully');
                console.log(`   ✅ Reminder tracked in booking at ${reminder15m.sentAt.toLocaleTimeString()}`);
            }
        } catch (error) {
            console.log(`   ❌ Failed to send 15-minute reminder: ${error.message}`);
        }

        // Test 3: Create a completed booking for rating reminder
        console.log('\n🔔 Test 3: Testing rating request reminder...');

        const completedBooking = await Booking.create({
            studentId: student._id,
            tutorId: tutorProfile._id,
            subject: {
                name: 'Completed Test Session',
                grades: ['Grade 10']
            },
            sessionDate: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
            startTime: '14:00',
            endTime: '15:00',
            duration: 60,
            sessionType: 'online',
            status: 'completed',
            pricePerHour: 50,
            totalAmount: 50,
            completedAt: new Date(Date.now() - 1 * 60 * 60 * 1000) // Completed 1 hour ago
        });

        try {
            await notificationService.sendRatingRequest(completedBooking);

            const updatedCompletedBooking = await Booking.findById(completedBooking._id);
            const ratingReminder = updatedCompletedBooking.remindersSent.find(r => r.type === 'rating_request');
            if (ratingReminder) {
                console.log('   ✅ Rating request sent successfully');
                console.log(`   ✅ Rating request tracked at ${ratingReminder.sentAt.toLocaleTimeString()}`);
            }
        } catch (error) {
            console.log(`   ❌ Failed to send rating request: ${error.message}`);
        }

        // Display summary
        console.log('\n📊 Test Summary:');
        console.log('═══════════════════════════════════════════════════════');

        const finalBooking = await Booking.findById(testBooking._id);
        console.log(`\nUpcoming Booking Reminders Sent: ${finalBooking.remindersSent.length}`);
        finalBooking.remindersSent.forEach(r => {
            console.log(`  - ${r.type}: ${r.sentAt.toLocaleString()}`);
        });

        const finalCompletedBooking = await Booking.findById(completedBooking._id);
        console.log(`\nCompleted Booking Reminders Sent: ${finalCompletedBooking.remindersSent.length}`);
        finalCompletedBooking.remindersSent.forEach(r => {
            console.log(`  - ${r.type}: ${r.sentAt.toLocaleString()}`);
        });

        console.log('\n✅ All tests completed!');
        console.log('\n💡 Tips:');
        console.log('   - Check the notifications collection in MongoDB to see created notifications');
        console.log('   - If Firebase is configured, check mobile devices for push notifications');
        console.log('   - The reminder scheduler runs every 5 minutes in production');
        console.log('   - Test bookings have been created for manual testing\n');

        // Clean up test data
        console.log('🧹 Cleaning up test bookings...');
        await Booking.deleteMany({ _id: { $in: [testBooking._id, completedBooking._id] } });
        console.log('✅ Test bookings cleaned up\n');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await mongoose.connection.close();
        console.log('👋 Database connection closed');
        process.exit(0);
    }
}

// Run the test
testBookingReminders();
