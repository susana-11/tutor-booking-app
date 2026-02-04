# ✅ Reschedule Request/Approval System - COMPLETE

## Overview
Implemented a comprehensive reschedule request/approval system following real-world app patterns (like Uber, Airbnb). One party requests a reschedule, and the other party must approve or reject it before the booking is actually rescheduled.

---

## 🎯 Features Implemented

### Backend API (Node.js/Express)

#### 1. Request Reschedule Endpoint
**POST** `/api/bookings/:bookingId/reschedule/request`

**Request Body:**
```json
{
  "newDate": "2026-02-10T00:00:00.000Z",
  "newStartTime": "14:00",
  "newEndTime": "15:00",
  "reason": "I have a conflict at the original time"
}
```

**Features:**
- ✅ Validates booking exists and user is authorized
- ✅ Checks if booking can be rescheduled (must be 48+ hours before session)
- ✅ Prevents multiple pending reschedule requests
- ✅ Creates reschedule request with status 'pending'
- ✅ Sends high-priority notification to the other party
- ✅ Returns the created request with ID

**Response:**
```json
{
  "success": true,
  "message": "Reschedule request submitted successfully",
  "data": {
    "bookingId": "...",
    "rescheduleRequest": {
      "_id": "...",
      "requestedBy": "...",
      "requestedAt": "...",
      "newDate": "...",
      "newStartTime": "14:00",
      "newEndTime": "15:00",
      "reason": "...",
      "status": "pending"
    }
  }
}
```

#### 2. Respond to Reschedule Request Endpoint
**POST** `/api/bookings/:bookingId/reschedule/:requestId/respond`

**Request Body:**
```json
{
  "response": "accept"  // or "reject"
}
```

