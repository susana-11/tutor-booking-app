const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection failed:', error.message);
    console.log('⚠️  Server will continue without database connection');
    console.log('💡 To fix this, install and start MongoDB locally or use MongoDB Atlas');
    // Don't exit the process, just log the error
    // process.exit(1);
  }
};

module.exports = connectDB;
