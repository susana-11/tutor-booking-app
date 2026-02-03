// Temporary OTP storage for testing
// In production, use email/SMS instead
const otpStore = new Map();

const storeOTP = (email, otp) => {
  otpStore.set(email, {
    otp,
    timestamp: Date.now(),
  });
};

const getOTP = (email) => {
  return otpStore.get(email)?.otp;
};

const clearOTP = (email) => {
  otpStore.delete(email);
};

module.exports = {
  storeOTP,
  getOTP,
  clearOTP,
};
