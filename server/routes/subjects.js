const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const subjectController = require('../controllers/subjectController');

const router = express.Router();

// Admin only routes (must come before other routes to avoid conflicts)
router.get('/admin', authenticate, authorize('admin'), subjectController.getAllSubjectsAdmin);
router.post('/admin', authenticate, authorize('admin'), subjectController.createSubject);
router.put('/admin/:id', authenticate, authorize('admin'), subjectController.updateSubject);
router.delete('/admin/:id', authenticate, authorize('admin'), subjectController.deleteSubject);

// Public routes (for tutors to select subjects)
router.get('/', subjectController.getAllSubjects);
router.get('/grade-levels', subjectController.getGradeLevels);
router.get('/categories', subjectController.getCategories);
router.get('/:id', subjectController.getSubjectById);

module.exports = router;