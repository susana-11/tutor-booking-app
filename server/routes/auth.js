const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const registerValidation = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('phone')
    .matches(/^(\+\d{1,3}[- ]?)?\d{10,14}$/)
    .withMessage('Please provide a valid phone number'),
  body('role')
    .isIn(['student', 'tutor'])
    .withMessage('Role must be either student or tutor')
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

const otpValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('otp')
    .isLength({ min: 6, max: 6 })
    .isNumeric()
    .withMessage('OTP must be a 6-digit number')
];

// Routes
router.post('/register', registerValidation, authController.register);
router.post('/verify-email', otpValidation, authController.verifyEmail);
router.post('/resend-otp', body('email').isEmail().normalizeEmail(), authController.resendOTP);
router.post('/login', loginValidation, authController.login);
router.post('/logout', authenticate, authController.logout);
router.post('/refresh-token', authController.refreshToken);

// Password reset
router.post('/forgot-password', 
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  authController.forgotPassword
);
router.post('/reset-password',
  [
    body('token').notEmpty().withMessage('Reset token is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long')
  ],
  authController.resetPassword
);

// Profile completion check
router.get('/profile-status', authenticate, authController.getProfileStatus);

// Get current user (for admin panel)
router.get('/me', authenticate, authController.me);

// Change password (authenticated users)
router.put('/change-password',
  authenticate,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters long')
  ],
  authController.changePassword
);

module.exports = router;