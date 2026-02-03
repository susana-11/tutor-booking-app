const mongoose = require('mongoose');
require('dotenv').config();

const AvailabilitySlot = require('../models/AvailabilitySlot');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');

async function checkTutorSlots() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // The tutorId being queried by student
    const queriedTutorId = '698181f5fe51257868d8f8bf';
    
    console.log('\n📊 CHECKING TUTOR DATA:');
    console.log('='.repeat(50));
    
    // 1. Check if this is a valid User ID
    const user = await User.findById(queriedTutorId);
    if (user) {
      console.log(`✅ User found: ${user.firstName} ${user.lastName} (${user.email})`);
      console.log(`   Role: ${user.role}`);
      console.log(`   User ID: ${user._id}`);
    } else {
      console.log(`❌ No user found with ID: ${queriedTutorId}`);
    }
    
    // 2. Check if this is a TutorProfile ID
    const profileById = await TutorProfile.findById(queriedTutorId).populate('userId');
    if (profileById) {
      console.log(`\n✅ TutorProfile found with this ID:`);
      console.log(`   Profile ID: ${profileById._id}`);
      console.log(`   User ID: ${profileById.userId._id}`);
      console.log(`   Name: ${profileById.userId.firstName} ${profileById.userId.lastName}`);
    } else {
      console.log(`\n❌ No TutorProfile found with ID: ${queriedTutorId}`);
    }
    
    // 3. Check if there's a TutorProfile for this userId
    const profileByUserId = await TutorProfile.findOne({ userId: queriedTutorId }).populate('userId');
    if (profileByUserId) {
      console.log(`\n✅ TutorProfile found for this userId:`);
      console.log(`   Profile ID: ${profileByUserId._id}`);
      console.log(`   User ID: ${profileByUserId.userId._id}`);
      console.log(`   Name: ${profileByUserId.userId.firstName} ${profileByUserId.userId.lastName}`);
    }
    
    console.log('\n📊 CHECKING AVAILABILITY SLOTS:');
    console.log('='.repeat(50));
    
    // 4. Check slots with this tutorId
    const slotsByQueriedId = await AvailabilitySlot.find({ tutorId: queriedTutorId });
    console.log(`\n🔍 Slots with tutorId = ${queriedTutorId}: ${slotsByQueriedId.length}`);
    if (slotsByQueriedId.length > 0) {
      slotsByQueriedId.forEach((slot, i) => {
        console.log(`   Slot ${i + 1}: ${slot.date.toDateString()} ${slot.timeSlot.startTime}-${slot.timeSlot.endTime}`);
      });
    }
    
    // 5. Check ALL slots in database
    const allSlots = await AvailabilitySlot.find({});
    console.log(`\n📊 Total slots in database: ${allSlots.length}`);
    
    if (allSlots.length > 0) {
      console.log('\n📋 All slots:');
      allSlots.forEach((slot, i) => {
        console.log(`   Slot ${i + 1}:`);
        console.log(`      tutorId: ${slot.tutorId}`);
        console.log(`      date: ${slot.date.toDateString()}`);
        console.log(`      time: ${slot.timeSlot.startTime}-${slot.timeSlot.endTime}`);
        console.log(`      isAvailable: ${slot.isAvailable}`);
        console.log(`      isActive: ${slot.isActive}`);
      });
      
      // Check if any slot's tutorId matches the profile ID
      const slotsByProfileId = allSlots.filter(s => s.tutorId.toString() === queriedTutorId);
      if (slotsByProfileId.length > 0) {
        console.log(`\n⚠️  Found ${slotsByProfileId.length} slots where tutorId matches the QUERIED ID`);
      }
      
      // Get unique tutorIds
      const uniqueTutorIds = [...new Set(allSlots.map(s => s.tutorId.toString()))];
      console.log(`\n📊 Unique tutorIds in slots: ${uniqueTutorIds.length}`);
      uniqueTutorIds.forEach(id => {
        console.log(`   - ${id}`);
      });
    }
    
    console.log('\n💡 DIAGNOSIS:');
    console.log('='.repeat(50));
    
    if (user && slotsByQueriedId.length === 0) {
      console.log('❌ PROBLEM: User exists but has no slots');
      console.log('   The tutor created slots but they were stored with a different tutorId');
      
      if (profileByUserId) {
        console.log(`\n💡 SOLUTION: Check if slots exist with Profile ID: ${profileByUserId._id}`);
        const slotsByProfileId = await AvailabilitySlot.find({ tutorId: profileByUserId._id });
        if (slotsByProfileId.length > 0) {
          console.log(`   ✅ Found ${slotsByProfileId.length} slots with Profile ID!`);
          console.log(`   ❌ ISSUE: Slots were created with Profile ID instead of User ID`);
          console.log(`\n🔧 FIX: Update slots to use User ID:`);
          console.log(`   db.availabilityslots.updateMany(`);
          console.log(`     { tutorId: ObjectId("${profileByUserId._id}") },`);
          console.log(`     { $set: { tutorId: ObjectId("${user._id}") } }`);
          console.log(`   )`);
        }
      }
    }
    
    if (!user && profileById) {
      console.log('❌ PROBLEM: The queried ID is a Profile ID, not a User ID');
      console.log(`   User ID should be: ${profileById.userId._id}`);
      console.log(`\n🔧 FIX: The mobile app should pass User ID, not Profile ID`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  }
}

checkTutorSlots();
