# 🚀 Quick Test: Cancellation & Refund Policy

## ⚡ 5-Minute Test

### Prerequisites:
- ✅ Backend deployed
- ✅ Mobile app rebuilt
- ✅ Test booking created

---

## 📱 Test Scenarios

### Scenario 1: Full Refund (1+ hours before) ⏰

**Steps:**
```
1. Create booking for 2+ hours from now
2. Go to "My Bookings"
3. Find the booking
4. Click "Cancel" button
5. See cancellation dialog
```

**Expected Dialog:**
- ✅ Refund: 100% (green)
- ✅ Amount: Full booking amount
- ✅ Message: "Full refund (cancelled Xh before session)"
- ✅ Policy displayed

**Complete Cancellation:**
```
6. Enter reason: "Schedule conflict"
7. Click "Cancel Booking"
8. See success message
9. Booking status → "Cancelled"
10. Refund processed
```

---

### Scenario 2: Partial Refund (30min - 1hr before) ⏰

**Steps:**
```
1. Create booking for 45 minutes from now
2. Go to "My Bookings"
3. Click "Cancel" button
```

**Expected Dialog:**
- ✅ Refund: 50% (orange)
- ✅ Amount: Half booking amount
- ✅ Message: "Partial refund (cancelled Xmin before session)"

**Complete:**
```
4. Enter reason: "Emergency"
5. Confirm cancellation
6. See 50% refund message
```

---

### Scenario 3: No Refund (< 30min before) ⏰

**Steps:**
```
1. Create booking for 15 minutes from now
2. Try to cancel
```

**Expected Dialog:**
- ✅ Refund: 0% (red)
- ✅ Amount: ETB 0.00
- ✅ Message: "No refund (less than 30 minutes before session)"

**Complete:**
```
3. Enter reason: "Changed mind"
4. Confirm cancellation
5. See no refund message
```

---

### Scenario 4: Tutor Cancellation (Always 100%) 👨‍🏫

**As Tutor:**
```
1. Login as tutor
2. Go to "My Bookings"
3. Find pending booking
4. Click "Decline"
5. Enter reason (optional)
6. Confirm decline
```

**Expected Result:**
- ✅ Student receives 100% refund
- ✅ Both parties notified
- ✅ Booking status → "Cancelled"

---

### Scenario 5: Cannot Cancel (Session Started) ❌

**Steps:**
```
1. Start a session
2. Try to click "Cancel" button
```

**Expected Result:**
- ✅ Error message shown
- ✅ "Cannot cancel - session has already started"
- ✅ Cancel button disabled or hidden

---

### Scenario 6: Cannot Cancel (Both Checked In) ❌

**For Offline Sessions:**
```
1. Both parties check in
2. Try to cancel
```

**Expected Result:**
- ✅ Error message shown
- ✅ "Cannot cancel - both parties have checked in"

---

## 🎯 Quick Checks

### Visual Checks:
- [ ] Cancel button visible on upcoming bookings
- [ ] Cancel button NOT visible on completed bookings
- [ ] Refund percentage color-coded (green/orange/red)
- [ ] Policy information displayed
- [ ] Reason input required

### Functional Checks:
- [ ] Refund calculated correctly
- [ ] Time until session accurate
- [ ] Cancellation reason required
- [ ] Success message shown
- [ ] Booking list refreshed
- [ ] Notifications sent

### Backend Checks:
- [ ] Booking status updated to 'cancelled'
- [ ] Refund amount calculated correctly
- [ ] Escrow refunded
- [ ] Availability slot released
- [ ] Both parties notified

---

## 📊 Test Data

### Test Booking 1 (Full Refund):
```
Session Time: 2 hours from now
Amount: ETB 100
Expected Refund: ETB 100 (100%)
```

### Test Booking 2 (Partial Refund):
```
Session Time: 45 minutes from now
Amount: ETB 100
Expected Refund: ETB 50 (50%)
```

### Test Booking 3 (No Refund):
```
Session Time: 15 minutes from now
Amount: ETB 100
Expected Refund: ETB 0 (0%)
```

---

## 🔍 Backend Verification

### Check Booking in Database:
```javascript
db.bookings.findOne({ _id: bookingId })

// Should see:
{
  status: 'cancelled',
  cancellationReason: 'User provided reason',
  cancelledBy: userId,
  cancelledAt: Date,
  refundAmount: calculatedAmount,
  refundStatus: 'processing',
  escrow: {
    status: 'refunded'
  }
}
```

### Check Logs:
```
Look for:
- "Student cancellation - refund calculation: ..."
- "Tutor cancellation - full refund: ..."
- "✅ Refund processed: ..."
```

---

## ❌ Common Issues

### Issue 1: Cancel Button Not Showing
**Cause:** Booking status not 'pending' or 'confirmed'
**Fix:** Check booking status

### Issue 2: Wrong Refund Amount
**Cause:** Time calculation incorrect
**Fix:** Check system time and session time

### Issue 3: Cannot Cancel Error
**Cause:** Session already started
**Fix:** Verify session status

### Issue 4: Refund Not Processed
**Cause:** Payment not completed
**Fix:** Check payment status

---

## 🎉 Success Indicators

All green:
- ✅ Cancel dialog shows correct refund
- ✅ Policy displayed clearly
- ✅ Reason required and validated
- ✅ Cancellation processed successfully
- ✅ Refund calculated correctly
- ✅ Booking status updated
- ✅ Notifications sent
- ✅ UI refreshed

---

## 📝 Notes

### Testing Configuration:
- Full refund: 1+ hours before
- Partial refund: 30min - 1hr before
- No refund: < 30min before

### Production Configuration:
- Full refund: 24+ hours before
- Partial refund: 12-24 hours before
- No refund: < 12 hours before

**To change:** Update environment variables on Render

---

**Time Required:** 10 minutes
**Difficulty:** Easy
**Prerequisites:** Booking created, app running

