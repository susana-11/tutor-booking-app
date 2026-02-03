require('dotenv').config();
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

console.log('\n🔍 Testing Agora Configuration...\n');

const appId = process.env.AGORA_APP_ID;
const appCertificate = process.env.AGORA_APP_CERTIFICATE;

// Check if credentials exist
if (!appId) {
  console.error('❌ AGORA_APP_ID not found in .env file');
  process.exit(1);
}

if (!appCertificate || appCertificate === 'your_certificate_here_after_enabling') {
  console.error('❌ AGORA_APP_CERTIFICATE not set in .env file');
  console.error('📝 Please enable the certificate in Agora Console and add it to .env');
  process.exit(1);
}

console.log('✅ App ID found:', appId.substring(0, 8) + '...');
console.log('✅ App Certificate found:', appCertificate.substring(0, 8) + '...\n');

// Test token generation
console.log('🔐 Testing token generation...\n');

const channelName = 'test-channel-' + Date.now();
const uid = 12345;
const role = RtcRole.PUBLISHER;
const expirationTimeInSeconds = 3600; // 1 hour
const currentTimestamp = Math.floor(Date.now() / 1000);
const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

try {
  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );
  
  console.log('✅ Token generated successfully!');
  console.log('📋 Channel Name:', channelName);
  console.log('👤 User ID:', uid);
  console.log('🎭 Role:', role === RtcRole.PUBLISHER ? 'Publisher' : 'Subscriber');
  console.log('⏰ Expires in:', expirationTimeInSeconds / 60, 'minutes');
  console.log('🔑 Token (first 50 chars):', token.substring(0, 50) + '...');
  console.log('\n🎉 Agora setup is complete and working!\n');
  console.log('📱 You can now implement voice and video calling features.');
  console.log('');
} catch (error) {
  console.error('❌ Error generating token:', error.message);
  console.error('\n💡 Troubleshooting:');
  console.error('   1. Make sure you enabled the certificate in Agora Console');
  console.error('   2. Copy the entire certificate (32 characters)');
  console.error('   3. Update AGORA_APP_CERTIFICATE in .env file');
  console.error('   4. Restart this script\n');
  process.exit(1);
}
