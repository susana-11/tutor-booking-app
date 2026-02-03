const express = require('express');
const { authenticate } = require('../middleware/auth');
const callController = require('../controllers/callController');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

// Call management
router.post('/initiate', callController.initiateCall);
router.post('/:callId/answer', callController.answerCall);
router.post('/:callId/reject', callController.rejectCall);
router.post('/:callId/end', callController.endCall);

// Call history and stats
router.get('/history', callController.getCallHistory);
router.get('/missed', callController.getMissedCalls);
router.get('/stats', callController.getCallStats);

module.exports = router;
