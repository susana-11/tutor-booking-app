require('dotenv').config();
const axios = require('axios');

const API_URL = process.env.API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

async function testRegistration() {
  console.log('🧪 Testing Registration Endpoint');
  console.log('API URL:', API_URL);
  console.log('');

  try {
    // Test registration with a new email
    const testEmail = `test${Date.now()}@gmail.com`;
    const registrationData = {
      firstName: 'Test',
      lastName: 'User',
      email: testEmail,
      password: '123abc',
      phone: '0912345678',
      role: 'student'
    };

    console.log('📝 Registering new user:', registrationData.email);
    
    const response = await axios.post(`${API_URL}/auth/register`, registrationData);
    
    console.log('✅ Registration successful!');
    console.log('Response status:', response.status);
    console.log('Response data:', JSON.stringify(response.data, null, 2));
    
    // Check if response has all required fields
    const data = response.data.data;
    console.log('');
    console.log('📋 Checking response fields:');
    console.log('  ✓ id:', data.id ? '✅' : '❌');
    console.log('  ✓ userId:', data.userId ? '✅' : '❌');
    console.log('  ✓ firstName:', data.firstName ? '✅' : '❌');
    console.log('  ✓ lastName:', data.lastName ? '✅' : '❌');
    console.log('  ✓ email:', data.email ? '✅' : '❌');
    console.log('  ✓ phone:', data.phone ? '✅' : '❌');
    console.log('  ✓ role:', data.role ? '✅' : '❌');
    console.log('  ✓ isEmailVerified:', data.isEmailVerified !== undefined ? '✅' : '❌');
    console.log('  ✓ profileCompleted:', data.profileCompleted !== undefined ? '✅' : '❌');
    console.log('  ✓ createdAt:', data.createdAt ? '✅' : '❌');
    console.log('  ✓ updatedAt:', data.updatedAt ? '✅' : '❌');
    
  } catch (error) {
    console.error('❌ Registration failed!');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testRegistration();
