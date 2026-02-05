# 🔍 Why It Shows 500 ETB Instead of Tutor's Actual Rate

## The Issue

The booking screen is showing 500 ETB as the hourly rate, even though the tutor may have set a different rate (like 100 ETB) in their profile.

## Root Cause

The hourly rate is stored in the database in the tutor's profile at:
```
TutorProfile.pricing.hourlyRate
```

When you see 500 ETB, it means the tutor's `pricing.hourlyRate` field in the database is actually set to 500.

## Why This Happens

### Scenario 1: Test Data
- Test tutors were created with a default rate of 500
- The tutor never updated their rate in the app

### Scenario 2: Tutor Set It to 500
- The tutor actually set their rate to 500 ETB when creating their profile
- This is the correct rate for that tutor

### Scenario 3: Old Data Format
- Tutor profile was created before the pricing structure was properly set up
- Default value of 500 was used

## How to Check

### Option 1: Run Check Script
```bash
cd server
node scripts/checkTutorRates.js
```

This will show all tutors and their hourly rates.

### Option 2: Check in Database
Look at the TutorProfile collection:
```javascript
{
  userId: "...",
  pricing: {
    hourlyRate: 500,  // ← This is what's being shown
    currency: "ETB"
  }
}
```

## How to Fix

### Option 1: Update via Script
```bash
cd server
node scripts/updateTutorRate.js
```

Follow the prompts:
1. Enter tutor email
2. See current rate
3. Enter new rate (e.g., 100)
4. Confirm

### Option 2: Tutor Updates in App
1. Tutor logs in
2. Goes to Profile Settings
3. Updates "Hourly Rate" field
4. Saves

### Option 3: Update Directly in Database
```javascript
// In MongoDB
db.tutorprofiles.updateOne(
  { userId: ObjectId("tutor_user_id") },
  { $set: { "pricing.hourlyRate": 100 } }
)
```

## The Data Flow

### 1. Database
```javascript
TutorProfile {
  pricing: {
    hourlyRate: 500  // ← Stored here
  }
}
```

### 2. Server API Response
```javascript
// server/controllers/tutorProfileController.js
{
  hourlyRate: profile.pricing?.hourlyRate || 0,  // ← Sent as 500
  pricing: profile.pricing
}
```

### 3. Mobile App - Tutor Search
```dart
// mobile_app/lib/features/student/screens/tutor_search_screen.dart
context.push('/student/book-tutor', extra: {
  'hourlyRate': (tutor['hourlyRate'] ?? 0).toDouble(),  // ← Receives 500
});
```

### 4. Mobile App - Booking Screen
```dart
// mobile_app/lib/features/student/screens/tutor_booking_screen.dart
final double hourlyRate;  // ← Gets 500 from navigation

// Used as fallback when sessionTypes is empty
final double onlineRateValue = hasSessionTypes 
    ? (_selectedSlot!.onlineRate ?? widget.hourlyRate) 
    : widget.hourlyRate;  // ← Shows 500
```

## The Correct Flow (With Session Types)

When availability slots have proper `sessionTypes` configured:

### 1. Tutor Creates Availability
```dart
// Tutor sets rates when creating schedule
sessionTypes: [
  { type: 'online', hourlyRate: 100 },
  { type: 'offline', hourlyRate: 120 }
]
```

### 2. Student Books
```dart
// Uses slot-specific rates, NOT profile rate
final hourlyRate = _selectedSessionType == 'online' 
    ? _selectedSlot!.onlineRate  // 100
    : _selectedSlot!.offlineRate; // 120
```

### 3. Price Calculation
```dart
totalAmount = hourlyRate × duration
// Example: 100 × 1.5 = 150 ETB
```

## Current Fallback Behavior

Since your slots don't have `sessionTypes` configured, the app uses the profile's base `hourlyRate` (500) as a fallback.

**This is why you see 500 ETB!**

## Solutions

### Quick Fix: Update Tutor's Profile Rate
```bash
cd server
node scripts/updateTutorRate.js
# Enter tutor email
# Enter correct rate (e.g., 100)
```

### Proper Fix: Create Availability with Session Types
1. Tutor logs in
2. Goes to Schedule Management
3. Creates new availability slots
4. Sets rates for each session type:
   - Online: 100 ETB/hr
   - Offline: 120 ETB/hr
5. Saves

Now when students book:
- Online sessions: 100 ETB/hr
- Offline sessions: 120 ETB/hr
- No more 500 ETB!

## Verification

### After Updating Rate:
1. Run check script:
```bash
node scripts/checkTutorRates.js
```

2. Should show:
```
1. John Doe (john@example.com)
   Hourly Rate: 100 ETB  ✅
   Subjects: Mathematics, Physics
   Status: approved
```

3. Test in app:
   - Search for tutor
   - Click "Book Session"
   - Should now show 100 ETB (not 500)

## Summary

✅ **The 500 ETB is coming from the database** - it's the tutor's actual stored rate
✅ **It's not a bug** - the app is correctly reading the data
✅ **To fix:** Update the tutor's `pricing.hourlyRate` in the database
✅ **Better solution:** Have tutor create availability with session-specific rates

## Scripts Created

- `server/scripts/checkTutorRates.js` - Check all tutor rates
- `server/scripts/updateTutorRate.js` - Update a specific tutor's rate

Run these to diagnose and fix the issue!
