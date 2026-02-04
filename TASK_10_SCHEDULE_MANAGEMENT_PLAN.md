# 🗓️ TASK 10: Schedule Management with Real-World Logic

## 📋 Overview

Implement comprehensive schedule management for tutors with real-world logic that considers student bookings when performing actions like:
- Make Unavailable
- Edit Time Slot  
- Delete Slot

## 🎯 Real-World Scenarios & Logic

### Scenario 1: Make Unavailable

**When slot is AVAILABLE (not booked):**
- ✅ Allow: Simply mark as unavailable
- Result: Slot hidden from students

**When slot is BOOKED (pending):**
- ⚠️ Warning: "This slot has a pending booking request"
- Options:
  1. Cancel booking and make unavailable
  2. Keep booking and don't change
- If cancelled: Notify student, refund if paid

**When slot is BOOKED (confirmed):**
- ❌ Block: "Cannot make unavailable - confirmed booking exists"
- Reason: Student has paid and confirmed
- Alternative: Must cancel booking first (with proper notice/refund)

---

### Scenario 2: Edit Time Slot

**When slot is AVAILABLE (not booked):**
- ✅ Allow: Edit freely
- Validation: New time must not overlap with existing slots

**When slot is BOOKED (pending):**
- ⚠️ Warning: "This will affect a pending booking request"
- Options:
  1. Edit and notify student of time change
  2. Cancel booking and edit
  3. Keep original time

**When slot is BOOKED (confirmed):**
- ❌ Block: "Cannot edit - confirmed booking exists"
- Reason: Student has confirmed and may have made plans
- Alternative: Use reschedule request system instead
- Exception: Can edit if more than 48 hours before session

---

### Scenario 3: Delete Slot

**When slot is AVAILABLE (not booked):**
- ✅ Allow: Delete with confirmation
- Warning: "Are you sure? This cannot be undone"

**When slot is BOOKED (pending):**
- ⚠️ Warning: "This slot has a pending booking"
- Options:
  1. Decline booking and delete slot
  2. Keep slot

**When slot is BOOKED (confirmed):**
- ❌ Block: "Cannot delete - confirmed booking exists"
- Reason: Student has paid and confirmed
- Alternative: Must cancel booking first
- Policy: Cancellation may incur penalties based on timing

---

## 🔄 Implementation Strategy

### Backend Enhancements

1. **Add new endpoint: Toggle Availability**
   ```
   PUT /api/availability/slots/:slotId/toggle-availability
   ```
   - Checks booking status
   - Returns appropriate warnings/errors
   - Handles booking cancellation if requested

2. **Enhance Update Endpoint**
   - Add booking status checks
   - Return warnings for booked slots
   - Implement time-based restrictions

3. **Enhance Delete Endpoint**
   - Already has basic checks
   - Add more detailed error messages
   - Add option to force-delete with booking cancellation

### Mobile App Enhancements

1. **Smart Menu Options**
   - Show/hide options based on slot status
   - Different labels for different states
   - Warning dialogs before destructive actions

2. **Confirmation Dialogs**
   - Multi-step confirmations for booked slots
   - Clear explanation of consequences
   - Option to notify student

3. **Error Handling**
   - User-friendly error messages
   - Suggest alternatives
   - Guide user to proper action

---

## 📱 UI/UX Flow

### Make Unavailable Flow

```
User clicks "Make Unavailable"
  ↓
Check slot status
  ↓
IF Available:
  → Confirm dialog
  → Mark unavailable
  → Success message
  
IF Pending Booking:
  → Warning dialog with options:
    - "Cancel booking and make unavailable"
    - "Keep booking"
  → If cancel chosen:
    → Notify student
    → Process refund if needed
    → Mark unavailable
    
IF Confirmed Booking:
  → Error dialog:
    - "Cannot make unavailable"
    - "Confirmed booking exists"
    - "Cancel booking first or wait until after session"
  → Show "Cancel Booking" button
```

### Edit Time Slot Flow

```
User clicks "Edit Time Slot"
  ↓
Check slot status
  ↓
IF Available:
  → Show edit dialog
  → Validate new time
  → Save changes
  
IF Pending Booking:
  → Warning dialog:
    - "Pending booking will be affected"
    - Options:
      1. "Edit and notify student"
      2. "Cancel booking and edit"
      3. "Cancel"
      
IF Confirmed Booking:
  → Check time until session
  → IF < 48 hours:
    → Error: "Too close to session time"
    → Suggest: "Use reschedule request instead"
  → IF >= 48 hours:
    → Warning: "This will require student approval"
    → Redirect to reschedule request
```

