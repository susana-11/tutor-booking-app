# 🧪 Wallet System - Quick Testing Guide

## 🚀 Before You Start

### 1. Rebuild Mobile App
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### 2. Backend Status
✅ Backend is already deployed and running on Render
✅ All wallet endpoints are live
✅ Chapa integration is in test mode

---

## 📱 Test Scenarios

### Test 1: View Wallet Balance (Profile Screen)
**Steps:**
1. Open the app and login as a student
2. Navigate to Profile screen (bottom nav)
3. Look for the wallet balance card (purple gradient)

**Expected Result:**
- ✅ Wallet card displays with balance (0.00 ETB initially)
- ✅ Shows "Available Balance"
- ✅ Shows "Add Money" and "History" buttons
- ✅ Card is clickable

**Screenshot Location:** Top of profile screen, below profile header

---

### Test 2: Open Wallet Screen
**Steps:**
1. From profile screen, tap on the wallet balance card
   OR
2. Scroll down to "Account Settings" → tap "My Wallet"

**Expected Result:**
- ✅ Opens wallet screen
- ✅ Shows balance card with gradient
- ✅ Shows "Add Money" and "History" action buttons
- ✅ Shows "Recent Transactions" section
- ✅ Initially shows "No transactions yet"

---

### Test 3: Add Money to Wallet
**Steps:**
1. Open wallet screen
2. Tap "Add Money" button
3. Enter amount: 1000 ETB (or select quick amount)
4. Tap "Add Balance" button
5. Redirects to Chapa payment page
6. Use Chapa test card:
   - Card: 5200000000000007
   - Expiry: Any future date
   - CVV: 123
7. Complete payment
8. Return to app

**Expected Result:**
- ✅ Redirects to Chapa checkout
- ✅ Payment processes successfully
- ✅ Webhook updates balance automatically
- ✅ Balance shows 1000.00 ETB
- ✅ Transaction appears in history

**Console Logs to Check:**
```
✅ Top-up initialized
✅ Chapa payment successful
✅ Webhook received
✅ Balance updated
```

---

### Test 4: Book Session with Wallet (Sufficient Balance)
**Steps:**
1. Ensure wallet has at least 300 ETB
2. Go to "Find Tutors" screen
3. Select a tutor
4. Choose time slot and session details
5. Tap "Book Session" button
6. Payment method dialog appears
7. Check wallet balance display
8. Tap "Pay with Wallet"

**Expected Result:**
- ✅ Payment dialog shows current balance
- ✅ Wallet option is enabled (not grayed out)
- ✅ Booking creates successfully
- ✅ Success dialog appears with payment details
- ✅ Shows "Amount: 300.00 ETB, Method: Wallet, Status: Paid"
- ✅ Redirects to bookings screen
- ✅ Balance deducted (1000 - 300 = 700 ETB)
- ✅ Escrow balance increases by 300 ETB

**Console Logs to Check:**
```
🔍 Creating booking with wallet payment
✅ Booking created: [booking_id]
💰 Processing wallet payment...
✅ Wallet payment successful!
```

---

### Test 5: Book Session with Insufficient Balance
**Steps:**
1. Ensure wallet has less than session cost (e.g., 100 ETB)
2. Try to book a 300 ETB session
3. Tap "Book Session" button
4. Payment method dialog appears

**Expected Result:**
- ✅ Wallet balance shows in red: "100.00 ETB"
- ✅ Wallet option is disabled (grayed out)
- ✅ Shows "Insufficient balance" subtitle
- ✅ "Add Money to Wallet" button appears at bottom
- ✅ Chapa option is still enabled
- ✅ Can tap "Add Money" to top-up
- ✅ Can tap "Pay with Chapa" to pay directly

---

### Test 6: View Transaction History
**Steps:**
1. Open wallet screen
2. Tap "History" button
3. View all transactions

**Expected Result:**
- ✅ Shows all transactions in chronological order
- ✅ Top-ups show with green color and + icon
- ✅ Payments show with red color and - icon
- ✅ Each transaction shows:
  - Description
  - Amount
  - Date
  - Type icon
- ✅ Can filter by type (if implemented)

**Sample Transactions:**
```
+ Wallet Top-up          +1000.00 ETB
- Booking Payment        -300.00 ETB
+ Refund                 +300.00 ETB
```

---

### Test 7: Escrow Display
**Steps:**
1. Book a session with wallet (money goes to escrow)
2. Open profile screen
3. Check wallet balance card

**Expected Result:**
- ✅ Shows "Available Balance: 700.00 ETB"
- ✅ Shows "In Escrow: 300.00 ETB" with lock icon
- ✅ Escrow section has semi-transparent background

---

### Test 8: Refund to Wallet
**Steps:**
1. Book a session with wallet
2. Cancel the booking (before 24 hours)
3. Check wallet balance

**Expected Result:**
- ✅ Refund processes automatically
- ✅ Money returns to wallet immediately
- ✅ Balance increases by refund amount
- ✅ Transaction shows in history as "Refund"
- ✅ Escrow balance decreases

