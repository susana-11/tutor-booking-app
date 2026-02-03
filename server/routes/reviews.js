const express = require('express');
const { authenticate } = require('../middleware/auth');
const reviewController = require('../controllers/reviewController');

const router = express.Router();

// Create a new review
router.post('/', authenticate, reviewController.createReview);

// Get reviews for a tutor
router.get('/tutor/:tutorId', reviewController.getTutorReviews);

// Get reviews written by a student
router.get('/student/:studentId', authenticate, reviewController.getStudentReviews);

// Get a single review
router.get('/:reviewId', reviewController.getReview);

// Update a review (within 24 hours)
router.put('/:reviewId', authenticate, reviewController.updateReview);

// Delete a review
router.delete('/:reviewId', authenticate, reviewController.deleteReview);

// Mark review as helpful/not helpful
router.put('/:reviewId/helpful', authenticate, reviewController.markHelpful);

// Tutor responds to a review
router.post('/:reviewId/response', authenticate, reviewController.addTutorResponse);

// Flag a review for moderation
router.post('/:reviewId/flag', authenticate, reviewController.flagReview);

module.exports = router;