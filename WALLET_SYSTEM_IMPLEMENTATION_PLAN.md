# 💰 Wallet-Based Payment System Implementation Plan

## Overview
Implementing a comprehensive wallet system that integrates with Chapa for top-ups, handles bookings through wallet balance, manages escrow, and processes refunds internally.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WALLET SYSTEM FLOW                        │
└─────────────────────────────────────────────────────────────┘

1️⃣ WALLET TOP-UP (via Chapa)
   Student → Add Balance Screen
   ↓
   Enter Amount → Chapa Checkout
   ↓
   Complete Payment → Webhook Callback
   ↓
   Backend: Verify → Store Transaction → Update Wallet Balance
   ↓
   App: "Balance Updated Successfully"

2️⃣ BOOKING PAYMENT (via Wallet)
   Student → Book Session → Pay with Wallet
   ↓
   Backend: Check Balance → Deduct from Wallet → Move to Escrow
   ↓
   Booking Status: Confirmed (No Chapa needed)

3️⃣ ESCROW & RELEASE
   Session Completed → Wait 2 Hours
   ↓
   Auto-Release: Escrow → Tutor Earnings
   ↓
   Tutor: Can Withdraw Anytime

4️⃣ REFUNDS (Internal)
   Cancellation → Calculate Refund
   ↓
   Escrow → Student Wallet (No Chapa)
   ↓
   Balance Updated Immediately
