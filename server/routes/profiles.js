const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const studentProfileController = require('../controllers/studentProfileController');
const tutorProfileController = require('../controllers/tutorProfileController');

const router = express.Router();

// Student Profile Routes
router.get('/student/profile', authenticate, authorize('student'), studentProfileController.getMyProfile);
router.get('/student/profile/:userId', studentProfileController.getProfile);
router.put('/student/profile', authenticate, authorize('student'), studentProfileController.updateProfile);

// Tutor Profile Routes
router.get('/tutor/profile', authenticate, authorize('tutor'), tutorProfileController.getMyProfile);
router.get('/tutor/profile/:userId', tutorProfileController.getProfile);
router.post('/tutor/profile', authenticate, authorize('tutor'), tutorProfileController.createProfile);
router.put('/tutor/profile', authenticate, authorize('tutor'), tutorProfileController.updateProfile);
router.post('/tutor/certificate', authenticate, authorize('tutor'), tutorProfileController.uploadCertificate);
router.put('/tutor/visibility', authenticate, authorize('tutor'), tutorProfileController.toggleVisibility);

// Browse tutors (for students)
router.get('/tutors', authenticate, tutorProfileController.getAllTutors);
router.get('/tutors/public', tutorProfileController.getAllTutors);

module.exports = router;
