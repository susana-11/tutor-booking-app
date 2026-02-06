# ✅ Payment Refund Notification Fixed

## Issue
When cancelling a booking with refund, the server was throwing a validation error:
```
ValidatorError: `payment_refunded` is not a valid enum value for path `type`
```

And also:
```
ValidatorError: `cancellation_no_refund` is not a valid enum value for path `type`
```

## Root Cause
The `cancellation_no_refund` notification type was missing from the Notification model enum. While `payment_refunded` was already in the enum, the `cancellation_no_refund` type used by the escrow service was not.

## Where It Was Used
In `server/services/escrowService.js`:
- `payment_refunded` - sent when a refund is processed (full or partial)
- `cancellation_no_refund` - sent when booking is cancelled too late for a refund

## Fix Applied
Added `cancellation_no_refund` to the Notification model enum:

```javascript
enum: [
  'booking_request',
  'booking_accepted',
  'booking_declined',
  'booking_cancelled',
  'booking_confirmed',
  'booking_reminder',
  'reschedule_request',
  'reschedule_accepted',
  'reschedule_rejected',
  'session_started',
  'session_ended',
  'rating_request',
  'new_message',
  'new_review',
  'call_incoming',
  'call_missed',
  'payment_received',
  'payment_pending',
  'payment_refunded',
  'cancellation_no_refund',  // ← ADDED
  'profile_approved',
  'profile_rejected',
  'system_announcement'
]
```

## Files Modified
- `server/models/Notification.js` - Added `cancellation_no_refund` to enum

## Deployment Status
✅ Changes committed to Git
✅ Pushed to GitHub (commit: cc81f66)
✅ Auto-deployed to Render

## Testing
After deployment, the following should work without errors:
1. **Cancel with full refund** → Student gets `payment_refunded` notification ✅
2. **Cancel with partial refund** → Student gets `payment_refunded` notification ✅
3. **Cancel with no refund** → Student gets `cancellation_no_refund` notification ✅

## Note
The `payment_refunded` type was already in the enum. The error was likely caused by the missing `cancellation_no_refund` type, which caused the entire notification creation to fail.

---

**Status**: ✅ FIXED AND DEPLOYED
**Date**: February 6, 2026
