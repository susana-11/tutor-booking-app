const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

/**
 * Generate Agora RTC token for voice/video calls
 * @param {string} channelName - Unique channel name
 * @param {number} uid - User ID (must be number)
 * @param {string} role - 'publisher' or 'subscriber'
 * @param {number} expirationTimeInSeconds - Token expiration time (default: 3600 = 1 hour)
 * @returns {string} Agora RTC token
 */
function generateAgoraToken(channelName, uid, role = 'publisher', expirationTimeInSeconds = 3600) {
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId || !appCertificate) {
    throw new Error('Agora credentials not configured');
  }

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
  
  const roleType = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
  
  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      roleType,
      privilegeExpiredTs
    );
    
    return token;
  } catch (error) {
    console.error('Error generating Agora token:', error);
    throw new Error('Failed to generate call token');
  }
}

/**
 * Generate unique channel name for a call
 * @param {string} initiatorId - Initiator user ID
 * @param {string} receiverId - Receiver user ID
 * @returns {string} Unique channel name
 */
function generateChannelName(initiatorId, receiverId) {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `call_${timestamp}_${random}`;
}

/**
 * Convert MongoDB ObjectId to numeric UID for Agora
 * @param {string} objectId - MongoDB ObjectId string
 * @returns {number} Numeric UID
 */
function objectIdToUid(objectId) {
  // Convert ObjectId to number (use last 8 characters as hex)
  const hex = objectId.toString().slice(-8);
  return parseInt(hex, 16);
}

module.exports = {
  generateAgoraToken,
  generateChannelName,
  objectIdToUid
};
