const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const dashboardController = require('../controllers/dashboardController');

// Student dashboard
router.get('/student', authenticate, authorize('student'), dashboardController.getStudentDashboard);

// Tutor dashboard
router.get('/tutor', authenticate, authorize('tutor'), dashboardController.getTutorDashboard);

// Tutor earnings analytics
router.get('/tutor/earnings-analytics', authenticate, authorize('tutor'), dashboardController.getTutorEarningsAnalytics);

module.exports = router;
