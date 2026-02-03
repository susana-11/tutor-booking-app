const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Subject = require('../models/Subject');

async function addEconomicsSubject() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Check if Economics subject exists
    let economicsSubject = await Subject.findOne({ name: 'Economics' });
    
    if (economicsSubject) {
      console.log('✅ Economics subject already exists:', economicsSubject._id);
    } else {
      // Create Economics subject
      economicsSubject = await Subject.create({
        name: 'Economics',
        category: 'Business & Economics',
        description: 'Economics tutoring covering micro and macroeconomics',
        gradelevels: ['High School (9-12)', 'College/University', 'Adult/Professional'],
        isActive: true,
        keywords: ['economics', 'microeconomics', 'macroeconomics', 'business'],
        searchTags: ['economics', 'business']
      });
      console.log('✅ Created Economics subject:', economicsSubject._id);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addEconomicsSubject();