```

## Database Schema Changes

### 1. New Wallet Model
```javascript
{
  userId: ObjectId (ref: User),
  balance: Number (default: 0),
  currency: String (default: 'ETB'),
  escrowBalance: Number (default: 0),
  totalDeposited: Number (default: 0),
  totalSpent: Number (default: 0),
  totalWithdrawn: Number (default: 0),
  totalRefunded: Number (default: 0),
  isActive: Boolean (default: true),
  lastTransactionAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### 2. Updated Transaction Model
```javascript
{
  // Existing fields...
  type: ['wallet_topup', 'wallet_deduction', 'wallet_refund', 
         'escrow_hold', 'escrow_release', 'withdrawal', 'platform_fee'],
  walletId: ObjectId (ref: Wallet),
  relatedTransactionId: ObjectId (ref: Transaction),
  balanceBefore: Number,
  balanceAfter: Number,
  // ... rest of fields
}
```

### 3. Updated Booking Model
```javascript
{
  // Existing fields...
  payment: {
    method: String, // 'wallet' or 'chapa'
    status: String, // 'pending', 'paid', 'refunded'
    amount: Number,
    paidAt: Date,
    walletTransactionId: ObjectId,
    escrowTransactionId: ObjectId,
    refundTransactionId: ObjectId
  }
}
```

## Implementation Steps

### Phase 1: Backend - Wallet Core
- [ ] Create Wallet model
- [ ] Create WalletService with methods:
  - `createWallet(userId)`
  - `getWalletBalance(userId)`
  - `addBalance(userId, amount, transactionId)`
  - `deductBalance(userId, amount, description)`
  - `refundBalance(userId, amount, description)`
  - `checkSufficientBalance(userId, amount)`
- [ ] Update Transaction model with wallet types
- [ ] Create wallet routes and controller

### Phase 2: Backend - Wallet Top-Up Integration
- [ ] Update ChapaService for wallet top-ups
- [ ] Create wallet top-up endpoint
- [ ] Implement webhook handler for wallet top-ups
- [ ] Create transaction records for top-ups
- [ ] Update wallet balance after successful payment

### Phase 3: Backend - Booking with Wallet
- [ ] Update booking controller to support wallet payment
- [ ] Implement balance check before booking
- [ ] Deduct from wallet and move to escrow
- [ ] Update booking payment status
- [ ] Create escrow transaction records

### Phase 4: Backend - Escrow Management
- [ ] Update EscrowService for wallet integration
- [ ] Implement auto-release after session completion
- [ ] Move escrow to tutor earnings (wallet)
- [ ] Handle manual release by admin
- [ ] Track escrow transactions

### Phase 5: Backend - Refund System
- [ ] Implement wallet refund logic
- [ ] Handle student cancellation refunds
- [ ] Handle tutor cancellation refunds (100%)
- [ ] Handle dispute refunds
- [ ] Update wallet balance immediately
- [ ] Create refund transaction records

### Phase 6: Backend - Withdrawal System
- [ ] Create withdrawal request endpoint
- [ ] Implement withdrawal processing
- [ ] Integrate with Chapa payout API (or manual)
- [ ] Deduct from tutor wallet
- [ ] Track withdrawal transactions

### Phase 7: Mobile App - Wallet UI
- [ ] Create Wallet Screen (balance display)
- [ ] Create Add Balance Screen
- [ ] Integrate Chapa checkout for top-up
- [ ] Create Transaction History Screen
- [ ] Update booking flow to use wallet
- [ ] Show wallet balance in profile

### Phase 8: Mobile App - Payment Flow
- [ ] Update booking screen to show wallet option
- [ ] Implement "Pay with Wallet" button
- [ ] Show insufficient balance error
- [ ] Redirect to add balance if needed
- [ ] Show payment success/failure

### Phase 9: Mobile App - Withdrawal
- [ ] Create Withdrawal Screen (tutor only)
- [ ] Add bank account form
- [ ] Implement withdrawal request
- [ ] Show withdrawal history
- [ ] Track withdrawal status

### Phase 10: Testing & Deployment
- [ ] Test wallet top-up flow
- [ ] Test booking with wallet
- [ ] Test refund scenarios
- [ ] Test withdrawal flow
- [ ] Test edge cases (insufficient balance, etc.)
- [ ] Deploy to production

## API Endpoints

### Wallet Endpoints
```
POST   /api/wallet/topup              - Initialize wallet top-up
GET    /api/wallet/balance            - Get wallet balance
GET    /api/wallet/transactions       - Get wallet transactions
POST   /api/wallet/withdraw           - Request withdrawal
GET    /api/wallet/withdrawals        - Get withdrawal history
```

### Updated Booking Endpoints
```
POST   /api/bookings                  - Create booking (with wallet option)
POST   /api/bookings/:id/pay-wallet   - Pay booking with wallet
POST   /api/bookings/:id/refund       - Refund to wallet
```

### Webhook Endpoints
```
POST   /api/payments/webhook/topup    - Chapa webhook for wallet top-ups
```

## Mobile App Screens

### New Screens
1. **Wallet Screen** (`wallet_screen.dart`)
   - Display current balance
   - Show recent transactions
   - Add balance button
   - Withdraw button (tutor only)

2. **Add Balance Screen** (`add_balance_screen.dart`)
   - Enter amount
   - Show Chapa payment options
   - Redirect to Chapa checkout
   - Handle callback

3. **Withdrawal Screen** (`withdrawal_screen.dart`)
   - Show available balance
   - Enter withdrawal amount
   - Bank account details form
   - Submit withdrawal request

4. **Transaction History Screen** (`transaction_history_screen.dart`)
   - List all wallet transactions
   - Filter by type
   - Show details

### Updated Screens
1. **Booking Screen**
   - Add "Pay with Wallet" option
   - Show wallet balance
   - Show insufficient balance warning

2. **Profile Screen**
   - Add wallet balance display
   - Add "My Wallet" button

## Transaction Types

### Wallet Transactions
- `wallet_topup` - Money added via Chapa
- `wallet_deduction` - Money deducted for booking
- `wallet_refund` - Money refunded from cancellation
- `escrow_hold` - Money moved to escrow
- `escrow_release` - Money released from escrow
- `withdrawal` - Money withdrawn to bank
- `platform_fee` - Platform fee deduction

## Refund Policy (Wallet-Based)

### Student Cancellation
- More than 24 hours before: 90% refund to wallet
- 12-24 hours before: 50% refund to wallet
- Less than 12 hours: 25% refund to wallet
- After session start: No refund

### Tutor Cancellation
- Any time: 100% refund to wallet
- Immediate refund processing

### Dispute Resolution
- Admin can refund any amount to wallet
- Admin can release escrow to tutor
- All handled internally (no Chapa)

## Security Considerations

1. **Balance Validation**
   - Always check balance before deduction
   - Use database transactions for atomicity
   - Prevent negative balances

2. **Webhook Security**
   - Verify Chapa webhook signatures
   - Validate transaction amounts
   - Prevent duplicate processing

3. **Withdrawal Security**
   - Verify bank account details
   - Implement withdrawal limits
   - Add admin approval for large amounts

4. **Audit Trail**
   - Log all wallet transactions
   - Track balance changes
   - Store transaction metadata

## Testing Scenarios

### Wallet Top-Up
- [ ] Successful top-up
- [ ] Failed top-up
- [ ] Duplicate webhook handling
- [ ] Invalid amount

### Booking Payment
- [ ] Sufficient balance
- [ ] Insufficient balance
- [ ] Concurrent bookings
- [ ] Failed escrow transfer

### Refunds
- [ ] Student cancellation (various times)
- [ ] Tutor cancellation
- [ ] Admin refund
- [ ] Partial refund

### Withdrawals
- [ ] Successful withdrawal
- [ ] Insufficient balance
- [ ] Invalid bank details
- [ ] Pending withdrawal

## Success Metrics

- Wallet top-up success rate > 95%
- Booking payment success rate > 99%
- Refund processing time < 1 second
- Withdrawal processing time < 24 hours
- Zero balance discrepancies

## Timeline

- **Phase 1-3**: Backend Core (2-3 days)
- **Phase 4-6**: Escrow & Refunds (2 days)
- **Phase 7-9**: Mobile App (3-4 days)
- **Phase 10**: Testing & Deployment (1-2 days)

**Total**: 8-11 days

## Next Steps

1. Create Wallet model
2. Implement WalletService
3. Update Transaction model
4. Create wallet endpoints
5. Test wallet top-up flow
6. Implement booking with wallet
7. Build mobile app UI
8. Test end-to-end flow
9. Deploy to production

---

**Status**: Ready to implement
**Priority**: High
**Complexity**: High
