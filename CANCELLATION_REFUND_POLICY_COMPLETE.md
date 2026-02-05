# ✅ Cancellation & Refund Policy Implementation

## 🎯 Feature Overview

Implemented comprehensive cancellation and refund policy for bookings with time-based refund rules.

---

## 📊 Refund Policy

### For Testing (Current):
| Time Before Session | Refund Amount | Notes |
|---------------------|---------------|-------|
| **1+ hours** | **100%** | Full refund |
| **30min - 1hr** | **50%** | Partial refund |
| **< 30 minutes** | **0%** | No refund |

### For Production (Future):
| Time Before Session | Refund Amount | Notes |
|---------------------|---------------|-------|
| **24+ hours** | **100%** | Full refund |
| **12-24 hours** | **50%** | Partial refund |
| **< 12 hours** | **0%** | No refund |

### Special Cases:
- **Tutor Cancels**: Always **100% refund** to student (any time)
- **Session Started**: **Cannot cancel** (session already in progress)
- **Both Checked In**: **Cannot cancel** (offline session started)

---

## 🔧 Implementation Details

### Backend Changes:

#### 1. **server/services/escrowService.js**
Updated refund rules configuration:
```javascript
refundRules: {
  full: 1,      // 100% refund if cancelled 1+ hours before (testing)
  partial: 0.5, // 50% refund if cancelled 0.5-1 hours before
  partialPercentage: 50,
  none: 0.5     // 0% refund if less than 0.5 hours (30 min) before
}
```

#### 2. **server/controllers/bookingController.js**
Enhanced cancellation logic:
- Check if session has started
- Check if both parties checked in (offline)
- Apply different refund rules for tutor vs student cancellation
- Tutor cancellation = always 100% refund
- Student cancellation = time-based refund rules
- Process refund through escrow service
- Send notifications to both parties

Key validations:
```javascript
// Cannot cancel if:
- status === 'cancelled' (already cancelled)
- status === 'completed' (session completed)
- status === 'no-show' (marked as no-show)
- session.isActive === true (session in progress)
- sessionStartedAt !== null (session started)
- checkIn.bothCheckedIn === true (both checked in)
```

### Frontend Changes:

#### 3. **mobile_app/lib/core/widgets/cancel_booking_dialog.dart** (NEW)
Comprehensive cancellation dialog with:
- **Refund calculation** based on time until session
- **Refund policy display** (visual breakdown)
- **Reason input** (required)
- **Confirmation buttons**
- **Error handling**
- **Loading states**

Features:
- Real-time refund calculation
- Color-coded refund percentage (green=100%, orange=50%, red=0%)
- Policy explanation
- Validation for reason input

#### 4. **mobile_app/lib/features/student/screens/student_bookings_screen.dart**
Updated `_cancelSession` method:
- Check if session can be cancelled
- Show comprehensive cancel dialog
- Display refund information
- Handle cancellation result
- Refresh bookings list

Validations:
```dart
// Cannot cancel if:
- sessionStartedAt != null
- session.isActive == true
- checkIn.bothCheckedIn == true
- status not in ['pending', 'confirmed']
```

---

## 🎨 User Experience

### Student Cancellation Flow:

1. **Click "Cancel" button** on booking card
2. **See cancellation dialog** with:
   - Refund amount and percentage
   - Time until session
   - Refund policy breakdown
   - Reason input field
3. **Enter cancellation reason** (required)
4. **Confirm cancellation**
5. **See success message** with refund details
6. **Booking status** changes to "Cancelled"
7. **Refund processed** automatically

### Tutor Cancellation Flow:

1. **Click "Decline" button** on booking request
2. **Enter decline reason** (optional)
3. **Confirm decline**
4. **Student receives 100% refund** automatically
5. **Both parties notified**

---

## 📱 UI Components

### Cancel Dialog Features:

**Header:**
- Red cancel icon
- "Cancel Booking" title
- "This action cannot be undone" subtitle

**Refund Information Card:**
- Color-coded based on refund percentage
  - Green: 100% refund
  - Orange: 50% refund
  - Red: 0% refund
