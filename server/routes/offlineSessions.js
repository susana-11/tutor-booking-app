const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const offlineSessionController = require('../controllers/offlineSessionController');

// Check-in/Check-out
router.post('/:bookingId/check-in', auth, offlineSessionController.checkIn);
router.post('/:bookingId/check-out', auth, offlineSessionController.checkOut);
router.get('/:bookingId/check-in-status', auth, offlineSessionController.getCheckInStatus);

// Running late
router.post('/:bookingId/running-late', auth, offlineSessionController.notifyRunningLate);

// Location
router.put('/:bookingId/location', auth, offlineSessionController.setMeetingLocation);

// Safety
router.post('/:bookingId/report-issue', auth, offlineSessionController.reportSafetyIssue);
router.post('/:bookingId/share-session', auth, offlineSessionController.shareSession);
router.post('/:bookingId/emergency-contact', auth, offlineSessionController.setEmergencyContact);

module.exports = router;
