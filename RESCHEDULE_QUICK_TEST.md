# 🧪 Reschedule System - Quick Test Guide

## Prerequisites
- Server running on port 5000
- Mobile app connected to server
- At least 2 test accounts (1 student, 1 tutor)
- At least 1 confirmed booking scheduled 48+ hours in the future

---

## Test 1: Student Requests Reschedule (Happy Path)

### Step 1: Student Side
1. **Login** as student
2. **Navigate** to "My Bookings" screen
3. **Tap** "Upcoming" tab
4. **Find** a confirmed booking (must be 48+ hours away)
5. **Tap** "Reschedule" button
6. **Verify** dialog opens showing:
   - Current session date/time
   - Date picker
   - Start time picker
   - End time picker
   - Reason field
   - Info message about approval

### Step 2: Submit Request
1. **Tap** date field → Select date at least 2 days ahead
2. **Tap** start time → Select new start time (e.g., 2:00 PM)
3. **Tap** end time → Select new end time (e.g., 3:00 PM)
4. **Type** reason: "I have a doctor's appointment"
5. **Tap** "Send Request" button
6. **Verify** success message: "✅ Reschedule request sent successfully"
7. **Verify** dialog closes
8. **Verify** booking list refreshes

### Step 3: Tutor Side
1. **Login** as tutor (the one for this booking)
2. **Navigate** to "My Bookings" screen
3. **Tap** "Confirmed" tab
4. **Find** the same booking
5. **Tap** "View Reschedule Requests" button
6. **Verify** dialog opens showing:
   - Request with "PENDING" badge (orange)
   - Requested new date/time
   - Reason: "I have a doctor's appointment"
   - "Accept" and "Decline" buttons

### Step 4: Accept Request
1. **Tap** "Accept" button
2. **Verify** loading indicator appears
3. **Verify** success message: "✅ Reschedule request accepted"
4. **Verify** dialog closes
5. **Verify** booking now shows NEW date/time
6. **Verify** booking list refreshes

### Step 5: Student Verification
1. **Go back** to student account
2. **Navigate** to "My Bookings" → "Upcoming"
3. **Verify** booking shows NEW date/time
4. **Tap** "View Reschedule Requests"
5. **Verify** request shows "ACCEPTED" badge (green)
6. **Verify** response timestamp is shown

✅ **Expected Result:** Booking successfully rescheduled to new date/time

---

## Test 2: Tutor Declines Reschedule Request

### Step 1: Student Requests
1. **Login** as student
2. **Request** reschedule for another confirmed booking
3. **Submit** with reason: "Need to change time"

### Step 2: Tutor Declines
1. **Login** as tutor
2. **Navigate** to booking
3. **Tap** "View Reschedule Requests"
4. **Tap** "Decline" button
5. **Verify** success message
6. **Verify** dialog closes

### Step 3: Verify Booking Unchanged
1. **Verify** booking still shows ORIGINAL date/time
2. **Verify** request shows "REJECTED" badge (red)

### Step 4: Student Notification
1. **Go back** to student account
2. **Verify** booking still shows ORIGINAL date/time
3. **Tap** "View Reschedule Requests"
4. **Verify** request shows "REJECTED" badge

✅ **Expected Result:** Booking remains unchanged, request marked as rejected

---

## Test 3: Tutor Requests Reschedule

### Step 1: Tutor Requests
1. **Login** as tutor
2. **Navigate** to "My Bookings" → "Confirmed"
3. **Find** a confirmed booking
4. **Tap** "Reschedule" button
5. **Select** new date/time
6. **Enter** reason: "I have a conflict"
7. **Tap** "Send Request"
8. **Verify** success message

### Step 2: Student Responds
1. **Login** as student
2. **Navigate** to the booking
3. **Tap** "View Reschedule Requests"
4. **Verify** tutor's request is shown
5. **Tap** "Accept" or "Decline"
6. **Verify** appropriate action taken

✅ **Expected Result:** Tutor can request reschedule, student can respond

---

## Test 4: Validation Tests

