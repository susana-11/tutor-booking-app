const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Student routes
router.get('/student/dashboard', authenticate, authorize('student'), (req, res) => {
  res.json({ message: 'Student dashboard', user: req.user });
});

// Tutor routes
router.get('/tutor/dashboard', authenticate, authorize('tutor'), (req, res) => {
  res.json({ message: 'Tutor dashboard', user: req.user });
});

// Admin routes
router.get('/admin/dashboard', authenticate, authorize('admin'), (req, res) => {
  res.json({ message: 'Admin dashboard', user: req.user });
});

module.exports = router;
