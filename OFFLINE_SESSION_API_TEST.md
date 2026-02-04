# 🧪 Offline Session API - Testing Guide

## Quick Test Commands

### 1. Create In-Person Booking
```bash
POST http://localhost:5000/api/bookings
Headers: {
  "Authorization": "Bearer YOUR_TOKEN",
  "Content-Type": "application/json"
}
Body: {
  "tutorId": "TUTOR_USER_ID",
  "subjectId": "SUBJECT_ID",
  "sessionDate": "2024-02-05",
  "startTime": "14:00",
  "endTime": "15:00",
  "sessionType": "inPerson",
  "location": {
    "type": "public_place",
    "address": "123 Main St",
    "city": "Addis Ababa",
    "state": "Addis Ababa",
    "country": "Ethiopia",
    "coordinates": {
      "latitude": 9.0192,
      "longitude": 38.7525
    },
    "placeName": "Starbucks Downtown",
    "instructions": "Meet at the entrance"
  }
}
```

### 2. Student Check-In
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/check-in
Headers: {
  "Authorization": "Bearer STUDENT_TOKEN"
}
Body: {
  "location": {
    "latitude": 9.0192,
    "longitude": 38.7525
  }
}
```

### 3. Tutor Check-In
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/check-in
Headers: {
  "Authorization": "Bearer TUTOR_TOKEN"
}
Body: {
  "location": {
    "latitude": 9.0193,
    "longitude": 38.7526
  }
}
```

### 4. Get Check-In Status
```bash
GET http://localhost:5000/api/offline-sessions/BOOKING_ID/check-in-status
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
```

### 5. Notify Running Late
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/running-late
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
Body: {
  "estimatedArrival": "2024-02-05T14:15:00Z",
  "reason": "Traffic delay"
}
```

### 6. Student Check-Out
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/check-out
Headers: {
  "Authorization": "Bearer STUDENT_TOKEN"
}
```

### 7. Tutor Check-Out
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/check-out
Headers: {
  "Authorization": "Bearer TUTOR_TOKEN"
}
```

### 8. Report Safety Issue
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/report-issue
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
Body: {
  "issueType": "safety_concern",
  "description": "Uncomfortable situation at meeting location"
}
```

### 9. Share Session
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/share-session
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
Body: {
  "contacts": [
    {
      "name": "Emergency Contact",
      "phone": "+251911234567",
      "email": "emergency@example.com"
    }
  ]
}
```

### 10. Set Emergency Contact
```bash
POST http://localhost:5000/api/offline-sessions/BOOKING_ID/emergency-contact
Headers: {
  "Authorization": "Bearer YOUR_TOKEN"
}
Body: {
  "name": "John Doe",
  "phone": "+251911234567",
  "relationship": "Friend"
}
```

---

## Expected Responses

### Successful Check-In
```json
{
  "success": true,
  "message": "Checked in successfully",
  "data": {
    "checkIn": {
      "student": {
        "checkedIn": true,
        "checkedInAt": "2024-02-05T14:00:00Z",
        "location": {
          "latitude": 9.0192,
          "longitude": 38.7525
        },
        "verified": true,
        "distanceFromMeetingPoint": 15
      },
      "tutor": {
        "checkedIn": false
      },
      "bothCheckedIn": false
    },
    "offlineSession": {
      "status": "student_checked_in",
      "studentArrived": true,
      "tutorArrived": false
    }
  }
}
```

### Both Checked In
```json
{
  "success": true,
  "message": "Checked in successfully",
  "data": {
    "checkIn": {
      "student": { "checkedIn": true, ... },
      "tutor": { "checkedIn": true, ... },
      "bothCheckedIn": true,
      "bothCheckedInAt": "2024-02-05T14:02:00Z"
    },
    "offlineSession": {
      "status": "in_progress",
      "studentArrived": true,
      "tutorArrived": true,
      "actualStartTime": "2024-02-05T14:02:00Z",
      "waitingTime": 2
    }
  }
}
```

### Session Completed
```json
{
  "success": true,
  "message": "Checked out successfully",
  "data": {
    "checkOut": {
      "student": { "checkedOut": true, ... },
      "tutor": { "checkedOut": true, ... },
      "bothCheckedOut": true,
      "bothCheckedOutAt": "2024-02-05T15:00:00Z"
    },
    "offlineSession": {
      "status": "completed",
      "actualEndTime": "2024-02-05T15:00:00Z",
      "actualDuration": 58
    },
    "status": "completed"
  }
}
```

---

## Testing Workflow

### Complete Test Sequence:
```
1. Create in-person booking ✅
2. Confirm booking (tutor accepts) ✅
3. Student checks in ✅
4. Verify notification sent to tutor ✅
5. Tutor checks in ✅
6. Verify both checked in ✅
7. Verify session auto-started ✅
8. Student checks out ✅
9. Tutor checks out ✅
10. Verify session completed ✅
11. Verify payment scheduled for release ✅
```

### Test Running Late:
```
1. Create booking ✅
2. Student notifies running late ✅
3. Verify tutor receives notification ✅
4. Student checks in (late) ✅
5. Continue normal flow ✅
```

### Test Safety Features:
```
1. Set emergency contact ✅
2. Share session with contacts ✅
3. Report safety issue ✅
4. Verify issue logged ✅
```

---

## Common Issues & Solutions

### Issue: "Check-in is only available for in-person sessions"
**Solution**: Ensure `sessionType` is set to `"inPerson"` when creating booking

### Issue: "Only confirmed bookings can be checked in"
**Solution**: Tutor must accept/confirm the booking first

### Issue: "Student already checked in"
**Solution**: Each party can only check in once

### Issue: "Both parties must check in before checking out"
**Solution**: Wait for both parties to check in first

### Issue: Distance verification fails
**Solution**: Ensure GPS coordinates are within 100m of meeting point

---

## Postman Collection

Import this collection to test all endpoints:

```json
{
  "info": {
    "name": "Offline Sessions API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Check In",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{token}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"location\": {\n    \"latitude\": 9.0192,\n    \"longitude\": 38.7525\n  }\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "{{baseUrl}}/api/offline-sessions/{{bookingId}}/check-in",
          "host": ["{{baseUrl}}"],
          "path": ["api", "offline-sessions", "{{bookingId}}", "check-in"]
        }
      }
    }
  ]
}
```

---

## Environment Variables

```
baseUrl=http://localhost:5000
token=YOUR_AUTH_TOKEN
bookingId=YOUR_BOOKING_ID
```

---

**Ready to test!** 🚀

Use these commands to test the complete offline session flow.
