require('dotenv').config();
const mongoose = require('mongoose');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');

async function checkTutorRates() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all approved tutors
    const tutors = await TutorProfile.find({ status: 'approved' })
      .populate('userId', 'firstName lastName email');

    console.log(`\n📊 Found ${tutors.length} approved tutors\n`);

    tutors.forEach((tutor, index) => {
      const user = tutor.userId;
      const name = user ? `${user.firstName} ${user.lastName}` : 'Unknown';
      const email = user ? user.email : 'No email';
      
      console.log(`${index + 1}. ${name} (${email})`);
      console.log(`   Hourly Rate: ${tutor.pricing?.hourlyRate || 'NOT SET'} ${tutor.pricing?.currency || 'USD'}`);
      console.log(`   Subjects: ${tutor.subjects.map(s => s.name).join(', ') || 'None'}`);
      console.log(`   Status: ${tutor.status}`);
      console.log('');
    });

    // Check for tutors with 500 rate
    const tutorsWith500 = tutors.filter(t => t.pricing?.hourlyRate === 500);
    if (tutorsWith500.length > 0) {
      console.log(`\n⚠️  Found ${tutorsWith500.length} tutor(s) with 500 hourly rate:`);
      tutorsWith500.forEach(tutor => {
        const user = tutor.userId;
        const name = user ? `${user.firstName} ${user.lastName}` : 'Unknown';
        console.log(`   - ${name}: ${tutor.pricing?.hourlyRate} ${tutor.pricing?.currency}`);
      });
    }

    await mongoose.connection.close();
    console.log('\n✅ Done');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkTutorRates();
