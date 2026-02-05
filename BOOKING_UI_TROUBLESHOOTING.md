# 🔍 Booking UI Troubleshooting Guide

## Issue: Session Details Tab Shows Only Text Labels

### Symptoms
- You see "Choose Session Type" text
- You see "Select Duration" text  
- You see "1hr", "1.5hr", "2hr" text
- But no interactive cards/buttons
- "Continue to Confirmation" button appears blurred/disabled

### Root Causes & Solutions

## Cause 1: Missing Session Type Data ⚠️

**Problem:** The availability slot doesn't have session type information

**Check:**
1. Look at console logs when you select a slot
2. You should see:
```
🔍 Session Details Tab - Selected Slot Info:
  - Has Online: true
  - Has Offline: true
  - Online Rate: 100
  - Offline Rate: 120
  - Session Types Count: 2
```

**If you see:**
```
  - Has Online: false
  - Has Offline: false
  - Session Types Count: 0
```

**Solution:** The tutor hasn't set up session types properly

### Fix on Tutor Side:
1. Tutor logs in
2. Goes to Schedule Management
3. When creating availability slots, must:
   - ✅ Check "Online Session" and set rate
   - ✅ Check "Offline Session" and set rate
   - ✅ For offline: Add meeting location and travel distance
4. Save the availability

### Fix via Script (if needed):
Run this to check tutor's slots:
```bash
cd server
node scripts/checkTutorSlots.js
```

## Cause 2: Widget Not Rendering (Flutter Issue)

**Problem:** The widgets exist but aren't displaying

**Solutions:**

### Solution A: Full App Restart
```bash
# Stop the app completely
# Then rebuild and run
cd mobile_app
flutter clean
flutter pub get
flutter run
```

### Solution B: Check for Conditional Rendering
The session type cards only show if:
- `_selectedSlot!.hasOnlineSession` is true (for online card)
- `_selectedSlot!.hasOfflineSession` is true (for offline card)

If BOTH are false, you'll see the title but no cards!

## Cause 3: Data Structure Mismatch

**Problem:** Server sends data in wrong format

**Check Server Response:**
Look for this in console when loading slots:
```
📥 Response success: true
📥 Response data length: 10
📊 Total slots received: 10
✅ Available slots after filtering: 5
```

**Expected Slot Structure:**
```json
{
  "id": "...",
  "tutorId": "...",
  "date": "2026-02-10T00:00:00.000Z",
  "timeSlot": {
    "startTime": "09:00",
    "endTime": "10:00",
    "durationMinutes": 60
  },
  "sessionTypes": [
    {
      "type": "online",
      "hourlyRate": 100
    },
    {
      "type": "offline",
      "hourlyRate": 120,
      "meetingLocation": "Tutor's Office",
      "travelDistance": 10
    }
  ],
  "isAvailable": true,
  "isBooked": false
}
```

**If sessionTypes is empty `[]`:**
- The tutor needs to recreate their availability with session types

## Cause 4: Price Display Issue ($500 instead of $100)

**This has been FIXED** ✅

**What was wrong:**
- Used `widget.hourlyRate` (base rate) instead of calculated rate
- Didn't multiply by duration

**What's fixed:**
- Now uses `_getSelectedHourlyRate()` (session-type-specific rate)
- Multiplies by `_selectedDuration` (1, 1.5, or 2 hours)
- Shows proper breakdown in confirmation

## Testing Steps

### Step 1: Verify Tutor Has Proper Availability
```bash
cd server
node scripts/checkTutorSlots.js
```

Look for output showing session types:
```
Slot: 2026-02-10 09:00-10:00
  Session Types:
    - online: 100 ETB/hr
    - offline: 120 ETB/hr (Location: Tutor's Office, Travel: 10km)
```

### Step 2: Test Booking Flow
1. **Student logs in**
2. **Search for tutor**
3. **Click "Book Session"**
4. **Tab 1 - Select Time:**
   - Choose a date
   - Select a time slot
   - You should see colored chips showing "Online - 100 ETB/hr" and "Offline - 120 ETB/hr"

5. **Tab 2 - Session Details:**
   - Should see 2 large cards:
     - 🎥 Online Session card (blue)
     - 📍 Offline Session card (green)
   - Should see 3 duration buttons:
     - 1 hr (shows calculated price)
     - 1.5 hrs (shows calculated price)
     - 2 hrs (shows calculated price)
   - If offline selected, should see 3 location options

6. **Tab 3 - Confirm:**
   - Should see complete summary
   - Should see correct price calculation
   - Button should show correct total

## Quick Fixes

### Fix 1: Recreate Test Availability
```bash
cd server
node scripts/createTestAvailability.js
```

This creates slots with proper session types.

### Fix 2: Check Specific Tutor
```bash
cd server
node scripts/checkTutorSlots.js
# Enter tutor email when prompted
```

### Fix 3: Full App Rebuild
```bash
cd mobile_app
flutter clean
flutter pub get
flutter run
```

## What to Look For in Console

### Good Output ✅
```
🔍 Loading slots for tutorId: 507f1f77bcf86cd799439011
📅 Date range: 2026-02-05 to 2026-03-07
📥 Response success: true
📥 Response data length: 15
📊 Total slots received: 15
✅ Available slots after filtering: 8

🔍 Session Details Tab - Selected Slot Info:
  - Has Online: true
  - Has Offline: true
  - Online Rate: 100.0
  - Offline Rate: 120.0
  - Session Types Count: 2
    - Type: online, Rate: 100.0
    - Type: offline, Rate: 120.0
```

### Bad Output ❌
```
🔍 Session Details Tab - Selected Slot Info:
  - Has Online: false
  - Has Offline: false
  - Online Rate: 0.0
  - Offline Rate: 0.0
  - Session Types Count: 0
```

**If you see bad output:** The slot has no session types configured!

## Server-Side Check

### Check Availability Slot in Database
```javascript
// In MongoDB or via script
db.availabilityslots.findOne({ tutorId: "..." })

// Should have:
{
  sessionTypes: [
    { type: "online", hourlyRate: 100 },
    { type: "offline", hourlyRate: 120, meetingLocation: "...", travelDistance: 10 }
  ]
}
```

### If sessionTypes is missing or empty:
The tutor needs to:
1. Go to Schedule Management
2. Delete old slots
3. Create new slots with session types properly configured

## Common Mistakes

### Mistake 1: Tutor Created Slots Before Session Types Feature
**Solution:** Delete old slots, create new ones

### Mistake 2: Only Set Base Hourly Rate, Not Session-Specific Rates
**Solution:** When creating availability, set rates for EACH session type

### Mistake 3: Didn't Select Session Type Checkboxes
**Solution:** Must check "Online Session" and/or "Offline Session" when creating availability

## Files Modified (for reference)
- `mobile_app/lib/features/student/screens/tutor_booking_screen.dart`
  - Added debug logging
  - Fixed price calculation
  - Added validation for session type selection
  - Enhanced confirmation tab

## Need More Help?

1. **Check console logs** - They show exactly what data is received
2. **Verify tutor's availability** - Use checkTutorSlots.js script
3. **Recreate test data** - Use createTestAvailability.js script
4. **Full app restart** - Sometimes Flutter needs a clean rebuild

## Expected Behavior After Fix

✅ Session type cards display with icons and colors
✅ Duration buttons show calculated prices
✅ Confirmation shows correct total (rate × duration)
✅ All prices in ETB currency
✅ Proper validation prevents incomplete bookings
