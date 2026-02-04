const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const offlineSessionController = require('../controllers/offlineSessionController');

// Check-in/Check-out
router.post('/:bookingId/check-in', authenticate, offlineSessionController.checkIn);
router.post('/:bookingId/check-out', authenticate, offlineSessionController.checkOut);
router.get('/:bookingId/check-in-status', authenticate, offlineSessionController.getCheckInStatus);

// Running late
router.post('/:bookingId/running-late', authenticate, offlineSessionController.notifyRunningLate);

// Location
router.put('/:bookingId/location', authenticate, offlineSessionController.setMeetingLocation);

// Safety
router.post('/:bookingId/report-issue', authenticate, offlineSessionController.reportSafetyIssue);
router.post('/:bookingId/share-session', authenticate, offlineSessionController.shareSession);
router.post('/:bookingId/emergency-contact', authenticate, offlineSessionController.setEmergencyContact);

module.exports = router;
