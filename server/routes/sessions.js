const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const sessionController = require('../controllers/sessionController');

// All routes require authentication
router.use(authenticate);

// Start a session
router.post('/:bookingId/start', sessionController.startSession);

// Join an active session
router.post('/:bookingId/join', sessionController.joinSession);

// End a session
router.post('/:bookingId/end', sessionController.endSession);

// Get session status
router.get('/:bookingId/status', sessionController.getSessionStatus);

// Release escrow (admin or automated)
router.post('/:bookingId/release-escrow', sessionController.releaseEscrow);

module.exports = router;
