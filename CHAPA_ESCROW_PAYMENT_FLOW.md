# 💳 Chapa Payment + Escrow Flow Implementation

## 🎯 Goal
Integrate Chapa payment with escrow system for secure tutor payments with 10-minute dispute window.

---

## 📊 Payment Flow

### Step 1: Student Books Session
✅ Already implemented - booking created with session details

### Step 2: Payment Initialization
**When**: After booking confirmation
**What**: Redirect student to Chapa checkout

```
Student clicks "Book Session" →
Booking created (status: 'pending_payment') →
Payment initialized via Chapa →
Student redirected to Chapa checkout page
```

### Step 3: Payment Processing
**When**: Student completes payment on Chapa
**What**: Chapa processes payment and sends webhook

```
Student pays on Chapa →
Chapa webhook received →
Payment verified →
Booking status: 'confirmed' →
Payment status: 'paid' →
Escrow status: 'held'
```

### Step 4: Session Takes Place
**When**: Scheduled session time
**What**: Tutor and student conduct session

```
Session starts →
Session ends →
Booking status: 'completed' →
Escrow release scheduled (10 minutes from now)
```

### Step 5: Dispute Window
**When**: After session completion
**What**: 10-minute window for disputes

```
Session completed at 10:00 AM →
Dispute window: 10:00 AM - 10:10 AM →
If no dispute filed → Auto-release at 10:10 AM
If dispute filed → Hold payment, admin review
```

### Step 6: Payment Release
**When**: 10 minutes after session completion (no dispute)
**What**: Automatic release to tutor

```
10 minutes passed →
No dispute filed →
Escrow status: 'released' →
Payment transferred to tutor balance →
Tutor notified
```

---

## 🔧 Implementation Tasks

### Task 1: Update Booking Model ✅ (Partially Done)
**File**: `server/models/Booking.js`

**Changes Needed**:
1. Change `releaseDelayHours` to `releaseDelayMinutes` in escrow schema
2. Update `completeSession()` method to use minutes
3. Update `endSession()` method to use minutes
4. Add `releaseDelayMinutes` field to escrow schema

**Code Changes**:
```javascript
// In escrow schema
releaseDelayMinutes: {
  type: Number,
  default: 10 // 10 minutes for testing, 1440 for 24 hours production
},

// In completeSession() and endSession()
const releaseDelayMinutes = this.escrow.releaseDelayMinutes || 10;
releaseDate.setMinutes(releaseDate.getMinutes() + releaseDelayMinutes);
console.log(`   (${releaseDelayMinutes} minutes from now - dispute window)`);
```

### Task 2: Update Escrow Service ✅ DONE
**File**: `server/services/escrowService.js`

**Changes Made**:
- Changed from `releaseDelayHours` to `releaseDelayMinutes`
- Default: 10 minutes for testing
- Scheduler runs every 5 minutes

### Task 3: Update Booking Controller
**File**: `server/controllers/bookingController.js`

**Changes Needed**:
1. After booking creation, return booking ID for payment
2. Don't auto-confirm booking - wait for payment
3. Set initial status to 'pending_payment'

**Code**:
```javascript
// In createBooking
const booking = new Booking({
  // ... existing fields
  status: 'pending_payment', // Wait for payment
  payment: {
    status: 'pending',
    amount: totalAmount,
    method: 'chapa'
  },
  escrow: {
    status: 'pending',
    autoReleaseEnabled: true,
    releaseDelayMinutes: 10 // 10 minutes dispute window
  }
});

await booking.save();

return res.status(201).json({
  success: true,
  message: 'Booking created. Please complete payment.',
  data: {
    booking: booking,
    requiresPayment: true
  }
});
```

### Task 4: Update Payment Service
**File**: `server/services/paymentService.js`

**Changes Needed**:
1. After payment verification, update booking status
2. Hold payment in escrow
3. Notify both parties

**Code**:
```javascript
async verifyPayment(reference) {
  // Verify with Chapa
  const chapaResult = await chapaService.verifyPayment(reference);
  
  if (chapaResult.success && chapaResult.data.status === 'success') {
    // Find booking by reference
    const booking = await Booking.findOne({ 'payment.chapaReference': reference });
    
    // Update payment status
    booking.payment.status = 'paid';
    booking.payment.paidAt = new Date();
    booking.status = 'confirmed';
    
    // Hold in escrow
    await booking.holdInEscrow();
    
    // Notify parties
    await notificationService.notifyBookingConfirmed(booking);
    
    return { success: true, booking };
  }
}
```

### Task 5: Create Payment Screen (Mobile)
**File**: `mobile_app/lib/features/student/screens/payment_screen.dart` (NEW)

**Features**:
- Show booking summary
- Show amount to pay
- "Pay with Chapa" button
- Open Chapa checkout in WebView
- Handle payment callback
- Show success/failure

**Code Structure**:
```dart
class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  // ... other details
}

// Initialize payment
Future<void> _initializePayment() async {
  final response = await paymentService.initializePayment(bookingId);
  if (response.success) {
    // Open Chapa checkout URL in WebView
    _openChapaCheckout(response.data['checkoutUrl']);
  }
}

// Handle payment result
void _handlePaymentResult(String status) {
  if (status == 'success') {
    // Verify payment
    // Show success
    // Navigate to bookings
  } else {
    // Show error
    // Allow retry
  }
}
```

