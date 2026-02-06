# 💰 Wallet System - Quick Start Guide

## ✅ What's Been Created

### Backend Models & Services
1. **Wallet Model** (`server/models/Wallet.js`) ✅
   - User wallet with balance tracking
   - Escrow balance management
   - Lifetime statistics
   - Freeze/unfreeze functionality

2. **Wallet Service** (`server/services/walletService.js`) ✅
   - Get/create wallet
   - Add/deduct balance
   - Move to/from escrow
   - Refund processing
   - Transaction history

### Implementation Plan
3. **Complete Plan** (`WALLET_SYSTEM_IMPLEMENTATION_PLAN.md`) ✅
   - Full architecture
   - Database schema
   - API endpoints
   - Mobile app screens
   - Testing scenarios

## 🚀 Next Steps to Complete

### Phase 1: Backend Controllers & Routes (2-3 hours)
Create these files:

1. **`server/controllers/walletController.js`**
```javascript
// Endpoints:
- getWalletBalance()
- initializeTopUp()
- getTransactions()
- getStatistics()
- requestWithdrawal()
- getWithdrawals()
```

2. **`server/routes/wallet.js`**
```javascript
// Routes:
GET    /api/wallet/balance
POST   /api/wallet/topup
GET    /api/wallet/transactions
GET    /api/wallet/statistics
POST   /api/wallet/withdraw
GET    /api/wallet/withdrawals
```

3. **Update `server/server.js`**
```javascript
// Add wallet routes
const walletRoutes = require('./routes/wallet');
app.use('/api/wallet', walletRoutes);
```

### Phase 2: Update Booking Flow (2-3 hours)

1. **Update `server/controllers/bookingController.js`**
   - Add wallet payment option
   - Check balance before booking
   - Deduct from wallet and move to escrow
   - Update payment status

2. **Update `server/services/escrowService.js`**
   - Integrate with wallet service
   - Release escrow to tutor wallet
   - Handle refunds to student wallet

3. **Update Chapa Webhook**
   - Handle wallet top-up webhooks
   - Verify and update wallet balance

### Phase 3: Mobile App - Wallet UI (4-6 hours)

Create these screens:

1. **`mobile_app/lib/features/wallet/screens/wallet_screen.dart`**
   - Display balance
   - Show recent transactions
   - Add balance button
   - Withdraw button (tutor only)

2. **`mobile_app/lib/features/wallet/screens/add_balance_screen.dart`**
   - Enter amount
   - Redirect to Chapa
   - Handle callback

3. **`mobile_app/lib/features/wallet/screens/transaction_history_screen.dart`**
   - List all transactions
   - Filter by type
   - Show details

4. **`mobile_app/lib/features/wallet/services/wallet_service.dart`**
   - API calls for wallet operations

### Phase 4: Update Booking UI (2-3 hours)

1. **Update `mobile_app/lib/features/student/screens/tutor_booking_screen.dart`**
   - Add "Pay with Wallet" option
   - Show wallet balance
   - Handle insufficient balance

2. **Update Profile Screens**
   - Add wallet balance display
   - Add "My Wallet" button

### Phase 5: Testing (2-3 hours)

Test these scenarios:
- [ ] Wallet top-up via Chapa
- [ ] Booking with wallet balance
- [ ] Insufficient balance handling
- [ ] Refund to wallet (student cancel)
- [ ] Refund to wallet (tutor cancel)
- [ ] Escrow release to tutor
- [ ] Withdrawal request

## 📋 Implementation Checklist

### Backend
- [x] Create Wallet model
- [x] Create WalletService
- [x] Create implementation plan
- [ ] Create WalletController
- [ ] Create wallet routes
- [ ] Update booking controller for wallet
- [ ] Update escrow service for wallet
- [ ] Update Chapa webhook for top-ups
- [ ] Update Transaction model types
- [ ] Test wallet operations

### Mobile App
- [ ] Create WalletService (API calls)
- [ ] Create Wallet screen
- [ ] Create Add Balance screen
- [ ] Create Transaction History screen
- [ ] Create Withdrawal screen (tutor)
- [ ] Update booking screen for wallet
- [ ] Update profile screens
- [ ] Add wallet balance widget
- [ ] Test wallet flows