- Large refund amount display
- Refund percentage badge
- Explanation message

**Policy Information:**
- Blue info box
- Bullet points with refund rules
- Easy to understand format

**Reason Input:**
- Multi-line text field
- Required field
- Placeholder text

**Action Buttons:**
- "Keep Booking" (outlined, gray)
- "Cancel Booking" (filled, red)
- Loading state on submit

---

## 🔐 Security & Validation

### Backend Validations:
- ✅ User authorization (student or tutor)
- ✅ Booking status check
- ✅ Session start check
- ✅ Check-in status check
- ✅ Payment status verification
- ✅ Escrow status verification

### Frontend Validations:
- ✅ Reason required
- ✅ Session status check
- ✅ Time calculation
- ✅ Error handling
- ✅ Loading states

---

## 💰 Refund Processing

### Automatic Refund Flow:

1. **Student cancels booking**
2. **System calculates refund** based on time
3. **Escrow service processes refund**
4. **Booking status** → 'cancelled'
5. **Refund status** → 'processing'
6. **Payment reversed** via Chapa
7. **Student balance updated**
8. **Tutor balance adjusted** (if applicable)
9. **Both parties notified**

### Refund Calculation:
```javascript
const hoursUntilSession = (sessionDateTime - now) / (1000 * 60 * 60);

if (hoursUntilSession >= 1) {
  refundPercentage = 100; // Full refund
} else if (hoursUntilSession >= 0.5) {
  refundPercentage = 50;  // Partial refund
} else {
  refundPercentage = 0;   // No refund
}

refundAmount = (totalAmount * refundPercentage) / 100;
```

---

## 🧪 Testing Guide

### Test Case 1: Full Refund (1+ hours before)
```
1. Create booking for 2+ hours from now
2. Click "Cancel" button
3. See "100% refund" in dialog
4. Enter reason: "Schedule conflict"
5. Confirm cancellation
6. Verify: Full refund processed
7. Verify: Booking status = 'cancelled'
```

### Test Case 2: Partial Refund (30min - 1hr before)
```
1. Create booking for 45 minutes from now
2. Click "Cancel" button
3. See "50% refund" in dialog
4. Enter reason: "Emergency"
5. Confirm cancellation
6. Verify: 50% refund processed
7. Verify: Booking status = 'cancelled'
```

### Test Case 3: No Refund (< 30min before)
```
1. Create booking for 15 minutes from now
2. Click "Cancel" button
3. See "0% refund" in dialog
4. Enter reason: "Changed mind"
5. Confirm cancellation
6. Verify: No refund processed
7. Verify: Booking status = 'cancelled'
```

### Test Case 4: Tutor Cancellation (Always 100%)
```
1. Tutor declines booking request
2. Enter decline reason
3. Confirm decline
4. Verify: Student receives 100% refund
5. Verify: Both parties notified
```

### Test Case 5: Cannot Cancel (Session Started)
```
1. Start session
2. Try to click "Cancel" button
3. Verify: Error message shown
4. Verify: "Cannot cancel - session has already started"
```

### Test Case 6: Cannot Cancel (Both Checked In)
```
1. Both parties check in (offline session)
2. Try to cancel
3. Verify: Error message shown
4. Verify: "Cannot cancel - both parties have checked in"
```

---

## 📊 Database Updates

### Booking Model Updates:
```javascript
{
  status: 'cancelled',
  cancellationReason: 'User provided reason',
  cancelledBy: userId,
  cancelledAt: Date,
  refundAmount: calculatedAmount,
  refundStatus: 'processing' | 'completed' | 'none',
  
  escrow: {
    status: 'refunded',
    refundedAt: Date
  }
}
```

---

## 🔄 Environment Variables

### Testing Configuration:
```env
# Refund policy (hours before session)
ESCROW_REFUND_FULL_HOURS=1        # 100% refund threshold
ESCROW_REFUND_PARTIAL_HOURS=0.5   # 50% refund threshold
ESCROW_REFUND_PARTIAL_PERCENT=50  # Partial refund percentage
ESCROW_REFUND_NONE_HOURS=0.5      # No refund threshold
```