---

### Test 9: Pull to Refresh
**Steps:**
1. Open wallet screen
2. Pull down to refresh
3. Wait for refresh to complete

**Expected Result:**
- ✅ Shows loading indicator
- ✅ Reloads balance
- ✅ Reloads recent transactions
- ✅ Updates UI with latest data

---

### Test 10: Navigation Flow
**Steps:**
1. Profile → Wallet Card → Wallet Screen
2. Wallet Screen → Add Money → Add Balance Screen
3. Wallet Screen → History → Transaction History Screen
4. Booking → Payment Dialog → Add Money → Add Balance Screen

**Expected Result:**
- ✅ All navigation works smoothly
- ✅ Back button works correctly
- ✅ No navigation errors
- ✅ Proper screen transitions

---

## 🎯 Quick Test Checklist

### Profile Screen
- [ ] Wallet card displays
- [ ] Balance loads correctly
- [ ] Escrow shows when > 0
- [ ] Card is clickable
- [ ] "My Wallet" button works

### Wallet Screen
- [ ] Balance displays correctly
- [ ] Action buttons work
- [ ] Recent transactions load
- [ ] Pull to refresh works
- [ ] Empty state shows correctly

### Add Balance Screen
- [ ] Amount input works
- [ ] Quick amounts work
- [ ] Chapa redirect works
- [ ] Balance updates after payment

### Booking Screen
- [ ] Payment dialog appears
- [ ] Wallet balance shows
- [ ] Wallet option enabled/disabled correctly
- [ ] Wallet payment works
- [ ] Success dialog shows
- [ ] Chapa payment still works

### Transaction History
- [ ] All transactions display
- [ ] Colors correct (green/red)
- [ ] Dates formatted correctly
- [ ] Transaction details correct

---

## 🐛 Common Issues & Solutions

### Issue 1: Wallet Balance Not Loading
**Symptoms:** Shows 0.00 ETB or loading forever

**Solutions:**
1. Check internet connection
2. Verify backend is running
3. Check console for API errors
4. Try pull to refresh
5. Restart app

### Issue 2: Payment Dialog Not Showing
**Symptoms:** "Book Session" button doesn't show dialog

**Solutions:**
1. Ensure you completed all booking steps
2. Check if slot is selected
3. Check if session type is selected
4. Look for console errors

### Issue 3: Wallet Payment Fails
**Symptoms:** Error message after selecting wallet payment

**Solutions:**
1. Verify sufficient balance
2. Check backend logs
3. Verify booking was created
4. Check wallet service API calls

### Issue 4: Balance Not Updating After Top-Up
**Symptoms:** Paid via Chapa but balance still 0

**Solutions:**
1. Wait 5-10 seconds for webhook
2. Pull to refresh wallet screen
3. Check transaction history
4. Verify Chapa webhook is configured
5. Check backend logs for webhook

### Issue 5: Escrow Not Showing
**Symptoms:** Paid booking but no escrow balance

**Solutions:**
1. Verify booking status is "confirmed"
2. Check if payment was successful
3. Refresh wallet screen
4. Check backend escrow service

---

## 📊 Expected Console Logs

### Successful Wallet Payment
```
🔍 Loading slots for tutorId: [tutor_id]
📅 Date range: [start] to [end]
📥 Response success: true
📊 Total slots received: 5
✅ Available slots after filtering: 3

🔍 Creating booking with wallet payment:
  - Total Amount: 300.0 ETB
  - Wallet Balance: 1000.0 ETB

✅ Booking created: [booking_id]
💰 Processing wallet payment...
✅ Wallet payment successful!
```

### Successful Top-Up
```
💰 Initializing top-up: 1000.0 ETB
✅ Top-up initialized
🔗 Redirecting to Chapa...
✅ Payment successful
🔄 Updating balance...
✅ Balance updated: 1000.0 ETB
```

---

## 🎉 Success Criteria

Your wallet system is working correctly if:

✅ Wallet balance displays on profile screen
✅ Can add money via Chapa
✅ Balance updates after top-up
✅ Can pay bookings with wallet
✅ Insufficient balance is handled correctly
✅ Escrow balance displays correctly
✅ Transaction history shows all transactions
✅ Refunds return to wallet
✅ Navigation works smoothly
✅ No console errors

---

## 📞 Need Help?

If you encounter issues:
1. Check console logs first
2. Verify backend is running
3. Check network connectivity
4. Review error messages
5. Test with different amounts
6. Try on different devices

---

## 🎯 Next Steps After Testing

Once all tests pass:
1. Test on real device (not just emulator)
2. Test with multiple users
3. Test edge cases (network errors, etc.)
4. Test concurrent bookings
5. Test refund scenarios
6. Monitor backend logs
7. Gather user feedback

---

**Testing Date**: February 6, 2026
**Status**: Ready for Testing
**Estimated Testing Time**: 30-45 minutes

Good luck with testing! 🚀
