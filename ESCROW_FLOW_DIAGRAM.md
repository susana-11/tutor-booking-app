# 🔄 Escrow System Flow Diagram

## 📊 Complete Payment & Escrow Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BOOKING & PAYMENT FLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

STEP 1: BOOKING CREATION
┌─────────┐
│ Student │ ──[Book Session]──> ┌───────┐
└─────────┘                      │ Tutor │
                                 └───────┘
                                     │
                                     ▼
                              [Accept/Decline]
                                     │
                                     ▼
                            ┌─────────────────┐
                            │ Booking Created │
                            │ Status: pending │
                            └─────────────────┘


STEP 2: PAYMENT PROCESSING
┌─────────┐
│ Student │ ──[Pay ETB 500]──> ┌──────────────┐
└─────────┘                     │ Chapa Gateway│
                                └──────────────┘
                                       │
                                       ▼
                              [Payment Verified]
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │   ESCROW HELD       │
                            │ Status: 'held'      │
                            │ Amount: ETB 425     │
                            │ (after 15% fee)     │
                            └─────────────────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │ Tutor Balance       │
                            │ Pending: +ETB 425   │
                            │ Available: unchanged│
                            └─────────────────────┘
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │ Booking Confirmed   │
                            │ Status: 'confirmed' │
                            └─────────────────────┘


STEP 3: SESSION COMPLETION
┌─────────┐                    ┌───────┐
│ Student │ ──[Join Session]── │ Tutor │
└─────────┘                    └───────┘
     │                              │
     └──────────[Session]───────────┘
                  │
                  ▼
         [Session Completed]
                  │
                  ▼
      ┌─────────────────────────┐
      │ Booking Status:         │
      │ 'completed'             │
      │                         │
      │ Escrow Release          │
      │ Scheduled For:          │
      │ Current Time + 1 hour   │
      └─────────────────────────┘


STEP 4: AUTOMATIC RELEASE (After 1 Hour)
         ┌──────────────┐
         │   Scheduler  │
         │ (Every 10min)│
         └──────────────┘
                │
                ▼
      [Check Release Time]
                │
                ▼
         [Time Reached?]
                │
            Yes │
                ▼
      ┌─────────────────────┐
      │  ESCROW RELEASED    │
      │ Status: 'released'  │
      └─────────────────────┘
                │
                ▼
      ┌─────────────────────┐
      │ Tutor Balance       │
      │ Pending: -ETB 425   │
      │ Available: +ETB 425 │
      └─────────────────────┘
                │
                ▼
      ┌─────────────────────┐
      │ Notification Sent   │
      │ "Payment Received"  │
      └─────────────────────┘
```

---

## 🚫 Cancellation Flow with Refund Rules

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      CANCELLATION SCENARIOS                             │
└─────────────────────────────────────────────────────────────────────────┘

SCENARIO A: EARLY CANCELLATION (24+ Hours Before)
┌─────────┐
│ Student │ ──[Cancel 48h before]──> ┌─────────────────┐
└─────────┘                           │ Calculate Refund│
                                      └─────────────────┘
                                              │
                                              ▼
                                    [Hours Until: 48]
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Refund: 100%     │
                                    │ ETB 500 → Student│
                                    │ ETB 0 → Tutor    │
                                    └──────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Escrow: refunded │
                                    │ Tutor Pending:   │
                                    │ -ETB 425         │
                                    └──────────────────┘


SCENARIO B: LATE CANCELLATION (12-24 Hours Before)
┌─────────┐
│ Student │ ──[Cancel 18h before]──> ┌─────────────────┐
└─────────┘                           │ Calculate Refund│
                                      └─────────────────┘
                                              │
                                              ▼
                                    [Hours Until: 18]
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Refund: 50%      │
                                    │ ETB 250 → Student│
                                    │ ETB 212.5→ Tutor │
                                    └──────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Escrow: refunded │
                                    │ Tutor Pending:   │
                                    │ -ETB 212.5       │
                                    │ Tutor Available: │
                                    │ +ETB 212.5       │
                                    └──────────────────┘


SCENARIO C: VERY LATE CANCELLATION (<12 Hours Before)
┌─────────┐
│ Student │ ──[Cancel 6h before]──> ┌─────────────────┐
└─────────┘                          │ Calculate Refund│
                                     └─────────────────┘
                                              │
                                              ▼
                                    [Hours Until: 6]
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Refund: 0%       │
                                    │ ETB 0 → Student  │
                                    │ ETB 425 → Tutor  │
                                    └──────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ Escrow: refunded │
                                    │ Tutor Pending:   │
                                    │ -ETB 425         │
                                    │ Tutor Available: │
                                    │ +ETB 425         │
                                    └──────────────────┘
```

---

## 💰 Tutor Balance Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        TUTOR BALANCE STATES                             │
└─────────────────────────────────────────────────────────────────────────┘

INITIAL STATE
┌──────────────────────┐
│ Tutor Balance        │
│ Total: ETB 0         │
│ Available: ETB 0     │
│ Pending: ETB 0       │
│ Withdrawn: ETB 0     │
└──────────────────────┘


