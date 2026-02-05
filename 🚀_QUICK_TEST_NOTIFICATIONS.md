# 🚀 Quick Test: Cancel & Reschedule Notifications

## ⚡ Quick Start

1. **Restart server:**
   ```bash
   restart-server.bat
   ```

2. **Run test script:**
   ```bash
   test-cancel-reschedule-notifications.bat
   ```

3. **Watch server logs** while testing

## 🧪 Test Scenarios

### Test 1: Student Cancels ❌
1. Login as **student**
2. Go to bookings
3. Cancel a booking
4. **Check:** Tutor receives notification

### Test 2: Tutor Cancels ❌
1. Login as **tutor**
2. Go to bookings
3. Cancel a booking
4. **Check:** Student receives notification

### Test 3: Student Reschedules 🔄
1. Login as **student**
2. Go to bookings
3. Request reschedule
4. **Check:** Tutor receives notification

### Test 4: Tutor Responds 🔄
1. Login as **tutor**
2. Go to bookings
3. Accept/reject reschedule
4. **Check:** Student receives notification

## 📊 What to Look For

### ✅ Success
```
📧 Sending cancellation notification
✅ Notification saved to database
✅ Real-time notification emitted
✅ Cancellation notification sent successfully
```

### ❌ Failure
```
❌ Failed to send cancellation notification
⚠️ Socket.IO not available
⚠️ Firebase credentials not found
```

## 🔍 Quick Debug

If notifications don't work:

1. **Check logs** - Look for ❌ or ⚠️
2. **Run test script** - Verify database has notifications
3. **Check device tokens** - User may need to logout/login
4. **Check Firebase** - Verify FIREBASE_SERVICE_ACCOUNT in .env

## 📚 Full Documentation

- `🔧_NOTIFICATION_FIX_APPLIED.md` - What was fixed
- `NOTIFICATION_DEBUG_GUIDE.md` - Detailed troubleshooting
- `📋_TASK_4_NOTIFICATION_FIX_SUMMARY.md` - Complete summary

## ✨ What Changed

- ✅ Enhanced logging (see exactly what's happening)
- ✅ Better error tracking (know when things fail)
- ✅ Higher priority (cancellations are now "high" priority)
- ✅ Better messages (shows WHO cancelled)
- ✅ Test tools (easy verification)

## 🎯 Expected Result

After testing, you should see:
- Notifications in both directions (student ↔ tutor)
- Clear logs showing notification flow
- Notifications appearing in mobile app
- Push notifications (if app in background)

## 💡 Pro Tip

Keep the server console visible while testing to see the notification flow in real-time!
