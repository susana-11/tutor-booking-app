require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function cleanupIncompleteUsers() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    console.log('\n🔍 Finding incomplete user registrations...');
    
    // Find users that are not email verified and were created recently
    const incompleteUsers = await User.find({
      isEmailVerified: false,
      createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } // Last 24 hours
    });

    console.log(`\n📊 Found ${incompleteUsers.length} incomplete registrations:`);
    
    if (incompleteUsers.length === 0) {
      console.log('✅ No incomplete registrations found!');
    } else {
      incompleteUsers.forEach((user, index) => {
        console.log(`${index + 1}. ${user.email} (${user.role}) - Created: ${user.createdAt}`);
      });

      console.log('\n🗑️  Deleting incomplete registrations...');
      const result = await User.deleteMany({
        isEmailVerified: false,
        createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
      });

      console.log(`✅ Deleted ${result.deletedCount} incomplete user(s)`);
      console.log('\n🎉 Cleanup complete! You can now register with those emails again.');
    }

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

cleanupIncompleteUsers();
