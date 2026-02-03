# 🚀 Session Management - Quick Start Guide

## ⚡ Quick Overview

The session management system is now fully implemented! Here's everything you need to know to test it.

---

## 🎯 What It Does

- **Smart Button**: "Start Session" button appears 5 minutes before session time
- **Live Timer**: Countdown timer during session with color warnings
- **Escrow System**: Payment held until 24 hours after session completion
- **Auto-Release**: Cron job automatically releases payment to tutor
- **Notifications**: Real-time updates at each step

---

## 🏃 Quick Test (5 Minutes)

### 1. Start Backend
```bash
cd server
npm start
```

### 2. Start Mobile App
```bash
cd mobile_app
flutter run
```

### 3. Test as Student

1. **Login** as student
2. **Search** for a tutor
3. **Book** a session (set time to 5 minutes from now)
4. **Pay** for the booking
5. **Go to** "My Bookings" tab
6. **Wait** for "Start Session" button to appear (5 min before)
7. **Tap** "Start Session"
8. **Verify** you see:
   - Active Session Screen
   - Timer counting down
   - Tutor information
   - End Session button
9. **End** the session
10. **Verify** completion dialog shows

### 4. Test as Tutor

1. **Login** as tutor
2. **Accept** booking request
3. **Go to** "My Bookings" tab
4. **Wait** for "Start Session" button to appear (5 min before)
5. **Tap** "Start Session"
6. **Verify** you see:
   - Active Session Screen
   - Timer counting down
   - Student information
   - Session notes input
   - End Session button
7. **Add** session notes
8. **End** the session
9. **Verify** completion dialog shows

---

## 💰 Test Escrow Release

### Option A: Wait 24 Hours (Real Test)
```
1. Complete a session
2. Wait 24 hours
3. Check tutor's balance
4. Verify payment received
5. Check notification
```

### Option B: Quick Test (1 Minute)

**Modify Cron Schedule:**

Edit `server/services/escrowService.js`:

```javascript
// Change this line:
cron.schedule('0 * * * *', async () => {

// To this (runs every minute):
cron.schedule('* * * * *', async () => {
```

**Then:**
```
1. Complete a session
2. Wait 1 minute
3. Check tutor's balance
4. Verify payment received
5. Check notification
```

**Remember to change it back after testing!**

---

## 🎨 What You'll See

### Before Session Time
```
My Bookings Screen
├── Upcoming Tab
│   └── Booking Card
│       ├── Tutor Name
│       ├── Subject
│       ├── Date & Time
│       ├── Status: Confirmed
│       └── 🕐 In 2 hours 30 minutes
```

### 5 Minutes Before
```
My Bookings Screen
├── Upcoming Tab
│   └── Booking Card
│       ├── Tutor Name
│       ├── Subject
│       ├── Date & Time
│       ├── Status: Confirmed
│       ├── ┌─────────────────────────┐
│       │   │  ▶  Start Session       │
│       │   └─────────────────────────┘
│       └── 🕐 In 5 minutes
```

### During Session
```
Active Session Screen
├── App Bar
│   ├── Timer: 00:45:30
│   └── Back Button
├── Progress Bar (Green)
├── Other Party Info
│   ├── Avatar
│   ├── Name
│   └── Subject
├── Session Notes (Tutor only)
│   └── Text Input
└── End Session Button
```

### 5 Minutes Warning
```
Active Session Screen
├── Timer: 00:05:00 (Orange)
├── Progress Bar (Orange)
├── ⚠️ 5 minutes remaining!
└── ...
```

### 1 Minute Warning
```
Active Session Screen
├── Timer: 00:01:00 (Red)
├── Progress Bar (Red)
├── ⚠️ 1 minute remaining!
└── ...
```

### Session Completed
```
Completion Dialog
├── ✅ Session Completed!
├── Payment will be released to
│   tutor in 24 hours
├── Rate your experience?
└── [Rate Session] [Later]
```

---

## 🔍 Key Files

### Backend:
- `server/controllers/sessionController.js` - Session endpoints
- `server/services/escrowService.js` - Escrow automation
- `server/models/Booking.js` - Session & escrow fields

### Mobile:
- `mobile_app/lib/core/services/session_service.dart` - API calls
- `mobile_app/lib/core/widgets/session_action_button.dart` - Smart button
- `mobile_app/lib/core/widgets/session_timer.dart` - Timer widget
- `mobile_app/lib/features/session/screens/active_session_screen.dart` - Session screen
- `mobile_app/lib/features/student/screens/student_bookings_screen.dart` - Student UI
- `mobile_app/lib/features/tutor/screens/tutor_bookings_screen.dart` - Tutor UI

---

## 🐛 Troubleshooting

### "Start Session" button not appearing?
- Check booking status is "confirmed"
- Check payment status is "completed"
- Check current time is within 5 minutes of session time
- Check session date/time format is correct

### Session screen not loading?
- Check backend is running
- Check session endpoint returns data
- Check Agora token generation works
- Check console for errors

### Payment not releasing?
- Check cron job is running (check server logs)
- Check 24 hours have passed since session ended
- Check escrow status in database
- Check tutor balance before/after

### Timer not counting down?
- Check session duration is set correctly
- Check timer widget is receiving correct data
- Check console for errors

---

## 📊 Database Check

### Check Booking Status:
```javascript
// In MongoDB
db.bookings.findOne({ _id: "booking_id" })

// Should see:
{
  status: "completed",
  session: {
    isActive: false,
    startedAt: Date,
    endedAt: Date,
    duration: Number
  },
  escrow: {
    status: "held", // or "released"
    heldAt: Date,
    releaseScheduledAt: Date,
    amount: Number
  }
}
```

### Check Tutor Balance:
```javascript
// In MongoDB
db.tutorprofiles.findOne({ userId: "tutor_id" })

// Should see:
{
  earnings: {
    totalEarned: Number, // Should increase after release
    availableBalance: Number, // Should increase after release
    pendingBalance: Number // Should decrease after release
  }
}
```

---

## ✅ Success Indicators

### Session Started Successfully:
- ✅ Navigate to Active Session Screen
- ✅ Timer displays and counts down
- ✅ Progress bar updates
- ✅ Other party info shows
- ✅ No errors in console

### Session Ended Successfully:
- ✅ Completion dialog shows
- ✅ Booking status changes to "completed"
- ✅ Escrow status changes to "held"
- ✅ Release scheduled for +24 hours
- ✅ Notifications sent

### Payment Released Successfully:
- ✅ Escrow status changes to "released"
- ✅ Tutor balance increases
- ✅ Transaction recorded
- ✅ Notification sent to tutor
- ✅ Cron job logs show success

---

## 🎉 You're Ready!

The system is fully implemented and ready for testing. Follow the quick test steps above to verify everything works correctly.

### Need Help?

Check these files for detailed information:
- `SESSION_MANAGEMENT_IMPLEMENTATION_COMPLETE.md` - Complete implementation details
- `SESSION_UI_IMPLEMENTATION_GUIDE.md` - UI implementation guide
- `REAL_WORLD_TUTOR_APP_COMPARISON.md` - How it compares to real apps

---

**Happy Testing! 🚀**
