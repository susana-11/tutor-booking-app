const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

const router = express.Router();

// Admin only routes
router.use(authenticate, authorize('admin'));

// Tutor approval routes
router.get('/tutors/pending', adminController.getPendingTutors);
router.get('/tutors', adminController.getAllTutors);
router.post('/tutors/:tutorId/approve', adminController.approveTutor);
router.post('/tutors/:tutorId/reject', adminController.rejectTutor);

// User management routes
router.get('/users', adminController.getAllUsers);
router.get('/users/by-role', adminController.getUsersByRole);
router.delete('/users/:userId', adminController.deleteUser);
router.post('/users/:userId/suspend', adminController.suspendUser);
router.post('/users/:userId/activate', adminController.activateUser);

// Dashboard stats
router.get('/stats', adminController.getDashboardStats);

// Booking management
router.get('/bookings', adminController.getAllBookings);

// Transaction management
router.get('/transactions', adminController.getAllTransactions);

// Analytics
router.get('/analytics', adminController.getAnalytics);

module.exports = router;