### Task 6: Update Payment WebView Screen
**File**: `mobile_app/lib/features/student/screens/payment_webview_screen.dart`

**Changes Needed**:
- Handle Chapa callback URLs
- Detect payment success/failure
- Return result to payment screen

### Task 7: Add Dispute System (Optional for MVP)
**Files**: 
- `server/models/Dispute.js` (already exists)
- `server/controllers/disputeController.js`
- Mobile dispute filing screen

**Features**:
- Student can file dispute within 10 minutes
- Dispute pauses escrow release
- Admin reviews and resolves
- Payment released based on resolution

---

## 📱 Mobile App Flow

### Current Flow (Before Payment):
```
1. Select tutor
2. Choose time slot
3. Select session type & duration
4. Confirm booking
5. ❌ Booking created (no payment)
```

### New Flow (With Payment):
```
1. Select tutor
2. Choose time slot
3. Select session type & duration
4. Confirm booking
5. ✨ Booking created (pending_payment)
6. ✨ Redirect to Payment Screen
7. ✨ Pay with Chapa
8. ✨ Payment verified
9. ✅ Booking confirmed
10. 📧 Notifications sent
```

---

## 🔐 Security Considerations

### Payment Security:
- ✅ Use Chapa's secure checkout
- ✅ Verify webhook signatures
- ✅ Verify payment on backend
- ✅ Never trust client-side payment status

### Escrow Security:
- ✅ Hold funds on platform (not with tutor or student)
- ✅ Automatic release after dispute window
- ✅ Manual release option for admin
- ✅ Audit trail for all transactions

### Dispute Protection:
- ✅ 10-minute window for disputes
- ✅ Payment held during dispute
- ✅ Admin review required
- ✅ Evidence collection system

---

## 🧪 Testing Checklist

### Payment Flow:
- [ ] Initialize payment for booking
- [ ] Complete payment on Chapa
- [ ] Verify webhook received
- [ ] Booking status updated to 'confirmed'
- [ ] Escrow status set to 'held'
- [ ] Notifications sent

### Escrow Flow:
- [ ] Session completed
- [ ] Escrow release scheduled (10 min)
- [ ] Scheduler picks up release
- [ ] Payment released to tutor
- [ ] Tutor notified
- [ ] Balance updated

### Dispute Flow:
- [ ] File dispute within 10 minutes
- [ ] Escrow release paused
- [ ] Admin notified
- [ ] Admin reviews
- [ ] Payment released based on decision

### Edge Cases:
- [ ] Payment fails - booking cancelled
- [ ] Payment timeout - booking expired
- [ ] Duplicate payment - refund extra
- [ ] Session cancelled before payment - full refund
- [ ] Session cancelled after payment - refund rules apply
- [ ] Dispute filed after 10 minutes - rejected

---

## 📊 Database Schema Updates

### Booking Model:
```javascript
escrow: {
  status: 'pending' | 'held' | 'released' | 'refunded',
  heldAt: Date,
  releasedAt: Date,
  releaseScheduledFor: Date,
  releaseDelayMinutes: Number, // NEW: Changed from Hours
  autoReleaseEnabled: Boolean
},

payment: {
  status: 'pending' | 'paid' | 'failed' | 'refunded',
  amount: Number,
  method: 'chapa',
  chapaReference: String,
  paidAt: Date
}
```

### Transaction Model:
Already exists - no changes needed

---

## 🚀 Deployment Steps

### 1. Backend Updates:
```bash
# Update Booking model
# Update Escrow service
# Update Payment service
# Update Booking controller
# Restart server
```

### 2. Frontend Updates:
```bash
# Create Payment screen
# Update Booking screen
# Update Payment WebView
# Rebuild app
```

### 3. Environment Variables:
```env
# Chapa Configuration
CHAPA_SECRET_KEY=your_secret_key
CHAPA_WEBHOOK_SECRET=your_webhook_secret
CHAPA_BASE_URL=https://api.chapa.co/v1

# Escrow Configuration
ESCROW_RELEASE_DELAY_MINUTES=10  # 10 min for testing, 1440 for 24hrs
ESCROW_SCHEDULER_FREQUENCY=5      # Check every 5 minutes
```

### 4. Testing:
```bash
# Test payment flow
# Test escrow release
# Test dispute window
# Test edge cases
```

---

## 📝 Status

**Current**: Planning & Partial Implementation
**Next**: Complete implementation tasks 1-6
**Timeline**: ~3-4 hours

### Completed:
- ✅ Escrow service updated for 10-minute window
- ✅ Booking screen updated to navigate to payment
- ✅ Payment and escrow infrastructure exists

### Remaining:
- [ ] Update Booking model (releaseDelayMinutes)
- [ ] Update Booking controller (pending_payment status)
- [ ] Update Payment service (escrow integration)
- [ ] Create Payment screen (mobile)
- [ ] Update Payment WebView (mobile)
- [ ] Test complete flow

---

**Last Updated**: Context Transfer Session
**Priority**: High
**Complexity**: Medium