**Features:**
- ✅ Validates request exists and is still pending
- ✅ Ensures responder is not the requester (can't approve own request)
- ✅ Updates request status to 'accepted' or 'rejected'
- ✅ If accepted: Updates booking with new date/time, marks as rescheduled
- ✅ If accepted: Updates availability slot if exists
- ✅ Sends notification to requester about the response
- ✅ Returns updated booking details

**Response (Accept):**
```json
{
  "success": true,
  "message": "Reschedule request accepted successfully",
  "data": {
    "bookingId": "...",
    "rescheduleRequest": { ... },
    "newSessionDate": "2026-02-10T00:00:00.000Z",
    "newStartTime": "14:00",
    "newEndTime": "15:00"
  }
}
```

#### 3. Get Reschedule Requests Endpoint
**GET** `/api/bookings/:bookingId/reschedule/requests`

**Features:**
- ✅ Returns all reschedule requests for a booking
- ✅ Populates requester information
- ✅ Shows status (pending/accepted/rejected)

**Response:**
```json
{
  "success": true,
  "data": {
    "bookingId": "...",
    "rescheduleRequests": [
      {
        "_id": "...",
        "requestedBy": { "firstName": "John", "lastName": "Doe" },
        "requestedAt": "...",
        "newDate": "...",
        "newStartTime": "14:00",
        "newEndTime": "15:00",
        "reason": "...",
        "status": "pending",
        "respondedAt": null
      }
    ]
  }
}
```

---

### Mobile App (Flutter/Dart)

#### 1. Booking Service Methods

**Request Reschedule:**
```dart
Future<ApiResponse<Map<String, dynamic>>> rescheduleBooking({
  required String bookingId,
  required DateTime newDate,
  required String newStartTime,
  required String newEndTime,
  String? reason,
})
```

**Respond to Request:**
```dart
Future<ApiResponse<Map<String, dynamic>>> respondToRescheduleRequest({
  required String bookingId,
  required String requestId,
  required String response, // 'accept' or 'reject'
})
```

**Get Requests:**
```dart
Future<ApiResponse<List<Map<String, dynamic>>>> getRescheduleRequests(String bookingId)
```

#### 2. Reschedule Request Dialog Widget
**File:** `mobile_app/lib/core/widgets/reschedule_request_dialog.dart`

**Features:**
- ✅ Beautiful, professional UI matching app theme
- ✅ Shows current session date/time
- ✅ Date picker (minimum 48 hours ahead)
- ✅ Start time and end time pickers
- ✅ Optional reason text field
- ✅ Validates end time is after start time
- ✅ Info message explaining approval is required
- ✅ Loading state during submission
- ✅ Success/error feedback

**Usage:**
```dart
showDialog(
  context: context,
  builder: (context) => RescheduleRequestDialog(
    booking: booking,
    onSuccess: () => _loadBookings(),
  ),
);
```

#### 3. Reschedule Requests Dialog Widget
**File:** `mobile_app/lib/core/widgets/reschedule_requests_dialog.dart`

**Features:**
- ✅ Lists all reschedule requests for a booking
- ✅ Shows status badges (Pending/Accepted/Rejected)
- ✅ Displays requested date/time prominently
- ✅ Shows reason if provided
- ✅ Accept/Decline buttons for pending requests
- ✅ Response timestamp for completed requests
- ✅ Empty state when no requests exist
- ✅ Loading state while fetching
- ✅ Confirmation dialogs for actions

**Usage:**
```dart
showDialog(
  context: context,
  builder: (context) => RescheduleRequestsDialog(
    booking: booking,
    onSuccess: () => _loadBookings(),
  ),
);
```

#### 4. Integration in Booking Screens

**Student Bookings Screen:**
- ✅ "Reschedule" button opens request dialog
- ✅ "View Reschedule Requests" button shows all requests
- ✅ Available for confirmed bookings

**Tutor Bookings Screen:**
- ✅ "Reschedule" button opens request dialog
- ✅ "View Reschedule Requests" button shows all requests
- ✅ Available for confirmed bookings
- ✅ Can respond to student's reschedule requests

---

## 🔄 User Flow

### Scenario 1: Student Requests Reschedule

1. **Student** views confirmed booking
2. **Student** clicks "Reschedule" button
3. **Student** selects new date/time and provides reason
4. **Student** submits request
5. **System** creates pending reschedule request
6. **System** sends notification to tutor
7. **Tutor** receives notification
8. **Tutor** opens booking and clicks "View Reschedule Requests"
9. **Tutor** sees the request with new date/time and reason
10. **Tutor** clicks "Accept" or "Decline"
11. **System** updates request status
12. If accepted: **System** updates booking with new date/time
13. **System** sends notification to student about response
14. **Student** receives notification and sees updated booking

### Scenario 2: Tutor Requests Reschedule

1. **Tutor** views confirmed booking
2. **Tutor** clicks "Reschedule" button
3. **Tutor** selects new date/time and provides reason
4. **Tutor** submits request
5. **System** creates pending reschedule request
6. **System** sends notification to student
7. **Student** receives notification
8. **Student** opens booking and clicks "View Reschedule Requests"
9. **Student** sees the request with new date/time and reason
10. **Student** clicks "Accept" or "Decline"
11. **System** updates request status
12. If accepted: **System** updates booking with new date/time
13. **System** sends notification to tutor about response
14. **Tutor** receives notification and sees updated booking

---

## 🎨 UI/UX Features

### Request Dialog
- Clean, modern design with app theme colors
- Current session info displayed for reference
- Intuitive date/time pickers
- Optional reason field with helpful placeholder
- Info banner explaining approval process
- Responsive buttons with loading states
- Success/error feedback with snackbars

### Requests List Dialog
- Scrollable list of all requests
- Color-coded status badges (Orange=Pending, Green=Accepted, Red=Rejected)
- Prominent display of requested date/time
- Reason shown in separate container
- Action buttons only for pending requests
- Response timestamp for completed requests
- Empty state with helpful message
- Loading indicator while fetching

---

## 🔒 Security & Validation

### Backend Validation
- ✅ User must be participant in booking (student or tutor)
- ✅ Booking must be in valid status (pending or confirmed)
- ✅ Must be at least 48 hours before session (uses `canBeRescheduled` virtual)
- ✅ Only one pending request allowed at a time
- ✅ Responder cannot be the requester
- ✅ Request must be in pending status to respond

### Frontend Validation
- ✅ Date must be at least 48 hours in future
- ✅ End time must be after start time
- ✅ All required fields must be filled
- ✅ Loading states prevent double submissions
- ✅ Error handling with user-friendly messages

---

## 📱 Notifications

### Request Notification (High Priority)
```
Title: "Reschedule Request"
Body: "[Name] requested to reschedule your session to [Date] at [Time]"
Type: reschedule_request
Action: Opens bookings screen
```

### Accepted Notification (High Priority)
```
Title: "Reschedule Request Accepted ✅"
Body: "[Name] accepted your reschedule request. New session: [Date] at [Time]"
Type: reschedule_accepted
Action: Opens bookings screen
```

### Declined Notification (Normal Priority)
```
Title: "Reschedule Request Declined"
Body: "[Name] declined your reschedule request"
Type: reschedule_rejected
Action: Opens bookings screen
```

---

## 🗄️ Database Schema

### Booking Model - rescheduleRequests Array
```javascript
rescheduleRequests: [{
  requestedBy: ObjectId,        // User who requested
  requestedAt: Date,             // When requested
  newDate: Date,                 // Proposed new date
  newStartTime: String,          // Proposed start time (HH:MM)
  newEndTime: String,            // Proposed end time (HH:MM)
  reason: String,                // Optional reason
  status: {                      // Request status
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending'
  },
  respondedAt: Date              // When responded (if not pending)
}]
```

### Additional Booking Fields
```javascript
isRescheduled: Boolean,          // True if booking was rescheduled
originalBookingId: ObjectId      // Reference to original booking (if rescheduled)
```

---

## 🧪 Testing Guide

### Test Case 1: Student Requests Reschedule
1. Login as student
2. Go to "My Bookings" → "Upcoming" tab
3. Find a confirmed booking at least 48 hours away
4. Click "Reschedule" button
5. Select new date (at least 48 hours ahead)
6. Select new start and end times
7. Enter reason (optional)
8. Click "Send Request"
9. Verify success message
10. Login as tutor
11. Go to "My Bookings" → "Confirmed" tab
12. Find the same booking
13. Click "View Reschedule Requests"
14. Verify request is shown with correct details
15. Click "Accept"
16. Verify booking is updated with new date/time
17. Login back as student
18. Verify booking shows new date/time

### Test Case 2: Tutor Declines Reschedule
1. Login as tutor
2. Request reschedule for a confirmed booking
3. Login as student
4. View reschedule requests
5. Click "Decline"
6. Verify request status changes to "Rejected"
7. Verify booking date/time remains unchanged

### Test Case 3: Validation Tests
1. Try to reschedule a booking less than 48 hours away → Should fail
2. Try to reschedule a completed booking → Should fail
3. Try to reschedule a cancelled booking → Should fail
4. Try to submit request with end time before start time → Should fail
5. Try to respond to your own request → Should fail (backend)
6. Try to respond to already-responded request → Should fail

---

## 📊 Real-World Comparison

### Similar to Uber
- Request ride time change → Driver accepts/declines
- Clear communication of new time
- Notifications for both parties

### Similar to Airbnb
- Guest requests date change → Host accepts/declines
- Shows original and new dates side-by-side
- Reason field for context

### Similar to Calendly
- Reschedule request workflow
- Email notifications
- Clear status tracking

---

## 🚀 Deployment Checklist

- [x] Backend endpoints implemented
- [x] Routes configured
- [x] Booking model supports reschedule requests
- [x] Notification service integrated
- [x] Mobile service methods added
- [x] Request dialog widget created
- [x] Requests list dialog widget created
- [x] Student bookings screen integrated
- [x] Tutor bookings screen integrated
- [x] Validation implemented (frontend & backend)
- [x] Error handling implemented
- [x] Loading states implemented
- [x] Success/error feedback implemented

---

## 📝 API Routes Summary

```
POST   /api/bookings/:bookingId/reschedule/request
POST   /api/bookings/:bookingId/reschedule/:requestId/respond
GET    /api/bookings/:bookingId/reschedule/requests
```

---

## 🎉 Status: COMPLETE

The reschedule request/approval system is fully implemented and ready for testing. Both students and tutors can request reschedules, and the other party must approve before the booking is actually rescheduled. The system follows real-world app patterns with proper validation, notifications, and user feedback.

**Next Steps:**
1. Test the complete flow with real bookings
2. Verify notifications are sent correctly
3. Test edge cases (cancellation, multiple requests, etc.)
4. Deploy to production

---

## 💡 Future Enhancements (Optional)

- Add ability to propose alternative times when declining
- Add reschedule history/audit log
- Add automatic expiration of pending requests after X days
- Add reschedule fee/policy configuration
- Add bulk reschedule for recurring sessions
- Add calendar integration for availability checking
