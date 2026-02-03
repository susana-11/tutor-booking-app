# Chapa Payment - Quick Start Guide

## Prerequisites

Before you start, you need:
1. Chapa account (sign up at https://chapa.co)
2. Chapa Secret Key
3. Chapa Webhook Secret

## Step 1: Configure Chapa Keys

Update `server/.env` with your Chapa credentials:

```env
# Replace these with your actual Chapa keys
CHAPA_SECRET_KEY=CHASECK_TEST-xxxxxxxxxxxxxxxxxx
CHAPA_WEBHOOK_SECRET=your_webhook_secret_here

# These can stay as is for development
CHAPA_BASE_URL=https://api.chapa.co/v1
CHAPA_CALLBACK_URL=http://localhost:5000/api/payments/callback
CHAPA_RETURN_URL=http://localhost:5000/api/payments/success

# Platform settings (adjust as needed)
PLATFORM_FEE_PERCENTAGE=10
MIN_WITHDRAWAL_AMOUNT=100
```

## Step 2: Restart Server

```bash
cd server
npm start
```

The server will now use your Chapa credentials.

## Step 3: Test Payment Flow (Student Side)

### A. Create a Booking
1. Open mobile app as student
2. Find a tutor
3. Book a session
4. Note the booking ID

### B. Initialize Payment
The app will automatically:
1. Call `/api/payments/initialize` with booking ID
2. Receive Chapa checkout URL
3. Open payment page in browser

### C. Complete Payment
1. On Chapa payment page, enter test card details:
   - Card: Use Chapa test cards
   - Or use mobile money test numbers
2. Complete payment
3. You'll be redirected back to app

### D. Verify Payment
The system automatically:
1. Receives webhook from Chapa
2. Verifies payment
3. Updates booking status to "confirmed"
4. Adds funds to tutor balance

## Step 4: Test Withdrawal Flow (Tutor Side)

### A. Set Up Bank Account
1. Open mobile app as tutor
2. Go to Earnings screen
3. Tap "Bank Account"
4. Enter:
   - Account Number
   - Account Name
   - Bank Name
5. Save

### B. Check Balance
In Earnings screen, you'll see:
- **Available**: Funds ready to withdraw
- **Pending**: Funds from unconfirmed bookings
- **Total**: Total earned all-time
- **Withdrawn**: Total withdrawn

### C. Request Withdrawal
1. Tap "Withdraw Funds" button
2. Enter amount (minimum ETB 100)
3. Review fee calculation:
   - Amount: ETB 1000
   - Platform Fee (10%): -ETB 100
   - You receive: ETB 900
4. Confirm withdrawal
5. Check transaction history

## Step 5: Verify Everything Works

### Check Database
```javascript
// In MongoDB, check:

// 1. Transaction created
db.transactions.find({ type: 'payment' })

// 2. Tutor balance updated
db.tutorprofiles.findOne({ userId: TUTOR_USER_ID })
// Should show balance.available > 0

// 3. Booking confirmed
db.bookings.findOne({ _id: BOOKING_ID })
// Should show payment.status: 'paid'
```

### Check Server Logs
```bash
# Look for:
✓ Payment initialized: booking_xxxxx
✓ Payment verified: booking_xxxxx
✓ Tutor balance updated: +1000 ETB
✓ Withdrawal processed: -1000 ETB
```

## Common Issues & Solutions

### Issue 1: "Payment initialization failed"
**Solution**: Check Chapa secret key in `.env`

### Issue 2: "Webhook signature invalid"
**Solution**: Verify webhook secret matches Chapa dashboard

### Issue 3: "Insufficient balance"
**Solution**: Ensure payment was completed and verified

### Issue 4: "Bank account not set up"
**Solution**: Add bank account details in app first

### Issue 5: "Minimum withdrawal is ETB 100"
**Solution**: Withdraw at least ETB 100

## Testing with Chapa Test Mode

### Test Cards (Chapa Sandbox)
```
Success Card:
Number: 4200 0000 0000 0000
CVV: 123
Expiry: Any future date

Decline Card:
Number: 4100 0000 0000 0000
CVV: 123
Expiry: Any future date
```

### Test Mobile Money
Use Chapa test phone numbers from their documentation.

## API Testing with Postman/cURL

### 1. Initialize Payment
```bash
curl -X POST http://localhost:5000/api/payments/initialize \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "65abc123def456789"
  }'
```

Response:
```json
{
  "success": true,
  "message": "Payment initialized successfully",
  "data": {
    "checkoutUrl": "https://checkout.chapa.co/checkout/payment/xxxxx",
    "reference": "booking_1738483200_abc123",
    "amount": 1000
  }
}
```

### 2. Verify Payment
```bash
curl http://localhost:5000/api/payments/verify/booking_1738483200_abc123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Get Balance
```bash
curl http://localhost:5000/api/withdrawals/balance \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Response:
```json
{
  "success": true,
  "data": {
    "available": 1000,
    "pending": 0,
    "total": 1000,
    "withdrawn": 0
  }
}
```

### 4. Request Withdrawal
```bash
curl -X POST http://localhost:5000/api/withdrawals/request \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 500
  }'
```

Response:
```json
{
  "success": true,
  "message": "Withdrawal processed successfully",
  "data": {
    "transactionId": "65abc...",
    "amount": 500,
    "fee": 50,
    "netAmount": 450,
    "status": "completed"
  }
}
```

## Webhook Testing

### Set Up Webhook URL in Chapa Dashboard
```
https://your-domain.com/api/payments/webhook
```

For local testing, use ngrok:
```bash
ngrok http 5000
# Use the ngrok URL in Chapa dashboard
```

### Test Webhook Manually
```bash
curl -X POST http://localhost:5000/api/payments/webhook \
  -H "Content-Type: application/json" \
  -H "chapa-signature: YOUR_SIGNATURE" \
  -d '{
    "event": "charge.success",
    "data": {
      "reference": "booking_1738483200_abc123",
      "amount": "1000",
      "status": "success",
      "trx_ref": "CHW-xxxxx"
    }
  }'
```

## Production Checklist

Before going live:

- [ ] Replace test Chapa keys with production keys
- [ ] Update callback URLs to production domain
- [ ] Set up webhook URL in Chapa dashboard
- [ ] Test with real payment (small amount)
- [ ] Verify webhook reception
- [ ] Test withdrawal flow
- [ ] Set up bank transfer integration (replace mock)
- [ ] Configure minimum withdrawal amount
- [ ] Set platform fee percentage
- [ ] Add monitoring and alerts
- [ ] Test refund flow
- [ ] Document support procedures

## Support Resources

- **Chapa Documentation**: https://developer.chapa.co
- **Chapa Dashboard**: https://dashboard.chapa.co
- **Chapa Support**: support@chapa.co

## Next Steps

1. ✅ Configure Chapa keys
2. ✅ Test payment flow
3. ✅ Test withdrawal flow
4. ⏳ Integrate real bank transfer API
5. ⏳ Add payment analytics
6. ⏳ Implement refund system

---

**Ready to test!** Start with Step 1 above.
