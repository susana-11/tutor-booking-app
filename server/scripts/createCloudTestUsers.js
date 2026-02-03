require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const StudentProfile = require('../models/StudentProfile');
const Subject = require('../models/Subject');

async function createCloudTestUsers() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Create subjects first
    console.log('\n📚 Creating subjects...');
    const subjects = [
      { name: 'Mathematics', description: 'Math tutoring', category: 'Mathematics' },
      { name: 'Physics', description: 'Physics tutoring', category: 'Sciences' },
      { name: 'Chemistry', description: 'Chemistry tutoring', category: 'Sciences' },
      { name: 'Biology', description: 'Biology tutoring', category: 'Sciences' },
      { name: 'English', description: 'English tutoring', category: 'Languages' },
      { name: 'Economics', description: 'Economics tutoring', category: 'Business & Economics' },
      { name: 'General', description: 'General tutoring', category: 'Other' }
    ];

    for (const subject of subjects) {
      const existing = await Subject.findOne({ name: subject.name });
      if (!existing) {
        await Subject.create(subject);
        console.log(`✅ Created subject: ${subject.name}`);
      } else {
        console.log(`⏭️  Subject already exists: ${subject.name}`);
      }
    }

    // Create tutor user
    console.log('\n👨‍🏫 Creating tutor user...');
    const tutorEmail = 'bubuam13@gmail.com';
    let tutorUser = await User.findOne({ email: tutorEmail });
    
    if (!tutorUser) {
      const hashedPassword = await bcrypt.hash('123abc', 10);
      tutorUser = await User.create({
        email: tutorEmail,
        password: hashedPassword,
        firstName: 'Hindekie',
        lastName: 'Amanuel',
        phone: '0923394163',
        role: 'tutor',
        isEmailVerified: true,
        profileCompleted: true
      });
      console.log('✅ Tutor user created');
    } else {
      console.log('⏭️  Tutor user already exists');
    }

    // Create tutor profile
    console.log('\n📝 Creating tutor profile...');
    let tutorProfile = await TutorProfile.findOne({ userId: tutorUser._id });
    
    if (!tutorProfile) {
      const economicsSubject = await Subject.findOne({ name: 'Economics' });
      tutorProfile = await TutorProfile.create({
        userId: tutorUser._id,
        bio: 'Experienced Economics tutor with 5+ years of teaching experience.',
        headline: 'Expert Economics Tutor',
        experience: {
          years: 5,
          description: '5 years of teaching Economics at high school and university level'
        },
        education: [{
          degree: 'Bachelor',
          institution: 'Addis Ababa University',
          year: 2018,
          field: 'Economics'
        }],
        subjects: [{
          name: economicsSubject.name,
          category: economicsSubject.category,
          gradelevels: ['High School (9-12)', 'College/University'],
          experience: '5 years',
          isSpecialty: true
        }],
        pricing: {
          hourlyRate: 500,
          currency: 'ETB'
        },
        teachingMode: {
          online: true,
          inPerson: false
        },
        availability: {
          timezone: 'Africa/Addis_Ababa',
          schedule: []
        },
        verification: {
          status: 'approved',
          isVerified: true,
          verifiedAt: new Date()
        },
        settings: {
          isVisible: true,
          acceptingBookings: true,
          autoAcceptBookings: false
        },
        stats: {
          rating: 4.8,
          totalReviews: 15,
          totalEarnings: 25000,
          completedSessions: 50,
          totalStudents: 20
        }
      });
      console.log('✅ Tutor profile created');
    } else {
      console.log('⏭️  Tutor profile already exists');
    }

    // Create student user
    console.log('\n👨‍🎓 Creating student user...');
    const studentEmail = 'etsebruk@example.com'; // Update with actual email if different
    let studentUser = await User.findOne({ email: studentEmail });
    
    if (!studentUser) {
      const hashedPassword = await bcrypt.hash('123abc', 10);
      studentUser = await User.create({
        email: studentEmail,
        password: hashedPassword,
        firstName: 'Etsebruk',
        lastName: 'Amanuel',
        phone: '0911223344',
        role: 'student',
        isEmailVerified: true,
        profileCompleted: true
      });
      console.log('✅ Student user created');
    } else {
      console.log('⏭️  Student user already exists');
    }

    // Create student profile
    console.log('\n📝 Creating student profile...');
    let studentProfile = await StudentProfile.findOne({ userId: studentUser._id });
    
    if (!studentProfile) {
      studentProfile = await StudentProfile.create({
        userId: studentUser._id,
        dateOfBirth: new Date('2005-01-15'),
        grade: '12',
        school: 'Test High School',
        learningGoals: ['Improve Economics understanding', 'Prepare for university'],
        interests: ['Economics', 'Business']
      });
      console.log('✅ Student profile created');
    } else {
      console.log('⏭️  Student profile already exists');
    }

    console.log('\n🎉 Setup complete!');
    console.log('\n📱 Test Accounts:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('👨‍🏫 TUTOR ACCOUNT:');
    console.log(`   Email: ${tutorEmail}`);
    console.log('   Password: 123abc');
    console.log('   Name: Hindekie Amanuel');
    console.log('   Subject: Economics');
    console.log('   Rate: 500 ETB/hour');
    console.log('');
    console.log('👨‍🎓 STUDENT ACCOUNT:');
    console.log(`   Email: ${studentEmail}`);
    console.log('   Password: 123abc');
    console.log('   Name: Etsebruk Amanuel');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('\n✅ You can now login with these accounts on your mobile app!');

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createCloudTestUsers();
