# 🧪 Escrow System - Quick Test Guide

## 🎯 Quick Testing Steps

### Prerequisites
- Server running on `http://localhost:5000`
- Test accounts created (student and tutor)
- Booking with payment completed

---

## Test 1: Normal Session Flow (1-Hour Release)

### Step 1: Create and Pay for Booking
```bash
# Student books session and pays
# Payment held in escrow
# Check tutor pending balance increased
```

**Expected:**
- ✅ Booking status: `confirmed`
- ✅ Escrow status: `held`
- ✅ Tutor pending balance: +ETB 425 (or booking amount)
- ✅ Tutor available balance: unchanged

### Step 2: Complete Session
```bash
# Complete the session (either party)
# Escrow release scheduled for 1 hour from now
```

**Expected:**
- ✅ Booking status: `completed`
- ✅ Escrow `releaseScheduledFor`: current time + 1 hour
- ✅ Server log: "📅 Escrow release scheduled for: [timestamp]"

### Step 3: Wait for Automatic Release
```bash
# Wait 1 hour (or check server logs every 10 minutes)
# Scheduler will automatically release escrow
```

**Expected (after 1 hour):**
- ✅ Server log: "🔄 Running escrow release check..."
- ✅ Server log: "📦 Found 1 escrow releases to process"
- ✅ Server log: "✅ Released escrow for booking [id]"
- ✅ Server log: "💰 Escrow released: ETB 425 to tutor [id]"
- ✅ Escrow status: `released`
- ✅ Tutor pending balance: -ETB 425
- ✅ Tutor available balance: +ETB 425
- ✅ Tutor receives notification

---

## Test 2: Early Cancellation (100% Refund)

### Setup
```bash
# Book session for 48 hours from now
# Pay for booking
```

### Cancel Booking
```bash
POST /api/bookings/:bookingId/cancel
{
  "reason": "Schedule conflict"
}
```

**Expected:**
- ✅ Booking status: `cancelled`
- ✅ Refund: 100% (full amount)
- ✅ Server log: "💸 Escrow refunded: ETB 500 (100%) to student [id]"
- ✅ Student receives refund notification
- ✅ Tutor pending balance: -ETB 425
- ✅ Escrow status: `refunded`

---

## Test 3: Late Cancellation (50% Refund)

### Setup
```bash
# Book session for 18 hours from now
# Pay for booking
```

### Cancel Booking
```bash
POST /api/bookings/:bookingId/cancel
{
  "reason": "Emergency"
}
```

**Expected:**
- ✅ Booking status: `cancelled`
- ✅ Refund: 50% to student
- ✅ Release: 50% to tutor
- ✅ Server log: "💸 Escrow refunded: ETB 250 (50%) to student [id]"
- ✅ Server log: "Platform retained: ETB 250"
- ✅ Student receives partial refund notification
- ✅ Tutor receives partial payment notification
- ✅ Tutor pending balance: -ETB 212.50
- ✅ Tutor available balance: +ETB 212.50
- ✅ Escrow status: `refunded`

---

## Test 4: Very Late Cancellation (0% Refund)

### Setup
```bash
# Book session for 6 hours from now
# Pay for booking
```

### Cancel Booking
```bash
POST /api/bookings/:bookingId/cancel
{
  "reason": "Can't make it"
}
```

**Expected:**
- ✅ Booking status: `cancelled`
- ✅ Refund: 0% to student
- ✅ Release: 100% to tutor immediately
- ✅ Server log: "💸 Escrow refunded: ETB 0 (0%) to student [id]"
- ✅ Student receives "no refund" notification
- ✅ Tutor receives full payment notification
- ✅ Tutor pending balance: -ETB 425
- ✅ Tutor available balance: +ETB 425
- ✅ Escrow status: `refunded`

---

## 🔍 Monitoring Commands

### Check Server Logs
```bash
# Watch for escrow scheduler
tail -f server.log | grep "escrow"

# Expected every 10 minutes:
# 🔄 Running escrow release check...
# 📦 Found X escrow releases to process
```

### Check Tutor Balance
```bash
GET /api/tutors/balance
Authorization: Bearer <tutor_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "total": 5000,
    "available": 3000,
    "pending": 2000,
    "withdrawn": 0
  }
}
```

