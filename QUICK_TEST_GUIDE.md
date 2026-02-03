# 🧪 Quick Test Guide - Verify All Fixes

## 🎯 What to Test

All critical issues have been fixed. Here's how to verify they work:

---

## Test 1: Schedule Duration Validation ⭐ NEW FIX

### Steps:
1. **Login as tutor**
2. **Go to "My Schedule" tab**
3. **Tap the "+" button** (bottom right)
4. **Select any day** (e.g., Monday)
5. **Select start time**: 09:00
6. **Select end time**: 09:10 (only 10 minutes)

### Expected Result:
- ✅ You should see a **RED warning box** that says:
  ```
  ⚠ Duration: 10 minutes
  Minimum 15 minutes required
  ```
- ✅ If you try to tap "Save", you'll see an error message
- ✅ The slot will NOT be created

### Fix It:
7. **Change end time to**: 09:30 (30 minutes)
8. **You should now see a GREEN box** that says:
   ```
   ✓ Duration: 30 minutes
   ```
9. **Tap "Save"**
10. ✅ Slot should be created successfully!

**Status**: ✅ This fix prevents the error you were seeing before!

---

## Test 2: Tutor Can See Student Bookings ⭐ CRITICAL

### Steps:
1. **Login as student**
2. **Search for a tutor**
3. **Create a booking** for any available time slot
4. **Logout**
5. **Login as that tutor**
6. **Go to "Bookings" tab**
7. **Go to "Pending" sub-tab**

### Expected Result:
- ✅ You should **SEE the booking** from the student!
- ✅ You should see student's name, subject, time, and amount
- ✅ You should see "Accept" and "Decline" buttons

**Before Fix**: Tutor couldn't see any bookings ❌  
**After Fix**: Tutor can see all bookings ✅

---

## Test 3: Escrow System (Money to Pending) ⭐ CRITICAL

### Steps:
1. **Login as tutor**
2. **Go to "Earnings" tab**
3. **Note the current balances**:
   - Pending: $___
   - Available: $___
4. **Accept a booking** (from Test 2)
5. **Logout**
6. **Login as student**
7. **Go to "Bookings" → "Upcoming"**
8. **Pay for the booking**
9. **Logout**
10. **Login as tutor again**
11. **Go to "Earnings" tab**

### Expected Result:
- ✅ **Pending balance should INCREASE** by the booking amount
- ✅ **Available balance should NOT change**
- ✅ Money is held in escrow for 24 hours

**Before Fix**: Money went directly to Available ❌  
**After Fix**: Money goes to Pending (escrow) ✅

---

## Test 4: Start Session Button ⭐ CRITICAL

### Prerequisites:
- You need a **confirmed booking** (status = confirmed, payment = completed)
- Booking should be scheduled for **soon** (within next 10 minutes)

### Steps:
1. **Create a booking** for 10 minutes from now
2. **Pay for it** (so status becomes "confirmed")
3. **Wait 5 minutes**
4. **Go to "Bookings" → "Upcoming"**

### Expected Result:
- ✅ You should see a **"Start Session" button**
- ✅ You should see a **countdown timer** (e.g., "In 5 minutes")
- ✅ Tap the button to start the session
- ✅ You should see the **Active Session Screen** with video call

**Note**: Button only appears 5 minutes before session time!

---

## Test 5: Complete Booking Flow (End-to-End)

### Full Flow:
```
Student:
1. Search tutor ✓
2. View profile ✓
3. Create booking ✓

Tutor:
4. See booking in "Pending" ✓ (Test 2)
5. Accept booking ✓

Student:
6. Pay for booking ✓

Tutor:
7. Money in "Pending" balance ✓ (Test 3)
8. Booking in "Confirmed" tab ✓

Both:
9. Wait 5 minutes before session
10. "Start Session" button appears ✓ (Test 4)
11. Start session ✓
12. Video call works ✓
13. End session ✓

After 24 Hours:
14. Money moves to "Available" ✓
15. Tutor can withdraw ✓
```

---

## 🚨 If Something Doesn't Work

### Issue: Tutor still can't see bookings
**Solution**: 
```bash
cd server
node scripts/fixExistingBookings.js
```
This fixes old bookings in the database.

### Issue: Money still goes to Available (not Pending)
**Check**: 
1. Make sure server is restarted
2. Check `server/services/paymentService.js` line 160
3. Should say: `'add', 'pending'` not `'add', 'available'`

### Issue: Duration validation not working
**Check**:
1. Make sure mobile app is restarted
2. Try creating a new slot
3. Should see the duration indicator

### Issue: Start Session button not appearing
**Check**:
1. Booking status must be "confirmed"
2. Payment status must be "completed"
3. Must be within 5 minutes of session time
4. Try refreshing the bookings screen

---

## ✅ Quick Verification Checklist

After testing, you should be able to say:

- [ ] ✅ I can create availability slots (≥15 minutes only)
- [ ] ✅ I see duration validation with green/red indicators
- [ ] ✅ Tutors can see student bookings in "Pending" tab
- [ ] ✅ When student pays, money goes to tutor's "Pending" balance
- [ ] ✅ "Start Session" button appears 5 min before session
- [ ] ✅ I can start a session and see the video call screen
- [ ] ✅ Complete booking flow works end-to-end

---

## 📊 What Each Fix Does

### Fix 1: Duration Validation
- **Prevents**: Creating time slots less than 15 minutes
- **Shows**: Real-time duration with visual feedback
- **Result**: No more validation errors!

### Fix 2: Booking Visibility
- **Fixes**: tutorId field now references User (not TutorProfile)
- **Result**: Tutors can see all student bookings!

### Fix 3: Escrow System
- **Changes**: Money goes to "Pending" (not "Available")
- **Result**: Proper escrow with 24-hour hold!

### Fix 4: Session Management
- **Adds**: Smart "Start Session" button
- **Shows**: Real-time countdown
- **Result**: Complete session flow works!

---

## 🎯 Priority Testing Order

1. **First**: Test duration validation (Test 1) - Quick & easy
2. **Second**: Test booking visibility (Test 2) - Critical
3. **Third**: Test escrow system (Test 3) - Critical
4. **Fourth**: Test session button (Test 4) - Needs timing
5. **Fifth**: Test complete flow (Test 5) - Full verification

---

## 💡 Tips

### For Testing Duration:
- Try 5 minutes → Should fail ❌
- Try 10 minutes → Should fail ❌
- Try 15 minutes → Should work ✅
- Try 30 minutes → Should work ✅

### For Testing Escrow:
- Check "Pending" balance before payment
- Check "Pending" balance after payment
- Should increase by booking amount
- "Available" should NOT change

### For Testing Session Button:
- Create booking for near future (10 min)
- Pay for it immediately
- Wait 5 minutes
- Refresh bookings screen
- Button should appear

---

## ✅ Success Criteria

**All fixes are working if**:
1. ✅ Can't create slots < 15 minutes
2. ✅ Tutors see student bookings
3. ✅ Money goes to Pending (not Available)
4. ✅ Start Session button appears
5. ✅ Complete flow works end-to-end

---

**Status**: ✅ ALL FIXES APPLIED  
**Ready**: YES - Start testing!  
**Expected**: Everything should work! 🚀

**Need Help?** Check the detailed documentation:
- `SCHEDULE_DURATION_VALIDATION_COMPLETE.md`
- `CRITICAL_FIXES_APPLIED.md`
- `FIXES_COMPLETE_README.md`