### Delete Slot Flow

```
User clicks "Delete"
  ↓
Check slot status
  ↓
IF Available:
  → Confirmation dialog
  → Delete slot
  → Success message
  
IF Pending Booking:
  → Warning dialog:
    - "Pending booking exists"
    - Options:
      1. "Decline booking and delete"
      2. "Keep slot"
      
IF Confirmed Booking:
  → Error dialog:
    - "Cannot delete confirmed booking"
    - "Cancel booking first"
  → Show "Cancel Booking" button
  → Explain cancellation policy
```

---

## 🔔 Notifications

### When Tutor Makes Slot Unavailable (with pending booking):
```
To Student:
Title: "Booking Request Cancelled"
Body: "The tutor has made this time slot unavailable. Please choose another time."
```

### When Tutor Edits Time (with pending booking):
```
To Student:
Title: "Time Slot Changed"
Body: "The tutor changed the time to [new time]. Your booking request has been updated."
```

### When Tutor Deletes Slot (with pending booking):
```
To Student:
Title: "Booking Request Cancelled"
Body: "The tutor removed this time slot. Please book another available time."
```

---

## ⚖️ Business Rules

1. **Confirmed Bookings are Sacred**
   - Cannot be modified without student approval
   - Require proper cancellation process
   - Subject to refund policies

2. **Pending Bookings are Flexible**
   - Can be cancelled by tutor
   - Student gets full refund
   - Student notified immediately

3. **Time-Based Restrictions**
   - 48 hours before: Use reschedule system
   - 24 hours before: Cannot cancel without penalty
   - After session: Cannot modify

4. **Student Protection**
   - Always notify of changes
   - Automatic refunds when applicable
   - Clear communication of reasons

---

## 🧪 Test Scenarios

### Test 1: Make Unavailable - Available Slot
1. Create available slot
2. Click "Make Unavailable"
3. Confirm action
4. Verify slot marked unavailable
5. Verify not visible to students

### Test 2: Make Unavailable - Pending Booking
1. Create slot with pending booking
2. Click "Make Unavailable"
3. See warning about pending booking
4. Choose "Cancel booking and make unavailable"
5. Verify booking cancelled
6. Verify student notified
7. Verify slot unavailable

### Test 3: Make Unavailable - Confirmed Booking
1. Create slot with confirmed booking
2. Click "Make Unavailable"
3. See error message
4. Verify action blocked
5. See suggestion to cancel booking first

### Test 4: Edit Time - Available Slot
1. Create available slot
2. Click "Edit Time Slot"
3. Change time
4. Save changes
5. Verify time updated

### Test 5: Edit Time - Confirmed Booking (48+ hours)
1. Create confirmed booking 3 days away
2. Click "Edit Time Slot"
3. See message about reschedule system
4. Redirect to reschedule request

### Test 6: Delete - Confirmed Booking
1. Create confirmed booking
2. Click "Delete"
3. See error message
4. Verify deletion blocked
5. See cancel booking option

---

## 📊 Success Criteria

- [x] All menu actions functional
- [x] Real-world logic implemented
- [x] Student bookings protected
- [x] Proper notifications sent
- [x] Clear error messages
- [x] User-friendly dialogs
- [x] Cancellation policies enforced
- [x] Refunds processed correctly
- [x] Alternative actions suggested

---

## 🚀 Implementation Priority

1. **Phase 1: Backend Logic** (High Priority)
   - Enhance update/delete endpoints
   - Add toggle availability endpoint
   - Implement booking status checks

2. **Phase 2: Mobile UI** (High Priority)
   - Implement menu actions
   - Add confirmation dialogs
   - Handle all scenarios

3. **Phase 3: Notifications** (Medium Priority)
   - Send appropriate notifications
   - Handle refunds
   - Update booking statuses

4. **Phase 4: Testing** (High Priority)
   - Test all scenarios
   - Verify student protection
   - Check edge cases

---

This plan ensures a professional, real-world implementation that protects both tutors and students while providing flexibility where appropriate.
