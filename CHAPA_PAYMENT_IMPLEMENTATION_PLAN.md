# Chapa Payment Integration - Implementation Plan

## Overview
Integrate Chapa payment gateway for booking payments with tutor balance management and withdrawal system.

## Payment Flow

### 1. Student Payment Flow
```
Student books session
  ↓
Student pays via Chapa
  ↓
Payment verified
  ↓
Money added to Tutor Balance
  ↓
Booking confirmed
```

### 2. Tutor Withdrawal Flow
```
Tutor requests withdrawal
  ↓
Platform deducts 10% fee
  ↓
Remaining 90% sent to tutor
  ↓
Balance updated
  ↓
Transaction recorded
```

## Database Schema

### TutorProfile Updates
```javascript
{
  balance: {
    available: Number,      // Available for withdrawal
    pending: Number,        // From unconfirmed bookings
    total: Number,          // Total earned
    withdrawn: Number       // Total withdrawn
  },
  bankAccount: {
    accountNumber: String,
    accountName: String,
    bankName: String
  }
}
```

### New Model: Transaction
```javascript
{
  userId: ObjectId,
  type: 'payment' | 'withdrawal' | 'refund',
  amount: Number,
  fee: Number,
  netAmount: Number,
  status: 'pending' | 'completed' | 'failed',
  bookingId: ObjectId,
  chapaReference: String,
  description: String,
  createdAt: Date
}
```

### Booking Updates
```javascript
{
  payment: {
    amount: Number,
    status: 'pending' | 'paid' | 'refunded',
    method: 'chapa',
    chapaReference: String,
    paidAt: Date,
    tutorShare: Number,     // 90% of amount
    platformFee: Number     // 10% of amount
  }
}
```

## Backend Implementation

### 1. Chapa Service (server/services/chapaService.js)
- Initialize payment
- Verify payment
- Process webhook
- Handle refunds

### 2. Payment Controller (server/controllers/paymentController.js)
- Initialize booking payment
- Verify payment callback
- Process withdrawal request
- Get transaction history

### 3. Balance Management
- Add to balance on payment
- Deduct on withdrawal
- Track pending amounts
- Calculate platform fees

### 4. API Endpoints

#### Payment Endpoints
```
POST   /api/payments/initialize        - Initialize Chapa payment
POST   /api/payments/verify/:reference - Verify payment
POST   /api/payments/webhook           - Chapa webhook
GET    /api/payments/transactions      - Get transaction history
```

#### Withdrawal Endpoints
```
POST   /api/withdrawals/request        - Request withdrawal
GET    /api/withdrawals                - Get withdrawal history
GET    /api/withdrawals/balance        - Get current balance
PUT    /api/withdrawals/bank-account   - Update bank account
```

## Mobile App Implementation

### 1. Payment Service (mobile_app/lib/core/services/payment_service.dart)
- Initialize payment
- Open Chapa payment page
- Verify payment status
- Handle payment callback

### 2. Withdrawal Service (mobile_app/lib/core/services/withdrawal_service.dart)
- Request withdrawal
- Get balance
- Get withdrawal history
- Update bank account

### 3. UI Screens

#### Student Side
- **Payment Screen**: Show amount, initiate Chapa payment
- **Payment Status**: Show payment progress and result

#### Tutor Side
- **Balance Screen**: Show available, pending, total balance
- **Withdrawal Screen**: Request withdrawal with bank details
- **Transaction History**: List all transactions
- **Bank Account Setup**: Add/update bank account

## Chapa Integration Details

### Configuration
```javascript
// .env
CHAPA_SECRET_KEY=your_secret_key_here
CHAPA_WEBHOOK_SECRET=your_webhook_secret_here
CHAPA_BASE_URL=https://api.chapa.co/v1
```

### Initialize Payment
```javascript
POST https://api.chapa.co/v1/transaction/initialize
Headers: Authorization: Bearer SECRET_KEY
Body: {
  amount: "100",
  currency: "ETB",
  email: "student@example.com",
  first_name: "John",
  last_name: "Doe",
  tx_ref: "booking_123456",
  callback_url: "https://yourapp.com/api/payments/callback",
  return_url: "https://yourapp.com/payment-success",
  customization: {
    title: "Tutor Booking Payment",
    description: "Payment for tutoring session"
  }
}
```

### Verify Payment
```javascript
GET https://api.chapa.co/v1/transaction/verify/{tx_ref}
Headers: Authorization: Bearer SECRET_KEY
```

## Platform Fee Calculation

### On Payment
```
Booking Amount: 1000 ETB
Platform keeps: 0 ETB (initially)
Tutor gets: 1000 ETB (added to balance)
```

### On Withdrawal
```
Withdrawal Request: 1000 ETB
Platform Fee (10%): 100 ETB
Tutor Receives: 900 ETB
```

## Security Considerations

1. **Webhook Verification**: Verify Chapa webhook signatures
2. **Idempotency**: Prevent duplicate payments
3. **Balance Validation**: Ensure sufficient balance before withdrawal
4. **Transaction Logging**: Log all financial transactions
5. **Encryption**: Encrypt sensitive bank account data

## Implementation Steps

### Phase 1: Backend Setup
1. ✅ Create Transaction model
2. ✅ Update TutorProfile model with balance fields
3. ✅ Update Booking model with payment fields
4. ✅ Create Chapa service
5. ✅ Create payment controller
6. ✅ Create withdrawal controller
7. ✅ Add API routes

### Phase 2: Mobile App
1. ✅ Create payment service
2. ✅ Create withdrawal service
3. ✅ Create payment screen
4. ✅ Create balance/earnings screen
5. ✅ Create withdrawal screen
6. ✅ Create transaction history screen
7. ✅ Integrate with booking flow

### Phase 3: Testing
1. Test payment initialization
2. Test payment verification
3. Test balance updates
4. Test withdrawal requests
5. Test fee calculations
6. Test edge cases

## Files to Create/Modify

### Backend
- `server/models/Transaction.js` (NEW)
- `server/services/chapaService.js` (NEW)
- `server/controllers/paymentController.js` (UPDATE)
- `server/controllers/withdrawalController.js` (NEW)
- `server/routes/payments.js` (UPDATE)
- `server/routes/withdrawals.js` (NEW)
- `server/models/TutorProfile.js` (UPDATE)
- `server/models/Booking.js` (UPDATE)

### Mobile App
- `mobile_app/lib/core/services/payment_service.dart` (NEW)
- `mobile_app/lib/core/services/withdrawal_service.dart` (NEW)
- `mobile_app/lib/features/payment/screens/payment_screen.dart` (NEW)
- `mobile_app/lib/features/tutor/screens/tutor_earnings_screen.dart` (UPDATE)
- `mobile_app/lib/features/tutor/screens/withdrawal_screen.dart` (NEW)
- `mobile_app/lib/features/tutor/screens/transaction_history_screen.dart` (NEW)

## Next Steps

1. You provide Chapa API keys
2. I'll implement the backend integration
3. I'll create the mobile app UI
4. We'll test the complete flow

## Notes

- Chapa supports ETB (Ethiopian Birr) currency
- Minimum withdrawal amount can be set (e.g., 100 ETB)
- Withdrawal processing time: 1-3 business days
- Platform fee is configurable (currently 10%)
- All amounts stored in database as numbers (not strings)

---

**Status**: Ready to implement once Chapa keys are provided
**Estimated Time**: 4-6 hours for complete implementation
