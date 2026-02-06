# Student Reschedule Request Guide

## ✅ Feature Already Implemented!

The student can accept or decline reschedule requests. Here's how it works:

## How Students See and Respond to Reschedule Requests

### 1. Notification Banner
When a tutor sends a reschedule request, the student sees an **orange banner** on the booking card that says:
```
"You have pending reschedule requests"
[View Button]
```

### 2. View Reschedule Requests
When the student clicks the **"View"** button, a dialog opens showing:

**For Each Request:**
- Status badge (PENDING, ACCEPTED, or REJECTED)
- New requested date and time
- Reason for rescheduling (if provided)
- Request timestamp

### 3. Accept or Decline
For **pending requests**, the student sees two buttons:
- **Decline** (red button with X icon)
- **Accept** (green button with checkmark icon)

### 4. After Responding
- **If Accepted:** 
  - Booking is updated with new date/time
  - Success message: "✅ Reschedule request accepted"
  - Booking list refreshes automatically
  
- **If Declined:**
  - Request is marked as rejected
  - Message: "Reschedule request declined"
  - Original booking time remains unchanged

## User Experience Details

### For the Requester (Tutor)
When viewing their own request, they see:
- Status: PENDING
- Message: "Waiting for the other party to respond"
- No action buttons (can't respond to own request)

### For the Responder (Student)
When viewing a request from the tutor, they see:
- Status: PENDING
- Accept and Decline buttons
- Can respond immediately

### After Response
Both parties see:
- Updated status (ACCEPTED or REJECTED)
- Response timestamp
- Icon indicating the outcome

## Where to Find It

### Student Side:
1. Open app as student
2. Go to **"My Bookings"** tab
3. Look for bookings with the orange banner
4. Click **"View"** button on the banner
5. See all reschedule requests
6. Click **Accept** or **Decline**

### Tutor Side:
1. Open app as tutor
2. Go to **"My Bookings"** tab
3. Click on a booking
4. Click **"View Reschedule Requests"**
5. See status of their requests

## Technical Implementation

### Files Involved:
- `mobile_app/lib/features/student/screens/student_bookings_screen.dart`
  - Shows the orange banner
  - Calls `_viewRescheduleRequests()` method
  
- `mobile_app/lib/core/widgets/reschedule_requests_dialog.dart`
  - Displays all requests
  - Handles accept/decline actions
  - Shows appropriate UI based on user role

- `mobile_app/lib/core/services/booking_service.dart`
  - `getRescheduleRequests()` - Fetches requests
  - `respondToRescheduleRequest()` - Sends accept/decline response

### Backend API:
- `GET /api/bookings/:bookingId/reschedule/requests` - Get all requests
- `POST /api/bookings/:bookingId/reschedule/:requestId/respond` - Accept or decline

## Testing

### Test Scenario:
1. **As Tutor:**
   - Create a reschedule request for a confirmed booking
   - Add a reason like "Need to move session earlier"
   
2. **As Student:**
   - Refresh bookings screen
   - See orange banner on the booking
   - Click "View" button
   - See the reschedule request with new date/time
   - Click "Accept" or "Decline"
   
3. **Verify:**
   - If accepted: Booking date/time updates
   - If declined: Original booking remains unchanged
   - Both parties see the updated status

## Screenshots Reference

### Orange Banner (Student View):
```
┌─────────────────────────────────────┐
│ [Tutor Name]              [Status]  │
│ Subject                              │
│ ┌─────────────────────────────────┐ │
│ │ 🔔 You have pending reschedule  │ │
│ │    requests            [View]   │ │
│ └─────────────────────────────────┘ │
│ [Start Session] [Reschedule] [Cancel]│
└─────────────────────────────────────┘
```

### Reschedule Requests Dialog:
```
┌─────────────────────────────────────┐
│ 📅 Reschedule Requests         [X]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [PENDING]      Jan 15, 2:30 PM  │ │
│ │                                 │ │
│ │ Requested New Time:             │ │
│ │ 📅 Monday, January 20, 2026     │ │
│ │ 🕐 3:00 PM - 4:00 PM            │ │
│ │                                 │ │
│ │ Reason:                         │ │
│ │ Need to move session earlier    │ │
│ │                                 │ │
│ │ [Decline]          [Accept]     │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Summary

✅ **Feature is fully implemented and working!**
- Students receive notifications via orange banner
- Students can view all reschedule requests
- Students can accept or decline requests
- UI updates automatically after response
- Both parties see the outcome

The feature is production-ready and deployed!
