const crypto = require('crypto');

const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const generateResetToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

const getOTPExpiry = () => {
  return new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
};

const getResetTokenExpiry = () => {
  return new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
};

module.exports = {
  generateOTP,
  generateResetToken,
  getOTPExpiry,
  getResetTokenExpiry,
};
