require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function findUserByName() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Search for user with name containing "Yiche" or "Ayaleneh"
    const users = await User.find({
      $or: [
        { firstName: /yiche/i },
        { lastName: /ayaleneh/i },
        { firstName: /ayaleneh/i },
        { lastName: /yiche/i }
      ]
    }).select('email firstName lastName phone role isEmailVerified');

    console.log('\n🔍 Search Results for "Yiche Ayaleneh":');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (users.length === 0) {
      console.log('❌ No user found with name "Yiche Ayaleneh"');
      console.log('\n💡 Available test accounts:');
      
      // Show all users
      const allUsers = await User.find().select('email firstName lastName role').limit(10);
      allUsers.forEach(user => {
        console.log(`   ${user.role.toUpperCase()}: ${user.firstName} ${user.lastName} - ${user.email}`);
      });
    } else {
      console.log(`✅ Found ${users.length} user(s):\n`);
      users.forEach(user => {
        console.log(`📧 Email: ${user.email}`);
        console.log(`👤 Name: ${user.firstName} ${user.lastName}`);
        console.log(`📱 Phone: ${user.phone}`);
        console.log(`🎭 Role: ${user.role}`);
        console.log(`✉️  Verified: ${user.isEmailVerified ? 'Yes' : 'No'}`);
        console.log('');
      });
    }
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    await mongoose.connection.close();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

findUserByName();
