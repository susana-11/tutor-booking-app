# 📍 Offline/In-Person Session Feature - Implementation Plan

## Overview
Implementing complete offline session management like Uber, TaskRabbit, and other real-world apps.

---

## Features to Implement

### 1. Location Management
- ✅ Meeting location selection
- ✅ Address autocomplete
- ✅ Saved locations (Home, Library, etc.)
- ✅ Map integration
- ✅ Distance calculation
- ✅ Travel time estimation

### 2. Session Coordination
- ✅ Check-in system (both parties)
- ✅ Check-out system
- ✅ Real-time location sharing (optional)
- ✅ Arrival notifications
- ✅ Running late notifications
- ✅ Session timer

### 3. Safety Features
- ✅ Emergency contact
- ✅ Share session details
- ✅ Report issues
- ✅ Session verification
- ✅ Photo verification (optional)

### 4. Payment & Completion
- ✅ Check-in required for payment
- ✅ Automatic completion after check-out
- ✅ Dispute handling
- ✅ No-show protection

---

## Database Schema Updates

### Booking Model - Offline Session Fields
```javascript
{
  sessionType: 'inPerson',
  
  // Location Details
  location: {
    type: {
      type: String,
      enum: ['student_location', 'tutor_location', 'public_place', 'custom']
    },
    address: String,
    city: String,
    state: String,
    zipCode: String,
    country: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    placeId: String, // Google Places ID
    placeName: String, // e.g., "Starbucks Downtown"
    instructions: String // e.g., "Meet at the entrance"
  },
  
  // Check-in/Check-out
  checkIn: {
    student: {
      checkedIn: Boolean,
      checkedInAt: Date,
      location: {
        latitude: Number,
        longitude: Number
      },
      verified: Boolean
    },
    tutor: {
      checkedIn: Boolean,
      checkedInAt: Date,
      location: {
        latitude: Number,
        longitude: Number
      },
      verified: Boolean
    },
    bothCheckedIn: Boolean,
    bothCheckedInAt: Date
  },
  
  checkOut: {
    student: {
      checkedOut: Boolean,
      checkedOutAt: Date
    },
    tutor: {
      checkedOut: Boolean,
      checkedOutAt: Date
    },
    bothCheckedOut: Boolean,
    bothCheckedOutAt: Date
  },
  
  // Session Status
  offlineSession: {
    status: {
      type: String,
      enum: ['scheduled', 'student_checked_in', 'tutor_checked_in', 
             'both_checked_in', 'in_progress', 'completed', 'no_show']
    },
    studentArrived: Boolean,
    tutorArrived: Boolean,
    runningLate: {
      student: {
        isLate: Boolean,
        estimatedArrival: Date,
        notifiedAt: Date
      },
      tutor: {
        isLate: Boolean,
        estimatedArrival: Date,
        notifiedAt: Date
      }
    },
    actualStartTime: Date,
    actualEndTime: Date,
    actualDuration: Number
  },
  
  // Safety
  safety: {
    emergencyContact: {
      name: String,
      phone: String,
      relationship: String
    },
    sessionShared: Boolean,
    sharedWith: [String], // Array of phone numbers/emails
    issues: [{
      reportedBy: ObjectId,
      issue: String,
      description: String,
      reportedAt: Date,
      resolved: Boolean
    }]
  }
}
```

---

## API Endpoints

### Location Management
```
POST   /api/bookings/:id/location        - Set meeting location
GET    /api/locations/search              - Search locations
GET    /api/locations/saved               - Get saved locations
POST   /api/locations/saved               - Save location
DELETE /api/locations/saved/:id           - Delete saved location
```

### Check-in/Check-out
```
POST   /api/bookings/:id/check-in         - Check in to session
POST   /api/bookings/:id/check-out        - Check out from session
GET    /api/bookings/:id/check-in-status  - Get check-in status
POST   /api/bookings/:id/running-late     - Notify running late
```

### Safety
```
POST   /api/bookings/:id/emergency-contact - Set emergency contact
POST   /api/bookings/:id/share-session     - Share session details
POST   /api/bookings/:id/report-issue      - Report safety issue
```

---

## Mobile App Screens

### 1. Location Selection Screen
```
- Search bar with autocomplete
- Map view
- Saved locations list
- Custom location input
- Distance & travel time display
- Confirm location button
```

### 2. Session Details Screen (Offline)
```
- Meeting location with map
- Directions button
- Check-in button
- Running late button
- Contact tutor/student button
- Emergency button
- Session timer
```

### 3. Check-in Screen
```
- Location verification
- Photo verification (optional)
- Confirm arrival button
- Waiting for other party indicator
- Cancel session option
```

### 4. Active Offline Session Screen
```
- Session timer
- Check-out button
- Add notes
- Report issue
- End session
```

---

## User Flow

### Student Flow:
```
1. Book session → Select "In-Person"
2. Choose meeting location
3. Receive confirmation
4. Get reminder (1 hour before)
5. Navigate to location
6. Check in when arrived
7. Wait for tutor check-in
8. Session starts
9. Check out when done
10. Rate session
```

### Tutor Flow:
```
1. Receive booking request
2. Review location
3. Accept/Reject
4. Get reminder (1 hour before)
5. Navigate to location
6. Check in when arrived
7. Wait for student check-in
8. Session starts
9. Check out when done
10. Receive payment
```

---

## Implementation Steps

### Phase 1: Backend (Server)
1. Update Booking model with offline fields
2. Create location management endpoints
3. Create check-in/check-out endpoints
4. Add safety endpoints
5. Update session controller
6. Add notifications for offline sessions

### Phase 2: Mobile App
1. Create location selection screen
2. Integrate map (Google Maps/Apple Maps)
3. Create check-in/check-out UI
4. Add GPS location services
5. Create offline session screen
6. Add safety features
7. Update booking flow

### Phase 3: Testing
1. Test location selection
2. Test check-in/check-out
3. Test notifications
4. Test payment flow
5. Test safety features
6. Test edge cases (no-show, late arrival)

---

## Next Steps

Starting implementation with:
1. Backend model updates
2. API endpoints
3. Mobile screens
4. Integration & testing

Let's build this! 🚀
