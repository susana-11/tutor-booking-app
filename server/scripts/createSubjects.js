const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor-booking', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const Subject = require('../models/Subject');

const subjects = [
  {
    name: 'Mathematics',
    category: 'Mathematics',
    description: 'Mathematics including algebra, geometry, calculus, and statistics',
    gradelevels: ['Elementary (K-5)', 'Middle School (6-8)', 'High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'English',
    category: 'Languages',
    description: 'English language, literature, writing, and communication',
    gradelevels: ['Elementary (K-5)', 'Middle School (6-8)', 'High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'Computer Science',
    category: 'Technology & Computing',
    description: 'Programming, algorithms, data structures, and computer systems',
    gradelevels: ['High School (9-12)', 'College/University', 'Adult/Professional'],
    isActive: true
  },
  {
    name: 'Physics',
    category: 'Sciences',
    description: 'Classical mechanics, thermodynamics, electromagnetism, and quantum physics',
    gradelevels: ['High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'Chemistry',
    category: 'Sciences',
    description: 'Organic, inorganic, physical, and analytical chemistry',
    gradelevels: ['High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'Biology',
    category: 'Sciences',
    description: 'Cell biology, genetics, ecology, and human anatomy',
    gradelevels: ['Middle School (6-8)', 'High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'History',
    category: 'Social Studies',
    description: 'World history, American history, and historical analysis',
    gradelevels: ['Elementary (K-5)', 'Middle School (6-8)', 'High School (9-12)', 'College/University'],
    isActive: true
  },
  {
    name: 'Spanish',
    category: 'Languages',
    description: 'Spanish language, grammar, conversation, and culture',
    gradelevels: ['Middle School (6-8)', 'High School (9-12)', 'College/University', 'Adult/Professional'],
    isActive: true
  },
  {
    name: 'French',
    category: 'Languages',
    description: 'French language, grammar, conversation, and culture',
    gradelevels: ['Middle School (6-8)', 'High School (9-12)', 'College/University', 'Adult/Professional'],
    isActive: true
  },
  {
    name: 'Art',
    category: 'Arts & Humanities',
    description: 'Drawing, painting, sculpture, and art history',
    gradelevels: ['Elementary (K-5)', 'Middle School (6-8)', 'High School (9-12)', 'College/University'],
    isActive: true
  }
];

async function createSubjects() {
  try {
    console.log('🎯 Creating subjects...');
    
    // Clear existing subjects
    await Subject.deleteMany({});
    console.log('✅ Cleared existing subjects');
    
    // Create new subjects
    const createdSubjects = await Subject.insertMany(subjects);
    console.log(`✅ Created ${createdSubjects.length} subjects:`);
    
    createdSubjects.forEach(subject => {
      console.log(`   - ${subject.name} (${subject.category})`);
    });
    
    console.log('🎉 Subjects created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating subjects:', error);
    process.exit(1);
  }
}

createSubjects();