### Check Booking Escrow Status
```bash
GET /api/bookings/:bookingId
Authorization: Bearer <user_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "...",
    "status": "completed",
    "escrow": {
      "status": "held",
      "heldAt": "2026-02-04T10:00:00Z",
      "releaseScheduledFor": "2026-02-04T11:00:00Z",
      "autoReleaseEnabled": true,
      "releaseDelayHours": 1
    }
  }
}
```

---

## ⚙️ Configuration Testing

### Test 30-Minute Release
```env
# Update .env
ESCROW_RELEASE_DELAY_HOURS=0.5
ESCROW_SCHEDULER_FREQUENCY=5
```

```bash
# Restart server
npm start

# Complete session
# Wait 30 minutes
# Check if escrow released
```

### Test Custom Refund Rules
```env
# Update .env
ESCROW_REFUND_FULL_HOURS=48
ESCROW_REFUND_PARTIAL_HOURS=24
ESCROW_REFUND_PARTIAL_PERCENT=75
```

```bash
# Restart server
# Test cancellations at different times
# Verify refund percentages match configuration
```

---

## 🐛 Troubleshooting

### Escrow Not Releasing
**Check:**
1. Is scheduler running? (Look for "🔄 Running escrow release check..." in logs)
2. Is `releaseScheduledFor` in the past?
3. Is escrow status `held`?
4. Is booking status `completed`?
5. Is `autoReleaseEnabled` true?

**Fix:**
```bash
# Manually trigger release (admin)
POST /api/admin/escrow/release/:bookingId
{
  "reason": "Manual release for testing"
}
```

### Refund Not Processing
**Check:**
1. Is escrow status `held`?
2. Is payment status `paid`?
3. Check server logs for errors

**Fix:**
```bash
# Check booking details
GET /api/bookings/:bookingId

# Verify escrow status and payment status
```

### Scheduler Not Running
**Check:**
1. Server logs on startup
2. Look for "✅ Escrow scheduler started"

**Fix:**
```bash
# Restart server
npm start

# Verify configuration
# Check ESCROW_SCHEDULER_FREQUENCY in .env
```

---

## 📊 Expected Timeline

### 1-Hour Release Configuration
```
Session Completes → Release Scheduled (T+0)
    ↓
Wait 10 minutes → Scheduler Check #1 (T+10)
    ↓
Wait 10 minutes → Scheduler Check #2 (T+20)
    ↓
Wait 10 minutes → Scheduler Check #3 (T+30)
    ↓
Wait 10 minutes → Scheduler Check #4 (T+40)
    ↓
Wait 10 minutes → Scheduler Check #5 (T+50)
    ↓
Wait 10 minutes → Scheduler Check #6 (T+60)
    ↓
Escrow Released! ✅
```

### 30-Minute Release Configuration
```
Session Completes → Release Scheduled (T+0)
    ↓
Wait 5 minutes → Scheduler Check #1 (T+5)
    ↓
Wait 5 minutes → Scheduler Check #2 (T+10)
    ↓
Wait 5 minutes → Scheduler Check #3 (T+15)
    ↓
Wait 5 minutes → Scheduler Check #4 (T+20)
    ↓
Wait 5 minutes → Scheduler Check #5 (T+25)
    ↓
Wait 5 minutes → Scheduler Check #6 (T+30)
    ↓
Escrow Released! ✅
```

---

## ✅ Success Criteria

- [ ] Payment held in escrow after booking
- [ ] Tutor pending balance increases
- [ ] Session completion schedules release
- [ ] Scheduler runs every 10 minutes
- [ ] Escrow released after 1 hour
- [ ] Tutor available balance increases
- [ ] Notifications sent to tutor
- [ ] 100% refund for early cancellation (24+ hours)
- [ ] 50% refund for late cancellation (12-24 hours)
- [ ] 0% refund for very late cancellation (<12 hours)
- [ ] Partial payments released to tutor correctly
- [ ] All escrow states tracked properly

---

## 🎉 Quick Verification

```bash
# 1. Start server
cd server && npm start

# 2. Look for startup message
# ⚙️ Escrow Service Configuration: { ... }
# ✅ Escrow scheduler started (runs every 10 minutes)

# 3. Complete a session
# 📅 Escrow release scheduled for: [timestamp]

# 4. Wait and watch logs
# 🔄 Running escrow release check...
# ✅ Released escrow for booking [id]

# 5. Verify tutor balance updated
# GET /api/tutors/balance

# SUCCESS! 🚀
```
