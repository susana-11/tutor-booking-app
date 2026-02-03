const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const Subject = require('../models/Subject');

async function checkTutorSubjects() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const tutorId = '6981814afe51257868d8f88a'; // The tutor ID from the logs
    
    // Find tutor profile
    const tutor = await TutorProfile.findOne({ userId: tutorId }).populate('userId');
    
    if (!tutor) {
      console.log('❌ Tutor not found');
      process.exit(1);
    }

    console.log('\n📋 Tutor Info:');
    console.log('  Profile ID:', tutor._id);
    console.log('  User ID:', tutor.userId._id);
    console.log('  Name:', `${tutor.userId.firstName} ${tutor.userId.lastName}`);
    console.log('  Subjects:', tutor.subjects);
    console.log('  Subjects type:', typeof tutor.subjects[0]);

    // Check if subjects are strings or objects
    if (tutor.subjects && tutor.subjects.length > 0) {
      const firstSubject = tutor.subjects[0];
      
      if (typeof firstSubject === 'string') {
        console.log('\n⚠️  Subjects are stored as strings, not references');
        console.log('  Looking up subject in database...');
        
        const subject = await Subject.findOne({ name: firstSubject });
        if (subject) {
          console.log('  ✅ Found subject:', subject.name, '(ID:', subject._id + ')');
        } else {
          console.log('  ❌ Subject not found in database:', firstSubject);
        }
      } else if (typeof firstSubject === 'object') {
        console.log('\n✅ Subjects are stored as objects');
        console.log('  Subject:', firstSubject);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkTutorSubjects();