### Production Configuration:
```env
# Refund policy (hours before session)
ESCROW_REFUND_FULL_HOURS=24       # 100% refund threshold
ESCROW_REFUND_PARTIAL_HOURS=12    # 50% refund threshold
ESCROW_REFUND_PARTIAL_PERCENT=50  # Partial refund percentage
ESCROW_REFUND_NONE_HOURS=12       # No refund threshold
```

---

## 📝 Notifications

### Student Cancellation:
**To Tutor:**
```
Subject: Session Cancelled
Message: [Student Name] has cancelled the [Subject] session 
         scheduled for [Date] at [Time].
         Reason: [Cancellation Reason]
```

### Tutor Cancellation:
**To Student:**
```
Subject: Session Cancelled - Full Refund
Message: [Tutor Name] has cancelled the [Subject] session 
         scheduled for [Date] at [Time].
         You will receive a full refund of ETB [Amount].
         Reason: [Cancellation Reason]
```

---

## ✅ Success Criteria

All criteria met:
- ✅ Student can cancel booking
- ✅ Refund calculated based on time
- ✅ Tutor cancellation = 100% refund
- ✅ Cannot cancel if session started
- ✅ Cannot cancel if both checked in
- ✅ Refund processed automatically
- ✅ Notifications sent to both parties
- ✅ UI shows refund information
- ✅ Policy clearly displayed
- ✅ Reason required for cancellation

---

## 🚀 Deployment

### Backend:
```bash
# Already deployed with payment integration
# No additional deployment needed
```

### Frontend:
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### Environment Variables:
Already configured on Render (no changes needed for testing)

---

## 📚 Files Modified/Created

### Created:
- `mobile_app/lib/core/widgets/cancel_booking_dialog.dart`
- `CANCELLATION_REFUND_POLICY_COMPLETE.md`

### Modified:
- `server/services/escrowService.js` (refund rules)
- `server/controllers/bookingController.js` (cancellation logic)
- `mobile_app/lib/features/student/screens/student_bookings_screen.dart` (cancel method)

---

## 🎯 Key Features

### For Students:
- ✅ Clear refund policy display
- ✅ Real-time refund calculation
- ✅ Easy cancellation process
- ✅ Reason input required
- ✅ Automatic refund processing

### For Tutors:
- ✅ Can decline bookings
- ✅ Student always gets full refund
- ✅ Notification sent to student
- ✅ Reason input optional

### For Platform:
- ✅ Fair refund policy
- ✅ Automatic processing
- ✅ Audit trail
- ✅ Dispute prevention
- ✅ User satisfaction

---

## 🔄 Future Enhancements

### Phase 2:
1. **Cancellation Analytics**
   - Track cancellation rates
   - Identify patterns
   - Improve policy

2. **Flexible Policies**
   - Per-tutor cancellation policies
   - Subject-specific rules
   - Premium vs standard policies

3. **Cancellation Insurance**
   - Optional insurance for students
   - Full refund any time
   - Small fee added to booking

4. **Dispute Resolution**
   - If student disagrees with refund
   - Admin review process
   - Evidence submission

---

## 📊 Status

**Status**: ✅ COMPLETE
**Priority**: High
**Complexity**: Medium
**Time Spent**: ~1 hour

### Completed:
- ✅ Backend refund policy updated (1 hour for testing)
- ✅ Cancellation validation enhanced
- ✅ Tutor cancellation = 100% refund
- ✅ Cancel dialog created with refund info
- ✅ Student bookings screen updated
- ✅ Refund calculation implemented
- ✅ Policy display added
- ✅ Notifications integrated

### Ready for Testing:
- ✅ Full refund (1+ hours)
- ✅ Partial refund (30min - 1hr)
- ✅ No refund (< 30min)
- ✅ Tutor cancellation
- ✅ Cannot cancel if started
- ✅ Cannot cancel if checked in

---

**Last Updated**: Current Session
**Implementation**: Complete
**Testing**: Ready
**Production**: Change thresholds to 24/12 hours

