require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const TutorProfile = require('../models/TutorProfile');
const StudentProfile = require('../models/StudentProfile');
const Subject = require('../models/Subject');

async function createMoreTestUsers() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get subjects
    const mathSubject = await Subject.findOne({ name: 'Mathematics' });
    const physicsSubject = await Subject.findOne({ name: 'Physics' });

    // Create additional tutor
    console.log('\n👨‍🏫 Creating additional tutor...');
    const tutor2Email = 'tutor2@example.com';
    let tutor2 = await User.findOne({ email: tutor2Email });
    
    if (!tutor2) {
      tutor2 = new User({
        email: tutor2Email,
        password: '123abc',
        firstName: 'Sarah',
        lastName: 'Johnson',
        phone: '0911111111',
        role: 'tutor',
        isEmailVerified: true,
        profileCompleted: true
      });
      await tutor2.save();
      console.log('✅ Tutor 2 created');

      // Create tutor profile
      await TutorProfile.create({
        userId: tutor2._id,
        bio: 'Passionate Mathematics and Physics tutor with 3 years of experience.',
        headline: 'Math & Physics Expert',
        experience: {
          years: 3,
          description: '3 years teaching Math and Physics'
        },
        education: [{
          degree: 'Bachelor',
          institution: 'Science University',
          year: 2020,
          field: 'Physics'
        }],
        subjects: [
          {
            name: mathSubject.name,
            category: mathSubject.category,
            gradelevels: ['High School (9-12)'],
            experience: '3 years',
            isSpecialty: true
          },
          {
            name: physicsSubject.name,
            category: physicsSubject.category,
            gradelevels: ['High School (9-12)'],
            experience: '3 years',
            isSpecialty: true
          }
        ],
        pricing: {
          hourlyRate: 400,
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
          rating: 4.5,
          totalReviews: 8,
          totalEarnings: 12000,
          completedSessions: 30,
          totalStudents: 15
        }
      });
      console.log('✅ Tutor 2 profile created');
    } else {
      console.log('⏭️  Tutor 2 already exists');
    }

    // Create additional student
    console.log('\n👨‍🎓 Creating additional student...');
    const student2Email = 'student2@example.com';
    let student2 = await User.findOne({ email: student2Email });
    
    if (!student2) {
      student2 = new User({
        email: student2Email,
        password: '123abc',
        firstName: 'Michael',
        lastName: 'Brown',
        phone: '0922222222',
        role: 'student',
        isEmailVerified: true,
        profileCompleted: true
      });
      await student2.save();
      console.log('✅ Student 2 created');

      // Create student profile
      await StudentProfile.create({
        userId: student2._id,
        dateOfBirth: new Date('2006-05-20'),
        grade: '11',
        school: 'Central High School',
        learningGoals: ['Improve Math skills', 'Prepare for exams'],
        interests: ['Mathematics', 'Physics']
      });
      console.log('✅ Student 2 profile created');
    } else {
      console.log('⏭️  Student 2 already exists');
    }

    console.log('\n🎉 Additional users created!');
    console.log('\n📱 All Test Accounts:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('👨‍🏫 TUTOR 1:');
    console.log('   Email: bubuam13@gmail.com');
    console.log('   Password: 123abc');
    console.log('   Subject: Economics');
    console.log('');
    console.log('👨‍🏫 TUTOR 2:');
    console.log('   Email: tutor2@example.com');
    console.log('   Password: 123abc');
    console.log('   Subjects: Math, Physics');
    console.log('');
    console.log('👨‍🎓 STUDENT 1:');
    console.log('   Email: etsebruk@example.com');
    console.log('   Password: 123abc');
    console.log('');
    console.log('👨‍🎓 STUDENT 2:');
    console.log('   Email: student2@example.com');
    console.log('   Password: 123abc');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createMoreTestUsers();
