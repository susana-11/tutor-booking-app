# 🔧 Notification Debug Guide

## Issue Summary

**Problem:** Notifications for cancel and reschedule operations only work in one direction:
- ✅ **Works:** Student cancels → Tutor receives notification
- ❌ **Doesn't work:** Tutor cancels → Student doesn't receive notification
- ❌ **Doesn't work:** Reschedule notifications (both directions)

## What Was Fixed

### 1. Enhanced Logging

Added comprehensive logging to track notification flow:

**In `bookingController.js`:**
- Cancel booking notifications (line ~545)
- Reschedule request notifications (line ~1000)
- Reschedule response notifications (line ~1195)

**In `notificationService.js`:**
- `createNotification()` method
- `notifyBookingCancelled()` method

### 2. Improved Notification Priority

Changed cancellation notification priority from `normal` to `high` to ensure delivery.

### 3. Better Error Handling

All notification errors are now logged with emoji indicators:
- 📧 = Sending notification
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning

## How to Debug

### Step 1: Check Server Logs

When a cancellation or reschedule happens, you should see logs like:

```
📧 Sending cancellation notification: {
  from: 'John Doe',
  fromRole: 'student',
  to: '507f1f77bcf86cd799439011',
  toRole: 'tutor',
  bookingId: '507f191e810c19729de860ea'
}
📝 Creating notification: {
  userId: '507f1f77bcf86cd799439011',
  type: 'booking_cancelled',
  title: 'Booking Cancelled',
  priority: 'high'
}
✅ Notification saved to database: 507f191e810c19729de860eb
✅ Real-time notification emitted via Socket.IO
✅ Cancellation notification sent successfully
```

### Step 2: Run the Test Script

```bash
test-cancel-reschedule-notifications.bat
```

This will:
1. Find a recent booking
2. Check notifications for both student and tutor
3. Show all cancel/reschedule notifications

### Step 3: Check Database

Manually verify notifications are being created:

```javascript
// In MongoDB shell or Compass
db.notifications.find({
  type: { $in: ['booking_cancelled', 'reschedule_request', 'reschedule_accepted', 'reschedule_rejected'] }
}).sort({ createdAt: -1 }).limit(10)
```

## Common Issues and Solutions

### Issue 1: Notifications Created But Not Delivered

**Symptoms:**
- Logs show "✅ Notification saved to database"
- But user doesn't receive notification on mobile app

**Possible Causes:**
1. **Device token not registered**
   - Check: `db.devicetokens.find({ userId: ObjectId('...') })`
   - Solution: User needs to log in again to register device token

2. **Socket.IO not connected**
   - Check logs for: "⚠️ Socket.IO not available for real-time notification"
   - Solution: Ensure Socket.IO is properly initialized in server

3. **Firebase not configured**
   - Check logs for: "⚠️ Firebase credentials not found"
   - Solution: Add FIREBASE_SERVICE_ACCOUNT to .env

### Issue 2: Notification Error in Logs

**Symptoms:**
- Logs show "❌ Failed to send cancellation notification"

**Solution:**
1. Check the error message in logs
2. Verify booking has both studentId and tutorId populated
3. Ensure User model has firstName and lastName fields

### Issue 3: Wrong User Receives Notification

**Symptoms:**
- Student cancels but student receives notification (instead of tutor)

**Solution:**
- Check the `isStudent` and `isTutor` logic in cancelBooking
- Verify `notifyUserId` is correctly set to the OTHER party

## Testing Scenarios

### Test 1: Student Cancels Booking

1. Login as student
2. Go to bookings
3. Cancel a confirmed booking
4. **Expected:** Tutor receives notification
5. **Check:** Server logs and tutor's notification list

### Test 2: Tutor Cancels Booking

1. Login as tutor
2. Go to bookings
3. Cancel a confirmed booking
4. **Expected:** Student receives notification
5. **Check:** Server logs and student's notification list

### Test 3: Student Requests Reschedule

1. Login as student
2. Go to bookings
3. Request to reschedule a booking
4. **Expected:** Tutor receives notification
5. **Check:** Server logs and tutor's notification list

### Test 4: Tutor Responds to Reschedule

1. Login as tutor
2. Go to bookings
3. Accept or reject reschedule request
4. **Expected:** Student receives notification
5. **Check:** Server logs and student's notification list

## Code Changes Summary

### `server/controllers/bookingController.js`

1. **Cancel Booking** (line ~545):
   - Added detailed logging
   - Added role tracking (student/tutor)
   - Better error messages

2. **Request Reschedule** (line ~1000):
   - Added detailed logging
   - Added role tracking
   - Better error messages

3. **Respond to Reschedule** (line ~1195):
   - Added detailed logging
   - Added role tracking
   - Better error messages

### `server/services/notificationService.js`

1. **createNotification** (line ~10):
   - Added logging for notification creation
   - Added logging for Socket.IO emission
   - Better error tracking

2. **notifyBookingCancelled** (line ~230):
   - Added logging
   - Changed priority from 'normal' to 'high'
   - Added cancelledBy name to notification body
   - Ensure bookingId is converted to string

## Next Steps

1. **Restart the server** to apply changes:
   ```bash
   restart-server.bat
   ```

2. **Test each scenario** listed above

3. **Monitor server logs** during testing

4. **Run the test script** to verify notifications in database:
   ```bash
   test-cancel-reschedule-notifications.bat
   ```

5. **Check mobile app** to ensure notifications appear

## Expected Behavior After Fix

### Cancellation Flow

1. User A cancels booking
2. Server logs show:
   - "📧 Sending cancellation notification"
   - "📝 Creating notification"
   - "✅ Notification saved to database"
   - "✅ Real-time notification emitted via Socket.IO"
   - "✅ Cancellation notification sent successfully"
3. User B receives notification:
   - In-app notification badge updates
   - Push notification (if app is in background)
   - Real-time notification (if app is open)

### Reschedule Flow

1. User A requests reschedule
2. Server logs show notification sent to User B
3. User B receives notification
4. User B accepts/rejects
5. Server logs show notification sent to User A
6. User A receives notification

## Troubleshooting Commands

```bash
# Check recent notifications
node server/scripts/testCancelRescheduleNotifications.js

# Check device tokens
# In MongoDB shell:
db.devicetokens.find({ isActive: true })

# Check Socket.IO connections
# Look for logs in server console when users connect

# Test notification creation manually
# In server console or script:
const notificationService = require('./services/notificationService');
await notificationService.createNotification({
  userId: 'USER_ID_HERE',
  type: 'test',
  title: 'Test Notification',
  body: 'This is a test',
  data: {},
  priority: 'high'
});
```

## Contact

If issues persist after following this guide:
1. Check server logs for specific error messages
2. Verify database has notifications created
3. Test with different user accounts
4. Ensure mobile app is properly connected to server
