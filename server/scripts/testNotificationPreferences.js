/**
 * Test script for notification preferences endpoints
 * 
 * This script tests:
 * 1. Getting notification preferences (should return defaults if not set)
 * 2. Updating notification preferences
 * 3. Getting updated preferences to verify changes
 * 
 * Usage:
 * 1. Make sure server is running
 * 2. Update the JWT_TOKEN with a valid token from a logged-in user
 * 3. Run: node server/scripts/testNotificationPreferences.js
 */

require('dotenv').config();
const axios = require('axios');

const API_URL = process.env.API_URL || 'http://localhost:5000/api';

// Replace this with a valid JWT token from a logged-in user
const JWT_TOKEN = 'YOUR_JWT_TOKEN_HERE';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Authorization': `Bearer ${JWT_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testNotificationPreferences() {
  console.log('🧪 Testing Notification Preferences Endpoints\n');
  console.log('='.repeat(60));

  try {
    // Test 1: Get current preferences
    console.log('\n📋 Test 1: Getting current notification preferences...');
    const getResponse = await api.get('/users/notification-preferences');
    console.log('✅ GET /users/notification-preferences');
    console.log('Response:', JSON.stringify(getResponse.data, null, 2));

    // Test 2: Update preferences
    console.log('\n📝 Test 2: Updating notification preferences...');
    const updateData = {
      emailNotifications: true,
      pushNotifications: true,
      bookingNotifications: true,
      messageNotifications: false, // Disable message notifications
      reviewNotifications: true,
      paymentNotifications: true,
      reminderNotifications: true,
      promotionalNotifications: true // Enable promotional
    };
    
    const updateResponse = await api.put('/users/notification-preferences', updateData);
    console.log('✅ PUT /users/notification-preferences');
    console.log('Response:', JSON.stringify(updateResponse.data, null, 2));

    // Test 3: Get updated preferences to verify
    console.log('\n🔍 Test 3: Verifying updated preferences...');
    const verifyResponse = await api.get('/users/notification-preferences');
    console.log('✅ GET /users/notification-preferences (after update)');
    console.log('Response:', JSON.stringify(verifyResponse.data, null, 2));

    // Verify the changes
    const prefs = verifyResponse.data.data;
    console.log('\n✅ Verification:');
    console.log(`  - Message Notifications: ${prefs.messageNotifications} (should be false)`);
    console.log(`  - Promotional Notifications: ${prefs.promotionalNotifications} (should be true)`);

    if (prefs.messageNotifications === false && prefs.promotionalNotifications === true) {
      console.log('\n🎉 All tests passed! Notification preferences are working correctly.');
    } else {
      console.log('\n⚠️ Warning: Preferences may not have been saved correctly.');
    }

  } catch (error) {
    console.error('\n❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
    
    if (JWT_TOKEN === 'YOUR_JWT_TOKEN_HERE') {
      console.log('\n💡 Tip: Make sure to replace JWT_TOKEN with a valid token from a logged-in user.');
    }
  }

  console.log('\n' + '='.repeat(60));
}

// Run the test
testNotificationPreferences();
