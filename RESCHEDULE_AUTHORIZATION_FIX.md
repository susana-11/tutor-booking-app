# Reschedule Authorization Fix

## Issue
Tutors were getting 403 "Not authorized to view reschedule requests for this booking" errors when trying to view reschedule requests.

## Root Cause
The authorization check in `getRescheduleRequests` was comparing:
- `booking.tutorId._id.toString()` (string)
- `req.user.userId` (ObjectId)

When comparing a string to an ObjectId in JavaScript, they are never equal even if they represent the same ID.

## Solution
Added `.toString()` to both sides of the comparison to ensure consistent string comparison:

```javascript
// Before
const isStudent = booking.studentId._id.toString() === req.user.userId;
const isTutor = booking.tutorId._id.toString() === req.user.userId;

// After
const isStudent = booking.studentId._id.toString() === req.user.userId.toString();
const isTutor = booking.tutorId._id.toString() === req.user.userId.toString();
```

## Files Modified
- `server/controllers/bookingController.js`
  - Fixed `getRescheduleRequests` (line ~1328)
  - Fixed `getBookingDetails` (line ~632)
  - Fixed payment authorization check (line ~822)

## Testing
After deploying this fix:
1. Login as a tutor
2. Navigate to a booking with reschedule requests
3. Click to view reschedule requests
4. Should now see the requests without 403 error

## Note
Other functions like `requestReschedule`, `respondToRescheduleRequest`, and `cancelBooking` already had the correct `.toString()` on both sides.
