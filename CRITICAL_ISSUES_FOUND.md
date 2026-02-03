# 🚨 Critical Issues Found & Fixes Needed

## Issues Discovered

### 1. ❌ Escrow System Not Working
**Problem**: Payment goes directly to tutor's available balance instead of escrow

**Current Code** (server/services/paymentService.js line 155):
```javascript
// Update tutor balance
await this.updateTutorBalance(tutorProfileId, fees.tutorShare, 'add', 'available');
```

**Fix Applied**: Changed to add to 'pending' balance:
```javascript
// Update tutor balance - ADD TO PENDING, NOT AVAILABLE!
await this.updateTutorBalance(tutorProfileId, fees.tutorShare, 'add', 'pending');
```

**Status**: ✅ FIXED

---

### 2. ❌ Tutor Not Seeing Student Bookings
**Problem**: Booking model uses `tutorId` field but stores TutorProfile ID instead of User ID

**Root Cause**:
- Booking creation stores TutorProfile._id in `tutorId` field
- Query filters by User ID: `{ tutorId: req.user.userId }`
- Mismatch causes tutors not to see bookings

**Solution Needed**: 
1. Add separate `tutorProfileId` field to Booking model
2. Keep `tutorId` for User ID
3. Update booking creation to set both fields
4. Update queries to use correct field

---

### 3. ❌ Start Session Button Not Showing
**Problem**: SessionActionButton exists but bookings don't have proper session data

**Requirements for Button to Show**:
1. Booking status must be 'confirmed'
2. Payment status must be 'completed'
3. Current time must be within 5 minutes before session time
4. Session date/time must be properly formatted

**Current Issue**: Bookings created don't have all required fields

---

## 🔧 Fixes Needed

### Fix 1: Update Booking Model Schema

**File**: `server/models/Booking.js`

Add `tutorProfileId` field:
```javascript
{
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tutorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // User ID
  tutorProfileId: { type: mongoose.Schema.Types.ObjectId, ref: 'TutorProfile', required: true }, // Profile ID
  // ... rest of fields
}
```

### Fix 2: Update Booking Creation

**File**: `server/routes/bookings.js` (line ~200)

```javascript
const bookingData = {
  studentId: req.user.userId,
  tutorId: tutorProfile.userId, // ← User ID
  tutorProfileId: tutorProfile._id, // ← Profile ID
  // ... rest of fields
};
```

### Fix 3: Update Booking Queries

**File**: `server/routes/bookings.js` (line ~40)

```javascript
const filter = {
  $or: [
    { studentId: req.user.userId },
    { tutorId: req.user.userId } // ← This will now work!
  ]
};
```

### Fix 4: Ensure Proper Session Data

When creating bookings, ensure:
```javascript
{
  sessionDate: new Date(date), // ← Must be valid Date
  startTime: '14:00', // ← Must be HH:MM format
  endTime: '15:00', // ← Must be HH:MM format
  status: 'pending', // ← Will become 'confirmed' after payment
  paymentStatus: 'pending', // ← Will become 'completed' after payment
}
```

---

## 📋 Testing Checklist

After fixes:

### Test 1: Booking Creation
- [ ] Student creates booking
- [ ] Booking appears in student's "Upcoming" tab
- [ ] Booking appears in tutor's "Pending" tab ← **Currently broken**

### Test 2: Payment & Escrow
- [ ] Student pays for booking
- [ ] Money goes to tutor's PENDING balance (not available) ← **Fixed**
- [ ] Booking status changes to 'confirmed'
- [ ] Payment status changes to 'completed'

### Test 3: Start Session Button
- [ ] Button appears 5 minutes before session time
- [ ] Button shows countdown
- [ ] Tapping button navigates to active session screen

### Test 4: Session Completion
- [ ] Session ends
- [ ] Escrow release scheduled for +24 hours
- [ ] After 24 hours, money moves to available balance
- [ ] Tutor receives notification

---

## 🎯 Priority Fixes

### HIGH PRIORITY:
1. ✅ Fix escrow (money to pending, not available) - **DONE**
2. ⚠️ Fix tutor not seeing bookings (tutorId mismatch) - **NEEDS FIX**
3. ⚠️ Ensure session data is properly formatted - **NEEDS VERIFICATION**

### MEDIUM PRIORITY:
4. Test Start Session button with real data
5. Test escrow release after 24 hours
6. Test complete booking flow end-to-end

---

## 🔍 How to Verify Issues

### Check if Tutor Sees Bookings:
```javascript
// In MongoDB
db.bookings.find({ tutorId: ObjectId("tutor_user_id") })
// Should return bookings, but currently returns empty

db.bookings.find({ tutorId: ObjectId("tutor_profile_id") })
// Currently returns bookings (wrong!)
```

### Check Escrow Status:
```javascript
// After payment
db.bookings.findOne({ _id: ObjectId("booking_id") })
// Check: escrow.status should be 'held'

db.tutorprofiles.findOne({ _id: ObjectId("tutor_profile_id") })
// Check: balance.pending should increase (not balance.available)
```

---

## 📝 Next Steps

1. Apply Fix 1: Update Booking model
2. Apply Fix 2: Update booking creation
3. Apply Fix 3: Verify queries work
4. Test complete flow
5. Verify Start Session button appears

---

**Status**: Escrow fixed, booking visibility needs fix
**Priority**: HIGH - Tutors can't see bookings!