### Testing
- [ ] Test wallet top-up
- [ ] Test booking with wallet
- [ ] Test refunds
- [ ] Test escrow release
- [ ] Test withdrawals
- [ ] Test edge cases

## 🎯 Quick Implementation Path

If you want to implement this quickly, follow this order:

### Day 1: Backend Core
1. Create `walletController.js` (1 hour)
2. Create `wallet.js` routes (30 min)
3. Update `server.js` to include routes (5 min)
4. Update booking controller for wallet payment (1 hour)
5. Test with Postman (30 min)

### Day 2: Chapa Integration
1. Update Chapa webhook for top-ups (1 hour)
2. Test wallet top-up flow (1 hour)
3. Update escrow service (1 hour)
4. Test booking with wallet (1 hour)

### Day 3: Mobile App UI
1. Create WalletService (1 hour)
2. Create Wallet screen (2 hours)
3. Create Add Balance screen (1 hour)
4. Update booking screen (1 hour)

### Day 4: Testing & Polish
1. End-to-end testing (2 hours)
2. Fix bugs (2 hours)
3. UI polish (1 hour)
4. Deploy (1 hour)

## 💡 Key Concepts

### Wallet Balance Flow
```
Student Wallet Balance
    ↓
Pay for Booking → Move to Escrow
    ↓
Session Completed → Wait 2 Hours
    ↓
Escrow → Tutor Wallet Balance
    ↓
Tutor Withdraws → Bank Account
```

### Refund Flow
```
Cancellation Triggered
    ↓
Calculate Refund Amount
    ↓
Escrow → Student Wallet Balance
    ↓
Balance Updated Immediately
```

### Top-Up Flow
```
Student → Add Balance Screen
    ↓
Enter Amount → Chapa Checkout
    ↓
Complete Payment → Webhook
    ↓
Verify → Update Wallet Balance
    ↓
Show Success Message
```

## 🔧 Configuration

Add to `.env`:
```env
# Wallet Configuration
WALLET_MIN_TOPUP=10
WALLET_MAX_TOPUP=10000
WALLET_MIN_WITHDRAWAL=50
WALLET_MAX_WITHDRAWAL=50000
ESCROW_RELEASE_DELAY_HOURS=2
```

## 📱 Mobile App Routes

Add to `app_router.dart`:
```dart
GoRoute(
  path: '/wallet',
  builder: (context, state) => const WalletScreen(),
),
GoRoute(
  path: '/wallet/add-balance',
  builder: (context, state) => const AddBalanceScreen(),
),
GoRoute(
  path: '/wallet/transactions',
  builder: (context, state) => const TransactionHistoryScreen(),
),
GoRoute(
  path: '/wallet/withdraw',
  builder: (context, state) => const WithdrawalScreen(),
),
```

## 🎨 UI Components Needed

1. **Wallet Balance Card**
   - Current balance
   - Escrow balance
   - Total balance
   - Currency

2. **Transaction List Item**
   - Transaction type icon
   - Description
   - Amount (+ or -)
   - Date/time
   - Status

3. **Add Balance Form**
   - Amount input
   - Quick amount buttons (100, 500, 1000)
   - Payment method (Chapa)
   - Submit button

4. **Withdrawal Form**
   - Amount input
   - Bank account details
   - Available balance display
   - Submit button

## 🚨 Important Notes

1. **Always use transactions** for wallet operations to ensure atomicity
2. **Validate balance** before any deduction
3. **Log all operations** for audit trail
4. **Handle concurrent requests** properly
5. **Test refund scenarios** thoroughly
6. **Secure webhook endpoints** with signature verification

## 📞 Need Help?

Refer to:
- `WALLET_SYSTEM_IMPLEMENTATION_PLAN.md` - Full architecture
- `server/models/Wallet.js` - Wallet model methods
- `server/services/walletService.js` - Wallet operations
- Existing payment files for Chapa integration examples

## ✅ Success Criteria

- [ ] Student can top up wallet via Chapa
- [ ] Student can book using wallet balance
- [ ] Insufficient balance shows error
- [ ] Refunds go to wallet immediately
- [ ] Escrow releases to tutor after session
- [ ] Tutor can withdraw earnings
- [ ] All transactions are logged
- [ ] Balance is always accurate

---

**Status**: Foundation Complete - Ready for Controller & UI Implementation
**Estimated Time**: 2-4 days for full implementation
**Priority**: High