### Test 4a: Cannot Reschedule Too Soon
1. **Find** a booking less than 48 hours away
2. **Tap** "Reschedule" button
3. **Try** to submit request
4. **Verify** error message: "Booking cannot be rescheduled (must be at least 48 hours before session)"

### Test 4b: End Time Before Start Time
1. **Open** reschedule dialog
2. **Select** start time: 3:00 PM
3. **Select** end time: 2:00 PM (before start)
4. **Tap** "Send Request"
5. **Verify** error message: "End time must be after start time"

### Test 4c: Multiple Pending Requests
1. **Submit** a reschedule request
2. **Try** to submit another request for same booking
3. **Verify** error message: "There is already a pending reschedule request for this booking"

✅ **Expected Result:** All validations work correctly

---

## Test 5: UI/UX Verification

### Request Dialog
- [ ] Dialog has proper title and close button
- [ ] Current session info is displayed
- [ ] Date picker opens calendar
- [ ] Time pickers show time selection
- [ ] Reason field accepts text input
- [ ] Info banner is visible and clear
- [ ] Buttons are properly styled
- [ ] Loading state shows during submission
- [ ] Success/error messages appear

### Requests List Dialog
- [ ] Dialog has proper title and close button
- [ ] Empty state shows when no requests
- [ ] Loading indicator shows while fetching
- [ ] Requests are displayed in cards
- [ ] Status badges are color-coded correctly
- [ ] Date/time is formatted nicely
- [ ] Reason is shown if provided
- [ ] Action buttons only show for pending requests
- [ ] Response timestamp shows for completed requests

---

## Test 6: Notification Verification

### Request Notification
1. **Submit** reschedule request
2. **Check** other party's notifications
3. **Verify** notification shows:
   - Title: "Reschedule Request"
   - Body includes requester name and new date/time
   - Tapping opens bookings screen

### Accepted Notification
1. **Accept** reschedule request
2. **Check** requester's notifications
3. **Verify** notification shows:
   - Title: "Reschedule Request Accepted ✅"
   - Body includes responder name and new date/time
   - Tapping opens bookings screen

### Declined Notification
1. **Decline** reschedule request
2. **Check** requester's notifications
3. **Verify** notification shows:
   - Title: "Reschedule Request Declined"
   - Body includes responder name
   - Tapping opens bookings screen

---

## Common Issues & Solutions

### Issue: "Booking not found"
**Solution:** Make sure you're using the correct booking ID and the booking exists

### Issue: "Not authorized to reschedule"
**Solution:** Verify you're logged in as either the student or tutor for this booking

### Issue: "Booking cannot be rescheduled"
**Solution:** Check that:
- Booking is at least 48 hours away
- Booking status is 'pending' or 'confirmed'
- Booking is not already completed or cancelled

### Issue: Dialog doesn't open
**Solution:** Check console for errors, verify imports are correct

### Issue: Request not showing in list
**Solution:** Refresh the bookings list, check network requests

---

## API Testing (Optional)

### Test Request Reschedule API
```bash
curl -X POST http://localhost:5000/api/bookings/{bookingId}/reschedule/request \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "newDate": "2026-02-10T00:00:00.000Z",
    "newStartTime": "14:00",
    "newEndTime": "15:00",
    "reason": "Test reason"
  }'
```

### Test Respond to Request API
```bash
curl -X POST http://localhost:5000/api/bookings/{bookingId}/reschedule/{requestId}/respond \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "response": "accept"
  }'
```

### Test Get Requests API
```bash
curl -X GET http://localhost:5000/api/bookings/{bookingId}/reschedule/requests \
  -H "Authorization: Bearer {token}"
```

---

## Success Criteria

- [x] Student can request reschedule
- [x] Tutor can request reschedule
- [x] Other party receives notification
- [x] Other party can view requests
- [x] Other party can accept request
- [x] Other party can decline request
- [x] Booking updates when accepted
- [x] Booking unchanged when declined
- [x] Validations work correctly
- [x] UI is intuitive and responsive
- [x] Notifications are sent properly
- [x] Error handling works
- [x] Loading states show correctly

---

## 🎉 Test Complete!

If all tests pass, the reschedule system is working correctly and ready for production use!
