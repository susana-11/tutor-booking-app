require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function deleteUser() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const email = 'bubu@gmail.com';
    
    console.log(`\n🗑️  Deleting user: ${email}`);
    const result = await User.deleteOne({ email });
    
    if (result.deletedCount > 0) {
      console.log(`✅ Deleted user: ${email}`);
      console.log('\n🎉 You can now register with this email again!');
    } else {
      console.log(`❌ User not found: ${email}`);
    }

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

deleteUser();
