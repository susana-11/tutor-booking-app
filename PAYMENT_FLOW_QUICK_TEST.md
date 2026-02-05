# 🚀 Quick Test Guide: Chapa Payment Flow

## ⚡ 5-Minute Test

### Prerequisites:
- ✅ Backend deployed to Render
- ✅ Mobile app rebuilt with new changes
- ✅ Test accounts ready (student + tutor)

---

## 📱 Test Steps

### 1. Create Booking (2 min)

**As Student:**
```
1. Login to mobile app
2. Tap "Find Tutors"
3. Select any tutor
4. Tap "Book Session"
5. Select available time slot
6. Choose session type:
   - Online (video session)
   - Offline (in-person)
7. Select duration:
   - 1 hour
   - 1.5 hours
   - 2 hours
8. Add notes (optional)
9. Tap "Confirm Booking"
```

**Expected Result:**
- ✅ Redirected to Payment Screen
- ✅ See booking summary
- ✅ See total amount

---

### 2. Complete Payment (1 min)

**On Payment Screen:**
```
1. Review booking details
2. Check total amount
3. Tap "Pay with Chapa"
4. Complete payment on Chapa checkout
   (Use test card if in test mode)
5. Wait for verification
```

**Expected Result:**
- ✅ Payment successful dialog
- ✅ "View Bookings" button appears

---

### 3. Verify Booking (1 min)

**Check Booking Status:**
```
1. Tap "View Bookings"
2. Find your booking
3. Check status: "Confirmed"
4. Check payment: "Paid"
```

**As Tutor:**
```
1. Login to tutor account
2. Go to "My Bookings"
3. See new confirmed booking
4. Check payment status: "Paid"
```

**Expected Result:**
- ✅ Booking status: Confirmed
- ✅ Payment status: Paid
- ✅ Both parties can see booking

---

### 4. Complete Session (1 min)

**Simulate Session Completion:**

**Option A: Online Session**
```
1. Wait for session time (or use test mode)
2. Start session
3. End session
```

**Option B: Offline Session**
```
1. Both parties check in
2. Session auto-starts
3. Both parties check out
4. Session auto-completes
```

**Expected Result:**
- ✅ Booking status: Completed
- ✅ Escrow release scheduled (10 min)

---

### 5. Verify Payment Release (10 min)

**Wait 10 Minutes:**
```
1. Wait for 10 minutes
2. Check tutor balance
3. Check escrow status
```

**Expected Result:**
- ✅ Escrow status: Released
- ✅ Tutor balance increased
- ✅ Notifications sent

---

## 🧪 Quick Checks

### Backend Logs (Render):
```
Look for these messages:
- "🔒 Payment held in escrow for booking..."
- "📅 Escrow release scheduled for..."
- "💰 Releasing escrow for booking..."
- "✅ Escrow released successfully"
```

### Database Checks:
```javascript
// Check booking
db.bookings.findOne({ _id: bookingId })

// Should see:
{
  status: 'confirmed',
  payment: {
    status: 'paid',
    chapaReference: 'TX-...'
  },
  escrow: {
    status: 'held',
    releaseScheduledFor: Date (10 min from completion)
  }
}

// After 10 minutes:
{
  escrow: {
    status: 'released',
    releasedAt: Date
  }
}
```

---

## ❌ Common Issues

### Issue 1: Payment Screen Not Showing
**Cause:** Booking creation failed
**Fix:** Check backend logs for errors

### Issue 2: Payment Verification Failed
**Cause:** Chapa webhook not received
**Fix:** Check Chapa dashboard for webhook status

### Issue 3: Escrow Not Released
**Cause:** Scheduler not running
**Fix:** Check backend logs for scheduler errors

### Issue 4: Tutor Balance Not Updated
**Cause:** TutorProfile not found
**Fix:** Check tutorProfileId in booking

---

## 🎯 Success Indicators

### All Green:
- ✅ Booking created with status 'pending'
- ✅ Payment screen shown
- ✅ Payment completed via Chapa
- ✅ Booking status changed to 'confirmed'
- ✅ Escrow status changed to 'held'
- ✅ Session completed
- ✅ Escrow release scheduled (10 min)
- ✅ After 10 min: escrow released
- ✅ Tutor balance updated
- ✅ Notifications sent

---

## 📊 Test Data

### Test Student:
```
Email: student@test.com
Password: Test123!
```

### Test Tutor:
```
Email: tutor@test.com
Password: Test123!
```

### Test Card (Chapa Test Mode):
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date
CVV: Any 3 digits
```

---

## 🔄 Reset Test

To test again:
```
1. Cancel the booking
2. Create new booking
3. Repeat payment flow
```

---

## 📝 Notes

- Dispute window is 10 minutes for testing
- In production, change to 24 hours (1440 minutes)
- Scheduler runs every 5 minutes
- Payment held in escrow, NOT in tutor's available balance
- Automatic release after dispute window

---

**Time Required:** 15 minutes (including 10-min wait)
**Difficulty:** Easy
**Prerequisites:** Backend deployed, app rebuilt

