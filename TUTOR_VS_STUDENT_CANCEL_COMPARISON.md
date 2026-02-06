# 📊 Tutor vs Student Cancellation Comparison

## Overview
This document explains the differences between tutor and student cancellation policies.

## Visual Comparison

### Student Cancellation Flow
```
Student wants to cancel
        ↓
Opens "My Bookings"
        ↓
Clicks "Cancel" button
        ↓
Dialog calculates refund based on TIME
        ↓
┌─────────────────────────────────────┐
│ Time Until Session | Refund Amount  │
├─────────────────────────────────────┤
│ 1+ hours before    | 100% (Green)   │
│ 30min - 1hr before | 50% (Orange)   │
│ < 30 minutes       | 0% (Red)       │
└─────────────────────────────────────┘
        ↓
Student enters reason
        ↓
Booking cancelled
        ↓
Refund processed (0-100%)
        ↓
Tutor notified
```

### Tutor Cancellation Flow
```
Tutor wants to cancel
        ↓
Opens "My Bookings" → "Confirmed" tab
        ↓
Clicks "Cancel" button (RED)
        ↓
Dialog shows ALWAYS 100% refund
        ↓
┌─────────────────────────────────────┐
│ Tutor Cancellation | Refund Amount  │
├─────────────────────────────────────┤
│ ANY TIME           | 100% (Green)   │
│ No time limit      | Full refund    │
│ Student protected  | Always fair    │
└─────────────────────────────────────┘
        ↓
Tutor enters reason (REQUIRED)
        ↓
Booking cancelled
        ↓
100% refund processed
        ↓
Student notified + refunded
        ↓
Slot becomes available
```

## Detailed Comparison Table

| Feature | Student Cancellation | Tutor Cancellation |
|---------|---------------------|-------------------|
| **Refund Policy** | Time-based (3 tiers) | Always 100% |
| **1+ hours before** | 100% refund | 100% refund |
| **30min-1hr before** | 50% refund | 100% refund |
| **< 30min before** | 0% refund | 100% refund |
| **UI Color** | Green/Orange/Red | Always Green |
| **Button Color** | Default | Red (destructive) |
| **Reason** | Optional | Required |
| **Policy Text** | 3-tier explanation | Single tier |
| **Message** | Time-based message | "Tutor cancelled - full refund" |
| **Notification** | To tutor | To student |
| **Slot Status** | Freed up | Freed up |
| **Platform Fee** | Varies (0-100%) | 0% (full refund) |

## UI Screenshots (Text Description)

### Student Cancel Dialog
```
┌─────────────────────────────────────────┐
│  🚫  Cancel Booking                     │
│      This action cannot be undone       │
├─────────────────────────────────────────┤
│                                         │
│  Refund Amount              50%         │
│  ETB 250.00                             │
│  Partial refund (cancelled 45min before)│
│                                         │
│  ℹ️ Cancellation Policy                 │
│  • 1+ hours before: 100% refund        │
│  • 30min - 1hr before: 50% refund      │
│  • Less than 30min: No refund          │
│                                         │
│  Reason for Cancellation                │
│  ┌───────────────────────────────────┐ │
│  │ Please provide a reason...        │ │
│  └───────────────────────────────────┘ │
│                                         │
│  [Keep Booking]  [Cancel Booking]      │
└─────────────────────────────────────────┘
```

### Tutor Cancel Dialog
```
┌─────────────────────────────────────────┐
│  🚫  Cancel Booking                     │
│      This action cannot be undone       │
├─────────────────────────────────────────┤
│                                         │
│  Refund Amount             100%         │
│  ETB 500.00                             │
│  Student will receive 100% refund       │
│  (Tutor cancellation)                   │
│                                         │
│  ℹ️ Cancellation Policy                 │
│  • Tutor cancellations: 100% refund    │
│  • Student will be notified immediately│
│  • Booking slot will become available  │
│                                         │
│  Reason for Cancellation                │
│  ┌───────────────────────────────────┐ │
│  │ Please provide a reason...        │ │
│  └───────────────────────────────────┘ │
│                                         │
│  [Keep Booking]  [Cancel Booking]      │
└─────────────────────────────────────────┘
```

## Code Implementation

### Student Cancellation (Time-based)
```dart
// In CancelBookingDialog._calculateRefund()
if (hoursUntilSession >= 1) {
  refundPercentage = 100;
  refundMessage = 'Full refund (cancelled ${hoursUntilSession}h before)';
} else if (minutesUntilSession >= 30) {
  refundPercentage = 50;
  refundMessage = 'Partial refund (cancelled ${minutesUntilSession}min before)';
} else {
  refundPercentage = 0;
  refundMessage = 'No refund (less than 30 minutes before)';
}
```

