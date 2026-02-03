# Accepting Bookings Toggle - Testing Guide

## Prerequisites
- Server running on port 5000
- Mobile app connected to server
- Two test accounts:
  - Tutor account (with completed profile)
  - Student account

## Test Scenario 1: Toggle Accepting Bookings OFF

### Step 1: Login as Tutor
1. Open mobile app
2. Login with tutor credentials
3. Navigate to Profile screen

### Step 2: Toggle OFF
1. Find "Accepting Bookings" switch
2. Toggle it to OFF position
3. **Expected Result**: 
   - Switch turns OFF
   - Success message: "Availability updated successfully"
   - API call: `PUT /api/tutors/profile/availability` with `{isAvailable: false}`

### Step 3: Verify Student View
1. Logout from tutor account
2. Login with student account
3. Search for the tutor
4. Open tutor detail screen
5. **Expected Result**:
   - Orange warning badge appears: "Not accepting new bookings"
   - "Book Session" button is disabled
   - Button text changes to "Not Available"

### Step 4: Try to Book (Should Fail)
1. Even if you somehow trigger booking (via API)
2. **Expected Result**:
   - Error message: "This tutor is not accepting new bookings at the moment. Please try again later."
   - HTTP Status: 400
   - No booking created in database

## Test Scenario 2: Toggle Accepting Bookings ON

### Step 1: Login as Tutor
1. Open mobile app
2. Login with tutor credentials
3. Navigate to Profile screen

### Step 2: Toggle ON
1. Find "Accepting Bookings" switch
2. Toggle it to ON position
3. **Expected Result**:
   - Switch turns ON
   - Success message: "Availability updated successfully"
   - API call: `PUT /api/tutors/profile/availability` with `{isAvailable: true}`

### Step 3: Verify Student View
1. Logout from tutor account
2. Login with student account
3. Search for the tutor
4. Open tutor detail screen
5. **Expected Result**:
   - NO warning badge
   - "Book Session" button is ENABLED
   - Button text shows "Book Session"

### Step 4: Try to Book (Should Succeed)
1. Click "Book Session" button
2. Select date and time slot
3. Fill in booking details
4. Submit booking
5. **Expected Result**:
   - Success message: "Booking request sent! Waiting for tutor confirmation."
   - Booking created in database with status "pending"
   - Navigate back to previous screen

## Test Scenario 3: API Error Handling

### Step 1: Simulate Network Error
1. Turn off WiFi/mobile data
2. Try to toggle accepting bookings
3. **Expected Result**:
   - Error message displayed
   - Switch reverts to previous state
   - No changes saved

### Step 2: Verify State Persistence
1. Toggle accepting bookings OFF
2. Close app completely
3. Reopen app and login as tutor
4. Navigate to Profile screen
5. **Expected Result**:
   - Switch shows OFF state (persisted)

## Test Scenario 4: Multiple Booking Attempts

### Step 1: Create Multiple Bookings
1. Login as student
2. Try to book with tutor (isAvailable = true)
3. Create 2-3 bookings successfully
4. **Expected Result**: All bookings created

### Step 2: Toggle OFF and Try Again
1. Login as tutor
2. Toggle accepting bookings OFF
3. Login as student
4. Try to create another booking
5. **Expected Result**: 
   - Error message displayed
   - No new booking created
   - Existing bookings remain unchanged

## Verification Checklist

### Backend Verification
- [ ] `isAvailable` field exists in TutorProfile model
- [ ] Toggle endpoint works: `PUT /api/tutors/profile/availability`
- [ ] Booking validation in `bookingController.createBookingRequest()`
- [ ] Booking validation in legacy route `POST /api/bookings`
- [ ] Profile responses include `isAvailable` field

### Mobile App Verification
- [ ] Toggle switch in tutor profile screen
- [ ] API call on toggle
- [ ] Success/error feedback
- [ ] Warning badge on tutor detail screen
- [ ] Disabled button when unavailable
- [ ] Error handling for booking attempts

### Database Verification
```javascript
// Check tutor profile in MongoDB
db.tutorprofiles.findOne({ userId: ObjectId("TUTOR_USER_ID") })
// Should show: isAvailable: true/false

// Check bookings
db.bookings.find({ tutorId: "TUTOR_USER_ID" })
// Should NOT create new bookings when isAvailable = false
```

## Common Issues and Solutions

### Issue 1: Toggle doesn't work
**Solution**: Check server logs for errors, verify API endpoint is correct

### Issue 2: Button still enabled when unavailable
**Solution**: Verify `isAvailable` field is being returned in API response

### Issue 3: Booking still created when unavailable
**Solution**: Restart server to apply validation changes

### Issue 4: Warning badge doesn't show
**Solution**: Check if `isAvailable` field is being read correctly from API response

## API Endpoints Reference

### Toggle Accepting Bookings
```
PUT /api/tutors/profile/availability
Headers: Authorization: Bearer <token>
Body: { "isAvailable": true/false }
Response: { "success": true, "message": "..." }
```

### Get Tutor Profile
```
GET /api/tutors/profile
Headers: Authorization: Bearer <token>
Response: { 
  "success": true, 
  "data": { 
    "isAvailable": true/false,
    ...
  } 
}
```

### Create Booking
```
POST /api/bookings
Headers: Authorization: Bearer <token>
Body: { "tutorId": "...", "subjectId": "...", ... }
Response (when unavailable): {
  "success": false,
  "message": "This tutor is not accepting new bookings at the moment. Please try again later."
}
```

## Success Criteria

✅ Tutor can toggle accepting bookings ON/OFF
✅ Toggle state persists in database
✅ Student sees warning badge when tutor is unavailable
✅ Book button is disabled when tutor is unavailable
✅ Booking creation fails with clear error message when tutor is unavailable
✅ Existing bookings are not affected by toggle
✅ Error handling works correctly
✅ UI updates immediately after toggle

## Test Complete! 🎉

If all tests pass, the accepting bookings toggle feature is working correctly.
