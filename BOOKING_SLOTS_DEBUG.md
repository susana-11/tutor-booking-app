# 🔍 Debugging "No Available Slots" Issue

## Issue
When students try to book a session, they see "No available slots" even though the tutor has created availability.

## Possible Causes

### 1. Wrong Tutor ID Being Passed
- Student might be passing Profile ID instead of User ID
- Or vice versa

### 2. Date Range Mismatch
- Slots created for dates outside the query range
- Timezone issues

### 3. Slot Filtering Issues
- Slots marked as unavailable
- Slots already booked
- Slots in the past

## Debugging Steps

### Step 1: Check Server Logs
After adding logging, restart server and check what's being queried:

```bash
cd server
node server.js
```

Look for these logs when student tries to book:
```
🔍 Querying slots for tutorId: 507f1f77bcf86cd799439011
📅 Date range: 2026-02-03 to 2026-03-05
✅ Found 5 slots for tutor 507f1f77bcf86cd799439011
```

### Step 2: Check Mobile App Logs
Look at the Flutter console when loading booking screen:

```
🔍 Loading slots for tutorId: 507f1f77bcf86cd799439011
📅 Date range: 2026-02-03 to 2026-03-05
📥 Response success: true
📥 Response data length: 5
📊 Total slots received: 5
✅ Available slots after filtering: 3
```

### Step 3: Verify Tutor ID
Check what ID is being used:

1. **In MongoDB**, find the tutor's User document:
   ```javascript
   db.users.findOne({ email: "tutor@example.com" })
   // Note the _id field
   ```

2. **Check availability slots**:
   ```javascript
   db.availabilityslots.find({ tutorId: ObjectId("USER_ID_HERE") })
   // Should return the slots the tutor created
   ```

3. **Check what ID student is using**:
   - Look at mobile app logs
   - Should match the User _id from step 1

### Step 4: Check Slot Properties
Verify slots have correct properties:

```javascript
db.availabilityslots.findOne({ tutorId: ObjectId("USER_ID") })
```

Should show:
```javascript
{
  _id: ObjectId("..."),
  tutorId: ObjectId("USER_ID"), // ← Should be User ID
  date: ISODate("2026-02-04T00:00:00.000Z"),
  timeSlot: {
    startTime: "09:00",
    endTime: "09:30",
    durationMinutes: 30
  },
  isAvailable: true, // ← Should be true
  isActive: true, // ← Should be true
  booking: null, // ← Should be null (not booked)
  createdAt: ISODate("..."),
  updatedAt: ISODate("...")
}
```

## Common Issues & Fixes

### Issue 1: Tutor ID Mismatch
**Symptom**: Server logs show "Found 0 slots"

**Fix**: The tutorId being passed doesn't match the tutorId in slots

**Solution**:
1. Check what ID is in the URL when viewing tutor profile
2. Check what ID is stored in availability slots
3. They should match!

### Issue 2: Slots in the Past
**Symptom**: Slots found but filtered out

**Fix**: Slots are for dates that have already passed

**Solution**:
- Create new slots for future dates
- Or check if date comparison is working correctly

### Issue 3: Slots Marked Unavailable
**Symptom**: Slots found but `isAvailable: false`

**Fix**: Tutor marked slots as unavailable

**Solution**:
- Tutor should edit slots and mark as available
- Or check why slots are being created as unavailable

### Issue 4: Navigation Issue
**Symptom**: Can't even reach booking screen

**Fix**: Route not configured correctly

**Solution**: Check if navigating to correct route with correct parameters

## Quick Test

### Create Test Slot Manually
```javascript
// In MongoDB
db.availabilityslots.insertOne({
  tutorId: ObjectId("TUTOR_USER_ID_HERE"),
  date: new Date("2026-02-10"),
  timeSlot: {
    startTime: "14:00",
    endTime: "15:00",
    durationMinutes: 60
  },
  isAvailable: true,
  isActive: true,
  isRecurring: false,
  createdAt: new Date(),
  updatedAt: new Date()
})
```

Then try to book as student - should see this slot!

## Expected Flow

### Correct Flow:
```
1. Tutor creates slot
   - tutorId = Tutor's User ID
   - date = Future date
   - isAvailable = true
   - isActive = true

2. Student views tutor profile
   - tutorId = Same User ID

3. Student clicks "Book Session"
   - Passes tutorId to booking screen

4. Booking screen queries slots
   - GET /api/availability/slots?tutorId=USER_ID&startDate=...&endDate=...

5. Backend finds slots
   - Matches tutorId
   - Returns slots

6. Mobile app filters slots
   - isAvailable = true
   - isBooked = false
   - isUpcoming = true

7. Student sees available slots ✅
```

## Next Steps

1. **Add the logging** (already done in code)
2. **Restart server**
3. **Restart mobile app**
4. **Try to book again**
5. **Check logs** in both server and mobile app
6. **Report what you see**

The logs will tell us exactly what's happening!

---

**Status**: Debugging logs added  
**Action**: Restart server and mobile app, then try booking again  
**Look for**: Console logs showing tutorId and slot counts
