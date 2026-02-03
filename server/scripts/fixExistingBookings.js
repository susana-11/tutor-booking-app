require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const TutorProfile = require('../models/TutorProfile');

async function fixExistingBookings() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    console.log('🔍 Finding bookings to fix...');
    const bookings = await Booking.find({});
    console.log(`📦 Found ${bookings.length} bookings\n`);

    let fixed = 0;
    let skipped = 0;
    let errors = 0;

    for (const booking of bookings) {
      try {
        // Check if tutorProfileId already exists
        if (booking.tutorProfileId) {
          console.log(`⏭️  Skipping booking ${booking._id} - already has tutorProfileId`);
          skipped++;
          continue;
        }

        // Try to find tutor profile by the current tutorId
        const profile = await TutorProfile.findById(booking.tutorId);
        
        if (profile) {
          // Current tutorId is actually a profile ID
          console.log(`🔧 Fixing booking ${booking._id}:`);
          console.log(`   Old tutorId (Profile ID): ${booking.tutorId}`);
          console.log(`   New tutorId (User ID): ${profile.userId}`);
          console.log(`   New tutorProfileId: ${profile._id}`);
          
          booking.tutorProfileId = profile._id;
          booking.tutorId = profile.userId;
          await booking.save();
          
          console.log(`✅ Fixed!\n`);
          fixed++;
        } else {
          // tutorId might already be a User ID, try to find profile by userId
          const profileByUserId = await TutorProfile.findOne({ userId: booking.tutorId });
          
          if (profileByUserId) {
            console.log(`✅ Booking ${booking._id} already correct, just adding tutorProfileId`);
            booking.tutorProfileId = profileByUserId._id;
            await booking.save();
            fixed++;
          } else {
            console.log(`⚠️  Warning: Could not find tutor profile for booking ${booking._id}`);
            console.log(`   tutorId: ${booking.tutorId}`);
            skipped++;
          }
        }
      } catch (error) {
        console.error(`❌ Error fixing booking ${booking._id}:`, error.message);
        errors++;
      }
    }

    console.log('\n📊 Migration Summary:');
    console.log(`   Total bookings: ${bookings.length}`);
    console.log(`   ✅ Fixed: ${fixed}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log('');

    if (fixed > 0) {
      console.log('🎉 Migration completed successfully!');
      console.log('');
      console.log('📱 Now tutors should be able to see their bookings!');
    } else {
      console.log('ℹ️  No bookings needed fixing.');
    }

  } catch (error) {
    console.error('❌ Migration error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Disconnected from MongoDB');
  }
}

fixExistingBookings();