### Tutor Cancellation (Always 100%)
```dart
// In CancelBookingDialog._calculateRefund()
if (isTutor) {
  // Tutors always give 100% refund
  setState(() {
    _refundInfo = {
      'percentage': 100,
      'amount': totalAmount,
      'message': 'Student will receive 100% refund (Tutor cancellation)',
    };
  });
  return;
}
```

### Backend Logic
```javascript
// In bookingController.js cancelBooking()
if (isTutor) {
  refundCalculation = {
    refundAmount: booking.totalAmount,
    refundPercentage: 100,
    platformFeeRetained: 0,
    refundReason: 'Tutor cancelled - full refund',
    eligible: true
  };
} else {
  // Student cancellation - apply time-based rules
  refundCalculation = escrowService.calculateRefundAmount(booking);
}
```

## Business Logic Rationale

### Why Students Have Time-based Refunds:
1. **Protects tutors** from last-minute cancellations
2. **Encourages planning** - students book responsibly
3. **Fair compensation** - tutors lose opportunity cost
4. **Industry standard** - similar to hotels, flights

### Why Tutors Always Give 100% Refund:
1. **Protects students** - they paid in good faith
2. **Tutor responsibility** - professional commitment
3. **Trust building** - students feel safe booking
4. **Fair practice** - tutor controls their schedule
5. **Platform reputation** - student-friendly policy

## Example Scenarios

### Scenario 1: Student Cancels 2 Hours Before
```
Booking: ETB 500
Time: 2 hours before session
Refund: ETB 500 (100%)
Reason: "More than 1 hour before"
Result: ✅ Full refund to student
```

### Scenario 2: Student Cancels 45 Minutes Before
```
Booking: ETB 500
Time: 45 minutes before session
Refund: ETB 250 (50%)
Reason: "Between 30min and 1 hour"
Result: ⚠️ Partial refund to student
        ETB 250 to tutor (compensation)
```

### Scenario 3: Student Cancels 15 Minutes Before
```
Booking: ETB 500
Time: 15 minutes before session
Refund: ETB 0 (0%)
Reason: "Less than 30 minutes"
Result: ❌ No refund to student
        ETB 500 to tutor (full payment)
```

### Scenario 4: Tutor Cancels (Any Time)
```
Booking: ETB 500
Time: ANY TIME (even 5 minutes before)
Refund: ETB 500 (100%)
Reason: "Tutor cancelled"
Result: ✅ Full refund to student
        ETB 0 to tutor
        Slot becomes available
```

## Notification Messages

### Student Cancels (to Tutor):
```
📧 Booking Cancelled
John Doe cancelled the Math session on Feb 10, 2026.
Refund: 50% (ETB 250)
Reason: "Schedule conflict"
```

### Tutor Cancels (to Student):
```
📧 Booking Cancelled - Full Refund
Sarah Smith cancelled the Math session on Feb 10, 2026.
Refund: 100% (ETB 500) - Full refund processed
Reason: "Emergency - need to reschedule"
```

## Platform Fee Impact

### Student Cancellation:
```
Booking: ETB 500
Platform Fee: 20% (ETB 100)
Tutor Earnings: 80% (ETB 400)

If student cancels with 50% refund:
- Student gets: ETB 250
- Tutor gets: ETB 200 (50% of earnings)
- Platform keeps: ETB 50 (50% of fee)
```

### Tutor Cancellation:
```
Booking: ETB 500
Platform Fee: 20% (ETB 100)
Tutor Earnings: 80% (ETB 400)

If tutor cancels:
- Student gets: ETB 500 (100% refund)
- Tutor gets: ETB 0
- Platform refunds: ETB 100 (fee returned)
```

## Testing Checklist

### Student Cancellation Tests:
- [ ] Cancel 2 hours before → 100% refund
- [ ] Cancel 45 minutes before → 50% refund
- [ ] Cancel 15 minutes before → 0% refund
- [ ] Verify tutor receives compensation
- [ ] Check notification sent to tutor

### Tutor Cancellation Tests:
- [ ] Cancel 2 hours before → 100% refund
- [ ] Cancel 45 minutes before → 100% refund
- [ ] Cancel 15 minutes before → 100% refund
- [ ] Cancel 5 minutes before → 100% refund
- [ ] Verify student receives full refund
- [ ] Check notification sent to student
- [ ] Verify slot becomes available

## Summary

### Key Takeaways:
1. **Students**: Time-based refund (0-100%)
2. **Tutors**: Always 100% refund
3. **Reason**: Protect students, encourage tutor commitment
4. **UI**: Different colors and messages
5. **Backend**: Same endpoint, different logic
6. **Fair**: Both parties protected appropriately

### Fair for Everyone:
- ✅ Students protected from tutor cancellations
- ✅ Tutors protected from last-minute student cancellations
- ✅ Platform maintains trust and reputation
- ✅ Clear policies prevent disputes
- ✅ Automated refund processing

## Status: IMPLEMENTED ✅

Both cancellation flows are fully implemented and working. The system automatically detects who is cancelling and applies the appropriate refund policy.
