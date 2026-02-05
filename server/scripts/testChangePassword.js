/**
 * Test script for change password endpoint
 * 
 * This script tests:
 * 1. Changing password with correct current password
 * 2. Attempting to change with incorrect current password (should fail)
 * 3. Attempting to change with weak password (should fail)
 * 
 * Usage:
 * 1. Make sure server is running
 * 2. Update the JWT_TOKEN with a valid token from a logged-in user
 * 3. Update CURRENT_PASSWORD with the user's actual password
 * 4. Run: node server/scripts/testChangePassword.js
 * 
 * IMPORTANT: This will actually change the user's password!
 * Make sure to use a test account.
 */

require('dotenv').config();
const axios = require('axios');

const API_URL = process.env.API_URL || 'http://localhost:5000/api';

// Replace these with valid credentials
const JWT_TOKEN = 'YOUR_JWT_TOKEN_HERE';
const CURRENT_PASSWORD = 'YOUR_CURRENT_PASSWORD';
const NEW_PASSWORD = 'newPassword123';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Authorization': `Bearer ${JWT_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testChangePassword() {
  console.log('🧪 Testing Change Password Endpoint\n');
  console.log('='.repeat(60));

  try {
    // Test 1: Attempt with incorrect current password (should fail)
    console.log('\n❌ Test 1: Attempting with incorrect current password...');
    try {
      await api.put('/auth/change-password', {
        currentPassword: 'wrongPassword',
        newPassword: NEW_PASSWORD
      });
      console.log('⚠️ Warning: Should have failed but succeeded!');
    } catch (error) {
      if (error.response && error.response.status === 400) {
        console.log('✅ Correctly rejected incorrect current password');
        console.log('Message:', error.response.data.message);
      } else {
        throw error;
      }
    }

    // Test 2: Attempt with weak password (should fail)
    console.log('\n❌ Test 2: Attempting with weak password (< 6 chars)...');
    try {
      await api.put('/auth/change-password', {
        currentPassword: CURRENT_PASSWORD,
        newPassword: '12345' // Only 5 characters
      });
      console.log('⚠️ Warning: Should have failed but succeeded!');
    } catch (error) {
      if (error.response && error.response.status === 400) {
        console.log('✅ Correctly rejected weak password');
        console.log('Message:', error.response.data.message || error.response.data.errors);
      } else {
        throw error;
      }
    }

    // Test 3: Change password with correct credentials
    console.log('\n✅ Test 3: Changing password with correct credentials...');
    const response = await api.put('/auth/change-password', {
      currentPassword: CURRENT_PASSWORD,
      newPassword: NEW_PASSWORD
    });
    console.log('✅ PUT /auth/change-password');
    console.log('Response:', JSON.stringify(response.data, null, 2));

    // Test 4: Try to change back to original password
    console.log('\n🔄 Test 4: Changing password back to original...');
    const revertResponse = await api.put('/auth/change-password', {
      currentPassword: NEW_PASSWORD,
      newPassword: CURRENT_PASSWORD
    });
    console.log('✅ Password reverted successfully');
    console.log('Response:', JSON.stringify(revertResponse.data, null, 2));

    console.log('\n🎉 All tests passed! Change password endpoint is working correctly.');

  } catch (error) {
    console.error('\n❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
    
    if (JWT_TOKEN === 'YOUR_JWT_TOKEN_HERE' || CURRENT_PASSWORD === 'YOUR_CURRENT_PASSWORD') {
      console.log('\n💡 Tip: Make sure to replace JWT_TOKEN and CURRENT_PASSWORD with valid credentials.');
      console.log('⚠️ Warning: Use a test account as this will change the password!');
    }
  }

  console.log('\n' + '='.repeat(60));
}

// Run the test
testChangePassword();
