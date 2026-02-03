require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function updateStudentEmail() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Update the test student's email to a real one
    const result = await User.findOneAndUpdate(
      { email: 'etsebruk@example.com' },
      { email: 'etsebruk.test@gmail.com' }, // Use a real email
      { new: true }
    );

    if (result) {
      console.log('✅ Student email updated successfully');
      console.log('📧 New email:', result.email);
      console.log('👤 User ID:', result._id);
    } else {
      console.log('❌ Student not found');
    }

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateStudentEmail();
