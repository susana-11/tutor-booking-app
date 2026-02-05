require('dotenv').config();
const mongoose = require('mongoose');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function updateTutorRate() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Get tutor email
    const email = await question('Enter tutor email: ');
    
    // Find user
    const user = await User.findOne({ email: email.trim() });
    if (!user) {
      console.log('❌ User not found');
      rl.close();
      await mongoose.connection.close();
      return;
    }

    // Find tutor profile
    const tutor = await TutorProfile.findOne({ userId: user._id });
    if (!tutor) {
      console.log('❌ Tutor profile not found');
      rl.close();
      await mongoose.connection.close();
      return;
    }

    console.log(`\n📋 Current tutor info:`);
    console.log(`   Name: ${user.firstName} ${user.lastName}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Current Rate: ${tutor.pricing?.hourlyRate || 'NOT SET'} ${tutor.pricing?.currency || 'USD'}`);
    console.log(`   Subjects: ${tutor.subjects.map(s => s.name).join(', ')}`);

    // Get new rate
    const newRateStr = await question('\nEnter new hourly rate (or press Enter to cancel): ');
    
    if (!newRateStr.trim()) {
      console.log('❌ Cancelled');
      rl.close();
      await mongoose.connection.close();
      return;
    }

    const newRate = parseFloat(newRateStr);
    if (isNaN(newRate) || newRate < 1) {
      console.log('❌ Invalid rate. Must be a number >= 1');
      rl.close();
      await mongoose.connection.close();
      return;
    }

    // Update rate
    if (!tutor.pricing) {
      tutor.pricing = {};
    }
    tutor.pricing.hourlyRate = newRate;
    tutor.pricing.currency = tutor.pricing.currency || 'ETB';
    
    await tutor.save();

    console.log(`\n✅ Updated successfully!`);
    console.log(`   New Rate: ${tutor.pricing.hourlyRate} ${tutor.pricing.currency}`);

    rl.close();
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error);
    rl.close();
    process.exit(1);
  }
}

updateTutorRate();
