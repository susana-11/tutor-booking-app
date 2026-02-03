const mongoose = require('mongoose');
const TutorProfile = require('../models/TutorProfile');
const User = require('../models/User');
require('dotenv').config();

// Connect to database
const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/tutor_booking';
        console.log(`🔌 Connecting to MongoDB...`);
        await mongoose.connect(uri);
        console.log('✅ MongoDB connected');
    } catch (error) {
        console.error('❌ MongoDB connection error:', error);
        process.exit(1);
    }
};

async function testVisibilityToggle() {
    await connectDB();

    try {
        console.log('\n👁️ Testing Profile Visibility Toggle\n');

        // Find a test tutor
        const tutorUser = await User.findOne({ role: 'tutor' });
        if (!tutorUser) {
            console.log('⚠️ No tutor found to test with.');
            process.exit(1);
        }

        console.log(`👤 Testing with tutor: ${tutorUser.firstName} ${tutorUser.lastName}`);

        let profile = await TutorProfile.findOne({ userId: tutorUser._id });
        if (!profile) {
            // Create profile if missing
            profile = await TutorProfile.create({
                userId: tutorUser._id,
                bio: 'Test Bio',
                subjects: [{ name: 'Test Subject', gradelevels: ['10'] }],
                pricing: { hourlyRate: 50 },
                isActive: true
            });
            console.log('   Created missing tutor profile');
        }

        // Search logic simulation (similar to routes/tutors.js)
        const searchTutors = async () => {
            const results = await TutorProfile.find({
                status: 'approved',
                isActive: true,
                _id: profile._id
            });
            return results.length > 0;
        };

        // Step 1: Ensure Approved and Active initially
        profile.status = 'approved';
        profile.isActive = true;
        await profile.save();

        console.log('1️⃣  State: Active & Approved');
        let isVisible = await searchTutors();
        console.log(`   Visible in search? ${isVisible ? '✅ YES' : '❌ NO'}`);

        if (!isVisible) {
            console.log('   ⚠️ Tutor not found in search even when active. Check approval status.');
        }

        // Step 2: Toggle Visibility OFF (Hide)
        console.log('\n2️⃣  Toggling Visibility -> OFF (Hidden)');
        // Simulate controller action
        profile.isActive = false;
        await profile.save();

        console.log('   State: Inactive (Hidden)');
        isVisible = await searchTutors();
        console.log(`   Visible in search? ${!isVisible ? '✅ NO (Correct)' : '❌ YES (Failed)'}`);

        // Step 3: Toggle Visibility ON (Show)
        console.log('\n3️⃣  Toggling Visibility -> ON (Visible)');
        profile.isActive = true;
        await profile.save();

        console.log('   State: Active (Visible)');
        isVisible = await searchTutors();
        console.log(`   Visible in search? ${isVisible ? '✅ YES (Correct)' : '❌ NO (Failed)'}`);

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await mongoose.connection.close();
        process.exit(0);
    }
}

testVisibilityToggle();
