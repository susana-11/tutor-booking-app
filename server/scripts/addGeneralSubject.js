const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Subject = require('../models/Subject');

async function addGeneralSubject() {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI not found in .env file');
    }
    console.log('🔗 Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Check if General subject exists
    let generalSubject = await Subject.findOne({ name: 'General' });
    
    if (generalSubject) {
      console.log('✅ General subject already exists:', generalSubject._id);
    } else {
      // Create General subject
      generalSubject = await Subject.create({
        name: 'General',
        category: 'Other',
        description: 'General tutoring for all subjects',
        gradelevels: ['All Levels'],
        isActive: true,
        keywords: ['general', 'all subjects', 'tutoring'],
        searchTags: ['general']
      });
      console.log('✅ Created General subject:', generalSubject._id);
    }

    // List all subjects
    const allSubjects = await Subject.find();
    console.log('\n📚 All subjects in database:');
    allSubjects.forEach(subject => {
      console.log(`  - ${subject.name} (ID: ${subject._id})`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addGeneralSubject();
