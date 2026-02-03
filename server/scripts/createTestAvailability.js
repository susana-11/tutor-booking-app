/**
 * Create Test Availability Slots
 * 
 * This script creates sample availability slots for testing the booking system
 */

const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const AvailabilitySlot = require('../models/AvailabilitySlot');

async function createTestAvailability() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to database\n');

    // Find a tutor
    const tutor = await User.findOne({ role: 'tutor' });
    if (!tutor) {
      console.log('❌ No tutor found in database');
      console.log('💡 Please register a tutor first');
      process.exit(1);
    }

    const tutorProfile = await TutorProfile.findOne({ userId: tutor._id });
    if (!tutorProfile) {
      console.log('❌ Tutor profile not found');
      console.log('💡 Please create a tutor profile first');
      process.exit(1);
    }

    console.log(`📝 Creating availability slots for: ${tutor.firstName} ${tutor.lastName}`);
    console.log(`   Tutor ID: ${tutor._id}`);
    console.log(`   Profile ID: ${tutorProfile._id}\n`);

    // Delete existing slots for this tutor
    await AvailabilitySlot.deleteMany({ tutorId: tutorProfile._id });
    console.log('🗑️  Cleared existing slots\n');

    // Create slots for the next 7 days
    const slots = [];
    const today = new Date();
    
    for (let day = 1; day <= 7; day++) {
      const date = new Date(today);
      date.setDate(date.getDate() + day);
      
      // Create morning slots (9 AM - 12 PM)
      const morningSlots = [
        { start: '09:00', end: '10:00' },
        { start: '10:00', end: '11:00' },
        { start: '11:00', end: '12:00' },
      ];

      // Create afternoon slots (2 PM - 5 PM)
      const afternoonSlots = [
        { start: '14:00', end: '15:00' },
        { start: '15:00', end: '16:00' },
        { start: '16:00', end: '17:00' },
      ];

      // Create evening slots (6 PM - 8 PM)
      const eveningSlots = [
        { start: '18:00', end: '19:00' },
        { start: '19:00', end: '20:00' },
      ];

      const allSlots = [...morningSlots, ...afternoonSlots, ...eveningSlots];

      for (const slot of allSlots) {
        const availabilitySlot = new AvailabilitySlot({
          tutorId: tutorProfile._id,
          date: date,
          timeSlot: {
            startTime: slot.start,
            endTime: slot.end,
            durationMinutes: 60, // 1 hour
          },
          isAvailable: true,
        });

        await availabilitySlot.save();
        slots.push(availabilitySlot);
      }
    }

    console.log(`✅ Created ${slots.length} availability slots\n`);

    // Show summary
    console.log('📊 Summary:');
    console.log(`   Total slots: ${slots.length}`);
    console.log(`   Days covered: 7 days (${today.toDateString()} to ${new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toDateString()})`);
    console.log(`   Slots per day: ${slots.length / 7}`);
    console.log(`   Time slots: 9 AM - 8 PM\n`);

    // Show first few slots
    console.log('📅 Sample slots created:');
    for (let i = 0; i < Math.min(5, slots.length); i++) {
      const slot = slots[i];
      console.log(`   ${slot.date.toDateString()} ${slot.timeSlot.startTime} - ${slot.timeSlot.endTime}`);
    }
    console.log(`   ... and ${slots.length - 5} more\n`);

    console.log('🎉 Test availability slots created successfully!');
    console.log('\n📱 Next steps:');
    console.log('   1. Login as student in the mobile app');
    console.log('   2. Search for tutors');
    console.log(`   3. Click on "${tutor.firstName} ${tutor.lastName}"`);
    console.log('   4. You should now see available time slots');
    console.log('   5. Book a slot to test the booking system!\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('✅ Database connection closed');
  }
}

// Run the script
createTestAvailability();
