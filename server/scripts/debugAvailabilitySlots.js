const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const AvailabilitySlot = require('../models/AvailabilitySlot');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');

async function debugAvailabilitySlots() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get all tutors
    console.log('👨‍🏫 Finding all tutors...');
    const tutors = await User.find({ role: 'tutor' }).select('_id email firstName lastName');
    console.log(`Found ${tutors.length} tutors:\n`);
    
    tutors.forEach((tutor, index) => {
      console.log(`${index + 1}. ${tutor.firstName} ${tutor.lastName} (${tutor.email})`);
      console.log(`   User ID: ${tutor._id}`);
    });
    console.log('');

    // Check availability slots for each tutor
    for (const tutor of tutors) {
      console.log(`\n📅 Checking availability slots for ${tutor.firstName} ${tutor.lastName}...`);
      console.log(`   Tutor User ID: ${tutor._id}`);
      
      // Get tutor profile
      const tutorProfile = await TutorProfile.findOne({ userId: tutor._id });
      if (tutorProfile) {
        console.log(`   Tutor Profile ID: ${tutorProfile._id}`);
        console.log(`   Status: ${tutorProfile.status}`);
        console.log(`   Is Active: ${tutorProfile.isActive}`);
        console.log(`   Is Available: ${tutorProfile.isAvailable}`);
      } else {
        console.log(`   ❌ No tutor profile found!`);
      }

      // Check slots with User ID
      const slotsWithUserId = await AvailabilitySlot.find({ 
        tutorId: tutor._id,
        isActive: true 
      }).sort({ date: 1 });
      
      console.log(`   Slots with User ID (${tutor._id}): ${slotsWithUserId.length}`);
      
      if (slotsWithUserId.length > 0) {
        console.log(`   📊 Slot details:`);
        slotsWithUserId.forEach((slot, idx) => {
          console.log(`      ${idx + 1}. Date: ${slot.date.toISOString().split('T')[0]}`);
          console.log(`         Time: ${slot.timeSlot.startTime} - ${slot.timeSlot.endTime}`);
          console.log(`         Available: ${slot.isAvailable}`);
          console.log(`         Booked: ${slot.isBooked}`);
          console.log(`         Active: ${slot.isActive}`);
        });
      }

      // Check slots with Profile ID (if exists)
      if (tutorProfile) {
        const slotsWithProfileId = await AvailabilitySlot.find({ 
          tutorId: tutorProfile._id,
          isActive: true 
        }).sort({ date: 1 });
        
        console.log(`   Slots with Profile ID (${tutorProfile._id}): ${slotsWithProfileId.length}`);
        
        if (slotsWithProfileId.length > 0) {
          console.log(`   📊 Slot details:`);
          slotsWithProfileId.forEach((slot, idx) => {
            console.log(`      ${idx + 1}. Date: ${slot.date.toISOString().split('T')[0]}`);
            console.log(`         Time: ${slot.timeSlot.startTime} - ${slot.timeSlot.endTime}`);
            console.log(`         Available: ${slot.isAvailable}`);
            console.log(`         Booked: ${slot.isBooked}`);
            console.log(`         Active: ${slot.isActive}`);
          });
        }
      }
    }

    // Check all slots in database
    console.log('\n\n📊 ALL AVAILABILITY SLOTS IN DATABASE:');
    const allSlots = await AvailabilitySlot.find({ isActive: true }).sort({ date: 1 });
    console.log(`Total active slots: ${allSlots.length}\n`);
    
    if (allSlots.length > 0) {
      allSlots.forEach((slot, idx) => {
        console.log(`${idx + 1}. Tutor ID: ${slot.tutorId}`);
        console.log(`   Date: ${slot.date.toISOString().split('T')[0]}`);
        console.log(`   Time: ${slot.timeSlot.startTime} - ${slot.timeSlot.endTime}`);
        console.log(`   Duration: ${slot.timeSlot.durationMinutes} minutes`);
        console.log(`   Available: ${slot.isAvailable}`);
        console.log(`   Booked: ${slot.isBooked}`);
        console.log(`   Created: ${slot.createdAt}`);
        console.log('');
      });
    } else {
      console.log('❌ No availability slots found in database!');
    }

    console.log('\n✅ Debug complete!');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

debugAvailabilitySlots();
