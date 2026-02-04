const express = require('express');
const router = express.Router();
const availabilityController = require('../controllers/availabilityController');
const availabilitySlotController = require('../controllers/availabilitySlotController');
const { authenticate, authorize } = require('../middleware/auth');

// New availability slot management routes
router.get('/weekly', authenticate, authorize('tutor'), availabilitySlotController.getWeeklySchedule);
router.get('/slots', authenticate, availabilitySlotController.getAvailabilitySlots); // Allow both tutors and students
router.post('/slots', authenticate, authorize('tutor'), availabilitySlotController.createAvailabilitySlot);
router.post('/bulk', authenticate, authorize('tutor'), availabilitySlotController.createBulkAvailability);
router.put('/slots/:slotId', authenticate, authorize('tutor'), availabilitySlotController.updateAvailabilitySlot);
router.put('/slots/:slotId/toggle-availability', authenticate, authorize('tutor'), availabilitySlotController.toggleSlotAvailability);
router.delete('/slots/:slotId', authenticate, authorize('tutor'), availabilitySlotController.deleteAvailabilitySlot);

// Session management routes
router.get('/upcoming-sessions', authenticate, authorize('tutor'), availabilitySlotController.getUpcomingSessions);
router.post('/slots/:slotId/complete', authenticate, authorize('tutor'), availabilitySlotController.markSessionCompleted);
router.post('/slots/:slotId/cancel', authenticate, authorize('tutor'), availabilitySlotController.cancelSession);

// Legacy routes (keeping for backward compatibility)
// Get tutor's availability (for tutor's own view)
router.get('/my-availability', authenticate, availabilityController.getAvailability);

// Get specific tutor's availability (for students)
router.get('/tutor/:tutorId', authenticate, availabilityController.getAvailability);

// Get available slots for a specific date
router.get('/slots/:tutorId/:date', authenticate, availabilityController.getAvailableSlots);

// Update availability (tutors only)
router.put('/update', authenticate, availabilityController.updateAvailability);

// Toggle time slot availability (tutors only)
router.put('/toggle-slot', authenticate, availabilityController.toggleTimeSlot);

// Block a date (tutors only)
router.post('/block-date', authenticate, availabilityController.addBlockedDate);

// Remove blocked date (tutors only)
router.delete('/unblock-date/:date', authenticate, availabilityController.removeBlockedDate);

// Lock time slot (students only - for booking process)
router.post('/lock-slot', authenticate, availabilityController.lockTimeSlot);

// Release locked time slot
router.delete('/release-slot/:lockId', authenticate, availabilityController.releaseTimeSlot);

// Check real-time slot availability
router.get('/check-slot', authenticate, availabilityController.checkSlotAvailability);

module.exports = router;