AFTER PAYMENT (Escrow Held)
┌──────────────────────┐
│ Tutor Balance        │
│ Total: ETB 425       │
│ Available: ETB 0     │ ← Cannot withdraw yet
│ Pending: ETB 425     │ ← Held in escrow
│ Withdrawn: ETB 0     │
└──────────────────────┘


AFTER ESCROW RELEASE
┌──────────────────────┐
│ Tutor Balance        │
│ Total: ETB 425       │
│ Available: ETB 425   │ ← Can withdraw now!
│ Pending: ETB 0       │
│ Withdrawn: ETB 0     │
└──────────────────────┘


AFTER WITHDRAWAL
┌──────────────────────┐
│ Tutor Balance        │
│ Total: ETB 425       │
│ Available: ETB 0     │
│ Pending: ETB 0       │
│ Withdrawn: ETB 425   │ ← Money in bank
└──────────────────────┘
```

---

## ⏰ Timeline Visualization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    1-HOUR RELEASE TIMELINE                              │
└─────────────────────────────────────────────────────────────────────────┘

T+0min   │ Session Completed
         │ ✅ Escrow release scheduled for T+60min
         │
T+10min  │ 🔄 Scheduler Check #1
         │ ⏳ Not yet time (50 minutes remaining)
         │
T+20min  │ 🔄 Scheduler Check #2
         │ ⏳ Not yet time (40 minutes remaining)
         │
T+30min  │ 🔄 Scheduler Check #3
         │ ⏳ Not yet time (30 minutes remaining)
         │
T+40min  │ 🔄 Scheduler Check #4
         │ ⏳ Not yet time (20 minutes remaining)
         │
T+50min  │ 🔄 Scheduler Check #5
         │ ⏳ Not yet time (10 minutes remaining)
         │
T+60min  │ 🔄 Scheduler Check #6
         │ ✅ Time reached! Processing release...
         │ 💰 Escrow released: ETB 425 to tutor
         │ 🔔 Notification sent
         │
T+70min  │ 🔄 Scheduler Check #7
         │ ✅ Already released (skipped)
```

---

## 🔐 Security & State Management

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      ESCROW STATE MACHINE                               │
└─────────────────────────────────────────────────────────────────────────┘

                    ┌──────────┐
                    │   none   │ (No payment)
                    └──────────┘
                         │
                         │ [Payment Completed]
                         ▼
                    ┌──────────┐
                    │   held   │ (Escrow Active)
                    └──────────┘
                         │
                         ├─────────────────┐
                         │                 │
         [Session        │                 │ [Booking
          Completed]     │                 │  Cancelled]
                         │                 │
                         ▼                 ▼
                  ┌──────────┐      ┌──────────┐
                  │ released │      │ refunded │
                  └──────────┘      └──────────┘
                  (Final State)     (Final State)


STATE TRANSITIONS:
• none → held: Payment completed
• held → released: Session completed + time delay
• held → refunded: Booking cancelled
• released: Cannot change (final)
• refunded: Cannot change (final)
```

---

## 📊 Refund Calculation Logic

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    REFUND DECISION TREE                                 │
└─────────────────────────────────────────────────────────────────────────┘

                    [Cancellation Request]
                            │
                            ▼
                [Calculate Hours Until Session]
                            │
                            ▼
                    ┌───────────────┐
                    │ Hours >= 24?  │
                    └───────────────┘
                       │         │
                   Yes │         │ No
                       │         │
                       ▼         ▼
              ┌──────────┐  ┌───────────────┐
              │ 100%     │  │ Hours >= 12?  │
              │ Refund   │  └───────────────┘
              └──────────┘     │         │
                           Yes │         │ No
                               │         │
                               ▼         ▼
                          ┌──────────┐  ┌──────────┐
                          │ 50%      │  │ 0%       │
                          │ Refund   │  │ Refund   │
                          └──────────┘  └──────────┘


REFUND AMOUNTS (Example: ETB 500 booking):
┌──────────────┬──────────┬──────────┬──────────┐
│ Hours Before │ Student  │ Tutor    │ Platform │
├──────────────┼──────────┼──────────┼──────────┤
│ 24+          │ ETB 500  │ ETB 0    │ ETB 0    │
│ 12-24        │ ETB 250  │ ETB 212.5│ ETB 37.5 │
│ <12          │ ETB 0    │ ETB 425  │ ETB 75   │
└──────────────┴──────────┴──────────┴──────────┘
```

---

## 🎯 Key Points

1. **Payment Flow**: Student pays → Escrow held → Tutor pending balance
2. **Release Flow**: Session completes → Scheduled → Automatic release → Tutor available balance
3. **Cancellation**: Time-based refund rules (100%, 50%, 0%)
4. **Security**: All state transitions logged and auditable
5. **Automation**: Scheduler runs every 10 minutes (configurable)
6. **Notifications**: Both parties notified at each step
7. **Balance Management**: Pending vs Available separation for security
8. **Configurable**: All timings and percentages via environment variables

---

## ✅ Success Indicators

- ✅ Escrow held immediately after payment
- ✅ Tutor cannot withdraw until release
- ✅ Automatic release after configured delay
- ✅ Fair refund rules based on timing
- ✅ Partial refunds handled correctly
- ✅ All state transitions tracked
- ✅ Comprehensive notifications
- ✅ Admin oversight capability
