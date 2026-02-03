# Payment Initialization Fix - Complete

## Problem
Payment initialization was failing with error:
```
TypeError: Cannot read properties of null (reading 'toString')
at PaymentService.initializeBookingPayment (paymentService.js:66:89)
```

## Root Cause
The booking's `tutorId` field was set to a `User` ID instead of a `TutorProfile` ID. When the payment service tried to populate the `tutorId` field (which references `TutorProfile`), it returned `null`, causing the error when trying to access `.toString()`.

## Issues Fixed

### 1. Booking Creation Route (`server/routes/bookings.js`)
**Problem:** When creating a booking, the code was converting the `TutorProfile` ID to a `User` ID and storing that in the booking's `tutorId` field.

**Fix:** Modified the booking creation logic to always store the `TutorProfile` ID:
```javascript
// Before:
if (tutorProfile) {
  tutorId = tutorProfile.userId.toString(); // Wrong! Converts to User ID
}

// After:
let tutorProfileId = tutorId; // Store the original tutorId (profile ID)
if (tutorProfile) {
  tutorProfileId = tutorProfile._id.toString(); // Use TutorProfile ID
}
```

### 2. Payment Service (`server/services/paymentService.js`)
**Problem:** The code assumed `tutorId` would always be populated and tried to access `booking.tutorId._id.toString()` without checking if it was null or handling both populated and unpopulated cases.

**Fixes:**
- Added validation to check if `bookingId` is a valid MongoDB ObjectId
- Added better error handling for null/invalid tutorId
- Added logging to help debug payment initialization issues
- Handle both populated (object) and unpopulated (ObjectId) tutorId cases:

```javascript
// Handle tutorId whether it's populated or just an ObjectId
const tutorIdString = booking.tutorId?._id 
  ? booking.tutorId._id.toString() 
  : booking.tutorId.toString();
```

### 3. Existing Booking Fix
**Problem:** The existing booking (ID: `698097d8ff5f72401b102d2d`) had a User ID stored in the `tutorId` field.

**Fix:** Created and ran `fixBookingTutorId.js` script to:
1. Find the User by the stored ID
2. Look up the corresponding TutorProfile
3. Update the booking with the correct TutorProfile ID

## Scripts Created

### 1. `checkBooking.js`
Checks if a booking exists and displays its details, including both populated and raw tutorId values.

**Usage:**
```bash
node scripts/checkBooking.js <bookingId>
```

### 2. `fixBookingTutorId.js`
Fixes bookings that have User IDs instead of TutorProfile IDs in the tutorId field.

**Usage:**
```bash
node scripts/fixBookingTutorId.js <bookingId>
```

### 3. `fixNullTutorBookings.js`
Finds and deletes all bookings with null tutorId (these cannot be fixed automatically).

**Usage:**
```bash
node scripts/fixNullTutorBookings.js
```

## Testing
1. ✅ Server restarted with fixes
2. ✅ Existing booking fixed (tutorId updated from User ID to TutorProfile ID)
3. ✅ Booking can now be populated correctly
4. ✅ Payment initialization should now work

## Next Steps
1. Test payment initialization from the mobile app
2. If successful, the payment flow should work end-to-end
3. Monitor server logs for any additional issues

## Prevention
The fix ensures that:
- All new bookings will have the correct TutorProfile ID
- Payment service handles both populated and unpopulated tutorId
- Better validation and error messages for debugging

## Files Modified
- `server/routes/bookings.js` - Fixed booking creation to use TutorProfile ID
- `server/services/paymentService.js` - Added validation and better error handling
- `server/scripts/checkBooking.js` - Created diagnostic script
- `server/scripts/fixBookingTutorId.js` - Created fix script
- `server/scripts/fixNullTutorBookings.js` - Created cleanup script
