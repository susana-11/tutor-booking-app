require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');

async function fixBookingTutorId() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const bookingId = process.argv[2] || '698097d8ff5f72401b102d2d';
    
    console.log(`\n🔍 Fixing booking: ${bookingId}`);
    
    const booking = await Booking.findById(bookingId).lean();
    if (!booking) {
      console.log('❌ Booking not found');
      process.exit(1);
    }

    console.log(`Current tutorId: ${booking.tutorId}`);
    
    // Check if this is a User ID
    const user = await User.findById(booking.tutorId);
    if (user) {
      console.log(`✅ Found user: ${user.firstName} ${user.lastName} (${user.role})`);
      
      // Find the tutor profile for this user
      const tutorProfile = await TutorProfile.findOne({ userId: booking.tutorId });
      if (tutorProfile) {
        console.log(`✅ Found tutor profile: ${tutorProfile._id}`);
        
        // Update the booking
        await Booking.findByIdAndUpdate(bookingId, {
          tutorId: tutorProfile._id
        });
        
        console.log(`✅ Updated booking tutorId to: ${tutorProfile._id}`);
        
        // Verify the fix
        const updatedBooking = await Booking.findById(bookingId).populate('tutorId');
        console.log(`\n✅ Verification:`);
        console.log(`  Tutor Profile ID: ${updatedBooking.tutorId?._id}`);
        console.log(`  Can now be populated: ${updatedBooking.tutorId ? 'Yes' : 'No'}`);
      } else {
        console.log(`❌ No tutor profile found for user ${booking.tutorId}`);
        console.log(`⚠️  This booking should be deleted as it references an invalid tutor`);
      }
    } else {
      console.log(`❌ tutorId ${booking.tutorId} is not a valid User ID`);
      
      // Check if it's already a TutorProfile ID
      const tutorProfile = await TutorProfile.findById(booking.tutorId);
      if (tutorProfile) {
        console.log(`✅ tutorId is already a valid TutorProfile ID`);
      } else {
        console.log(`❌ tutorId is neither a User ID nor a TutorProfile ID`);
        console.log(`⚠️  This booking should be deleted`);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

fixBookingTutorId();
