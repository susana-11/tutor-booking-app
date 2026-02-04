require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function updateStudentEmail() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Update the test student's email to a real one
    console.log('🔍 Looking for student with email: etsebruk@example.com');
    
    const result = await User.findOneAndUpdate(
      { email: 'etsebruk@example.com' },
      { email: 'etsebruk.test@gmail.com' },
      { new: true }
    );

    if (result) {
      console.log('✅ Student email updated successfully!');
      console.log('📧 Old email: etsebruk@example.com');
      console.log('📧 New email:', result.email);
      console.log('👤 User ID:', result._id);
      console.log('👤 Name:', result.firstName, result.lastName);
      console.log('');
      console.log('🎉 DONE! You can now test payments with this account.');
      console.log('📱 Login with: etsebruk.test@gmail.com / 123abc');
    } else {
      console.log('❌ Student not found with email: etsebruk@example.com');
      console.log('ℹ️  The email might have already been changed.');
    }

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

updateStudentEmail();
