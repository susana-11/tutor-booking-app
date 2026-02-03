const express = require('express');
const { authenticate, authorize } = require('../middleware/auth');
const subjectController = require('../controllers/subjectController');

const router = express.Router();

// Public routes (for tutors to select subjects)
router.get('/subjects', subjectController.getAllSubjects);
router.get('/subjects/:id', subjectController.getSubjectById);
router.get('/grade-levels', subjectController.getGradeLevels);
router.get('/categories', subjectController.getCategories);

// Admin only routes
router.use(authenticate, authorize('admin'));

router.get('/admin/subjects', subjectController.getAllSubjectsAdmin);
router.post('/admin/subjects', subjectController.createSubject);
router.put('/admin/subjects/:id', subjectController.updateSubject);
router.delete('/admin/subjects/:id', subjectController.deleteSubject);

module.exports = router;