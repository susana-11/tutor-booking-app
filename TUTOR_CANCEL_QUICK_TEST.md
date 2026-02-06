# 🧪 Quick Test Guide: Tutor Cancellation Feature

## Prerequisites
- Rebuild mobile app to get latest changes
- Have a confirmed booking as tutor
- Student should have paid for the booking

## Test Steps

### 1. Rebuild Mobile App
```bash
# Windows
rebuild-support.bat

# Or manually
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### 2. Test Tutor Cancellation

#### As Tutor:
1. **Login as tutor**
   - Use your tutor account

2. **Navigate to Bookings**
   - Tap "Bookings" from bottom navigation
   - Go to "Confirmed" tab

3. **Find a Confirmed Booking**
   - Should see booking with:
     - Student name
     - Subject
     - Date/Time
     - "Start Session" button
     - "Message" and "Reschedule" buttons
     - **NEW: "Requests" and "Cancel" buttons**

4. **Click Cancel Button**
   - Red button with cancel icon
   - Should open cancel dialog

5. **Verify Dialog Shows:**
   - ✅ "Cancel Booking" title
   - ✅ "100%" refund percentage in green
   - ✅ Full refund amount (ETB X.XX)
   - ✅ Message: "Student will receive 100% refund (Tutor cancellation)"
   - ✅ Policy text:
     ```
     • Tutor cancellations: 100% refund to student
     • Student will be notified immediately
     • Booking slot will become available
     ```
   - ✅ Reason input field
   - ✅ "Keep Booking" and "Cancel Booking" buttons

6. **Enter Cancellation Reason**
   - Type: "Emergency - need to reschedule"
   - Click "Cancel Booking"

7. **Verify Success**
   - ✅ Dialog closes
   - ✅ Success message: "Booking cancelled. Student will receive 100% refund."
   - ✅ Booking disappears from Confirmed tab
   - ✅ Booking appears in Cancelled tab

#### As Student:
1. **Login as student** (the one who booked)

2. **Check Notifications**
   - ✅ Should see notification about cancellation
   - ✅ Message mentions tutor cancelled
   - ✅ Mentions 100% refund

3. **Check Bookings**
   - Go to "My Bookings"
   - ✅ Booking moved to "Cancelled" tab
   - ✅ Shows cancellation reason
   - ✅ Shows refund status

4. **Check Refund**
   - ✅ Payment status shows "refunded"
   - ✅ Refund amount = 100% of payment

## Compare with Student Cancellation

### Test Student Cancellation (for comparison):
1. **Login as student**
2. **Book a new session** (or use existing)
3. **Cancel the booking**
4. **Verify refund based on timing:**
   - 1+ hours before: 100% refund
   - 30min-1hr before: 50% refund
   - <30min before: 0% refund

### Key Differences:
| Aspect | Student Cancel | Tutor Cancel |
|--------|---------------|--------------|
| Refund | Time-based | Always 100% |
| UI Color | Orange/Red/Green | Always Green |
| Policy | 3-tier | Single tier |
| Message | Time-based | "Tutor cancelled" |

## Expected Results

### ✅ Success Criteria:
- [ ] Cancel button visible on tutor confirmed bookings
- [ ] Dialog shows 100% refund for tutors
- [ ] Cancellation reason required
- [ ] Booking cancelled successfully
- [ ] Student receives notification
- [ ] Student sees 100% refund
- [ ] Booking moves to cancelled tab
- [ ] Availability slot becomes available

### ❌ Common Issues:

**Issue: Cancel button not showing**
- Solution: Rebuild app with `flutter clean && flutter run`

**Issue: Dialog shows time-based refund**
- Solution: Check `isTutor: true` is passed in bookingDetails

**Issue: Backend returns error**
- Solution: Backend should already support this (check logs)

**Issue: Student doesn't get notification**
- Solution: Check notification service and socket connection

## Backend Verification

### Check Backend Logs:
```bash
# Should see in Render logs:
✅ Tutor cancellation - full refund: { refundAmount: X, refundPercentage: 100 }
✅ Refund processed: { refundAmount: X, refundPercentage: 100 }
📧 Sending cancellation notification
```

### Check Database:
```javascript
// Booking should have:
{
  status: 'cancelled',
  cancelledBy: tutorId,
  refundAmount: totalAmount,
  refundPercentage: 100,
  refundStatus: 'processing',
  escrow: { status: 'refunded' }
}
```

## Troubleshooting

### If Cancel Button Not Showing:
1. Check you're on "Confirmed" tab
2. Verify booking status is "confirmed"
3. Rebuild app: `flutter clean && flutter run`

### If Refund Not 100%:
1. Check `isTutor: true` in dialog params
2. Verify backend logs show tutor cancellation
3. Check booking.cancelledBy matches tutor ID

### If Student Not Notified:
1. Check socket connection
2. Verify notification service running
3. Check student's notification settings

## Next Steps After Testing

1. **If all tests pass:**
   - Deploy to production
   - Monitor for issues
   - Update user documentation

2. **If issues found:**
   - Check console logs
   - Verify backend deployment
   - Test socket connections
   - Check notification service

## Quick Commands

```bash
# Rebuild app
flutter clean && flutter pub get && flutter run

# Check backend logs (Render)
# Go to Render dashboard → tutor-app-backend → Logs

# Git status
git status
git log --oneline -5

# Push to production
git push origin main
```

## Status: READY TO TEST ✅

All code is committed and ready for testing. Backend already supports 100% refund for tutors, we just added the UI.
