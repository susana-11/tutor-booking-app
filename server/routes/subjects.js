const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const subjectController = require('../controllers/subjectController');

const router = express.Router();

// Public routes (for tutors to select subjects)
router.get('/', subjectController.getAllSubjects);
router.get('/grade-levels', subjectController.getGradeLevels);
router.get('/categories', subjectController.getCategories);
router.get('/:id', subjectController.getSubjectById);

// Admin only routes
router.use(authenticate, authorize('admin'));

router.get('/admin', subjectController.getAllSubjectsAdmin);
router.post('/admin', subjectController.createSubject);
router.put('/admin/:id', subjectController.updateSubject);
router.delete('/admin/:id', subjectController.deleteSubject);

module.exports = router;