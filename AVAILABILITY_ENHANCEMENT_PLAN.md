# 📅 Availability Enhancement Plan

## 🎯 Goal
Enhance the availability creation system to include:
1. ✅ Select days available (exists)
2. ✅ Select time ranges (exists)
3. **NEW**: Choose session types (online/offline) with separate pricing
4. **NEW**: If offline → set meeting location & travel distance
5. **NEW**: Set hourly price per session type
6. ✅ Recurring weekly (exists, will enhance)

---

## 📊 Current State

### What Exists:
- Day selection (Monday-Sunday)
- Time range selection (start/end time)
- Duration validation (minimum 15 minutes)
- Recurring weekly option
- Basic availability slot creation

### What's Missing:
- Session type selection (online/offline/both)
- Separate pricing for online vs offline sessions
- Offline session details (location, travel distance)
- Session type filtering in booking flow

---

## 🔧 Changes Required

### 1. Backend Changes

#### A. Update AvailabilitySlot Model
**File**: `server/models/AvailabilitySlot.js`

Add new fields:
```javascript
sessionTypes: [{
  type: {
    type: String,
    enum: ['online', 'offline'],
    required: true
  },
  hourlyRate: {
    type: Number,
    required: true,
    min: 0
  },
  // For offline sessions
  meetingLocation: {
    type: String,
    required: function() {
      return this.type === 'offline';
    }
  },
  travelDistance: {
    type: Number, // in kilometers
    required: function() {
      return this.type === 'offline';
    }
  },
  additionalNotes: String
}]
```

#### B. Update TutorProfile Model (Optional)
**File**: `server/models/TutorProfile.js`

Add default session type pricing:
```javascript
pricing: {
  hourlyRate: Number, // Keep for backward compatibility
  onlineRate: Number,
  offlineRate: Number,
  currency: { type: String, default: 'ETB' }
}
```

#### C. Update Controllers
**File**: `server/controllers/availabilitySlotController.js`

- Update `createAvailabilitySlot` to accept session types
- Update `createBulkAvailability` to accept session types
- Add validation for session type data

### 2. Frontend Changes

#### A. Update Availability Model
**File**: `mobile_app/lib/features/tutor/models/availability_model.dart`

Add new classes:
```dart
class SessionTypeInfo {
  final String type; // 'online' or 'offline'
  final double hourlyRate;
  final String? meetingLocation;
  final double? travelDistance;
  final String? additionalNotes;
}

class AvailabilitySlot {
  // ... existing fields
  final List<SessionTypeInfo> sessionTypes;
}
```

#### B. Update AddAvailabilitySheet UI
**File**: `mobile_app/lib/features/tutor/screens/tutor_schedule_screen.dart`

Add new UI sections:
1. **Session Type Selection**
   - Checkboxes for Online/Offline/Both
   - Show pricing fields for selected types

2. **Online Session Section** (if selected)
   - Hourly rate input field
   - Meeting platform (Zoom, Google Meet, etc.)

3. **Offline Session Section** (if selected)
   - Hourly rate input field
   - Meeting location input
   - Travel distance slider/input
   - Additional notes

4. **Recurring Options** (enhance existing)
   - Keep weekly recurring
   - Add end date picker

#### C. Update Availability Service
**File**: `mobile_app/lib/features/tutor/services/availability_service.dart`

- Update API calls to include session type data
- Add validation for session type requirements

### 3. Booking Flow Updates

#### Update Booking Screen
**File**: `mobile_app/lib/features/student/screens/tutor_booking_screen.dart`

- Show available session types for each slot
- Display different prices for online vs offline
- Allow student to choose session type
- Show offline location if applicable

---

## 🎨 UI Design

### AddAvailabilitySheet Layout:

```
┌─────────────────────────────────────┐
│  Add Availability                   │
├─────────────────────────────────────┤
│                                     │
│  1. Select Day                      │
│  [Dropdown: Monday ▼]               │
│                                     │
│  2. Select Time Range               │
│  [09:00] → [10:00]                  │
│  Duration: 60 minutes ✓             │
│                                     │
│  3. Session Types                   │
│  ☑ Online Session                   │
│    Hourly Rate: [500 ETB]           │
│    Platform: [Zoom ▼]               │
│                                     │
│  ☑ Offline Session                  │
│    Hourly Rate: [600 ETB]           │
│    Location: [Coffee Shop, Bole]    │
│    Travel Distance: [5 km]          │
│    Notes: [Near Edna Mall]          │
│                                     │
│  4. Recurring                       │
│  ☑ Repeat Weekly                    │
│    Until: [Dec 31, 2024]            │
│                                     │
│  [Cancel]  [Save Availability]      │
└─────────────────────────────────────┘
```

---

## 📝 Implementation Steps

### Phase 1: Backend (30 minutes)
1. ✅ Update AvailabilitySlot model
2. ✅ Update availability controller
3. ✅ Update availability routes
4. ✅ Test API endpoints

### Phase 2: Frontend Models (15 minutes)
1. ✅ Update availability_model.dart
2. ✅ Update availability_service.dart
3. ✅ Add validation logic

### Phase 3: Frontend UI (45 minutes)
1. ✅ Update AddAvailabilitySheet
2. ✅ Add session type selection UI
3. ✅ Add pricing inputs
4. ✅ Add offline session fields
5. ✅ Add validation and error handling
6. ✅ Update EditAvailabilitySheet

### Phase 4: Booking Flow (30 minutes)
1. ✅ Update booking screen to show session types
2. ✅ Update booking creation to include session type
3. ✅ Update price calculation

### Phase 5: Testing (20 minutes)
1. ✅ Test availability creation
2. ✅ Test recurring availability
3. ✅ Test booking with different session types
4. ✅ Test price calculations

**Total Estimated Time**: 2.5 hours

---

## 🔍 Validation Rules

### Session Type:
- At least one session type must be selected
- Each session type must have a valid hourly rate (> 0)
- Offline sessions must have location and travel distance

### Pricing:
- Hourly rate must be positive number
- Offline rate typically higher than online (optional validation)
- Maximum rate: 10,000 ETB (configurable)

### Location (Offline):
- Minimum 5 characters
- Maximum 200 characters
- Required if offline session selected

### Travel Distance (Offline):
- Minimum: 0 km
- Maximum: 100 km
- Required if offline session selected

### Recurring:
- If recurring, end date must be in future
- Maximum 52 weeks (1 year) ahead
- Minimum 1 week ahead

---

## 💡 Benefits

### For Tutors:
- Flexible pricing for different session types
- Can offer both online and offline options
- Clear communication of offline meeting locations
- Better control over availability

### For Students:
- Clear pricing transparency
- Can choose preferred session type
- Know meeting location upfront for offline sessions
- Better booking experience

### For Platform:
- More detailed availability data
- Better matching between tutors and students
- Improved user experience
- More booking options

---

## 🚀 Next Steps

1. Review and approve this plan
2. Start with Phase 1 (Backend)
3. Test each phase before moving to next
4. Deploy and gather feedback
5. Iterate based on user feedback

---

**Status**: 📋 PLAN READY
**Estimated Time**: 2.5 hours
**Priority**: HIGH
**Complexity**: MEDIUM
