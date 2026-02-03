# Session UI Implementation Guide

## ✅ What's Been Implemented

### 1. Session Timer Widget
**File**: `mobile_app/lib/core/widgets/session_timer.dart`

Two variants created:
- `SessionTimer`: Full timer with progress bar and warnings
- `CompactSessionTimer`: Compact version for app bar

Features:
- Countdown timer
- Progress bar
- Color changes (green → orange → red)
- 5-minute warning
- Auto-end when time is up
- Formatted time display (HH:MM:SS or MM:SS)

### 2. Active Session Screen
**File**: `mobile_app/lib/features/session/screens/active_session_screen.dart`

Features:
- Session timer display
- Other party information
- Session notes input
- End session button
- Agora integration
- Session completion dialog
- Payment release information
- Rating prompt

### 3. Router Configuration
**File**: `mobile_app/lib/core/router/app_router.dart`

Added route:
```dart
GoRoute(
  path: '/active-session/:bookingId',
  name: 'active-session',
  builder: (context, state) {
    final bookingId = state.pathParameters['bookingId']!;
    final sessionData = state.extra as Map<String, dynamic>;
    return ActiveSessionScreen(
      bookingId: bookingId,
      sessionData: sessionData,
    );
  },
),
```

---

## 📋 Next Steps - Add to Booking Screens

### Step 1: Import Session Service

Add to both `student_bookings_screen.dart` and `tutor_bookings_screen.dart`:

```dart
import '../../../core/services/session_service.dart';
```

### Step 2: Add Session Service Instance

In the State class:

```dart
final SessionService _sessionService = SessionService();
```

### Step 3: Add "Start Session" Button Logic

Add this method to both booking screens:

```dart
Future<void> _startSession(Map<String, dynamic> booking) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Start session
    final response = await _sessionService.startSession(booking['id']);

    // Close loading
    if (mounted) Navigator.pop(context);

    if (response.success && response.data != null) {
      // Navigate to active session screen
      if (mounted) {
        context.push(
          '/active-session/${booking['id']}',
          extra: response.data,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to start session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    // Close loading
    if (mounted) Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _joinSession(Map<String, dynamic> booking) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Join session
    final response = await _sessionService.joinSession(booking['id']);

    // Close loading
    if (mounted) Navigator.pop(context);

    if (response.success && response.data != null) {
      // Navigate to active session screen
      if (mounted) {
        context.push(
          '/active-session/${booking['id']}',
          extra: response.data,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to join session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    // Close loading
    if (mounted) Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

bool _canStartSession(Map<String, dynamic> booking) {
  if (booking['status'] != 'confirmed') return false;
  
  try {
    final sessionDate = DateTime.parse(booking['sessionDate']);
    final startTime = booking['startTime'] as String;
    final parts = startTime.split(':');
    final sessionDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    
    final now = DateTime.now();
    
    // Can start 5 minutes before
    final canStartFrom = sessionDateTime.subtract(const Duration(minutes: 5));
    
    // Can start up to 15 minutes after
    final canStartUntil = sessionDateTime.add(const Duration(minutes: 15));
    
    return now.isAfter(canStartFrom) && now.isBefore(canStartUntil);
  } catch (e) {
    print('Error checking if can start: $e');
    return false;
  }
}

String _getTimeUntilSession(Map<String, dynamic> booking) {
  try {
    final sessionDate = DateTime.parse(booking['sessionDate']);
    final startTime = booking['startTime'] as String;
    final parts = startTime.split(':');
    final sessionDateTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    
    final now = DateTime.now();
    final difference = sessionDateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Session time passed';
    } else if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Starting now!';
    }
  } catch (e) {
    return '';
  }
}
```

### Step 4: Add Button to Booking Card

In the booking card widget (where you display each booking), add this button:

```dart
// Inside the booking card, after other booking details
if (_canStartSession(booking)) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => _startSession(booking),
      icon: const Icon(Icons.play_circle_filled),
      label: const Text('Start Session'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  ),
  const SizedBox(height: 4),
  Text(
    _getTimeUntilSession(booking),
    style: TextStyle(
      fontSize: 12,
      color: Colors.green[700],
      fontWeight: FontWeight.w500,
    ),
    textAlign: TextAlign.center,
  ),
] else if (booking['status'] == 'confirmed') ...[
  const SizedBox(height: 12),
  Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getTimeUntilSession(booking),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

### Step 5: Check for Active Sessions

Add this method to check if a session is already active:

```dart
Future<void> _checkActiveSession(Map<String, dynamic> booking) async {
  try {
    final response = await _sessionService.getSessionStatus(booking['id']);
    
    if (response.success && response.data != null) {
      final session = response.data!['session'] as Map<String, dynamic>?;
      final isActive = session?['isActive'] ?? false;
      
      if (isActive && mounted) {
        // Session is already active, show join button instead
        final shouldJoin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Session Active'),
            content: const Text(
              'This session is already active. Would you like to join?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Join Session'),
              ),
            ],
          ),
        );
        
        if (shouldJoin == true) {
          await _joinSession(booking);
        }
      }
    }
  } catch (e) {
    print('Error checking session status: $e');
  }
}
```

---

## 🎨 Visual Example

Here's how the booking card should look:

```
┌─────────────────────────────────────────┐
│ Mathematics Session                      │
│ with John Doe                           │
│                                         │
│ 📅 Dec 15, 2024                        │
│ ⏰ 2:00 PM - 3:00 PM                   │
│ 💰 ETB 500                             │
│ ✅ Confirmed                           │
│                                         │
│ ┌─────────────────────────────────┐   │
│ │  ▶  Start Session               │   │
│ └─────────────────────────────────┘   │
│ In 5 minutes                           │
└─────────────────────────────────────────┘
```

---

## 🔄 Complete User Flow

### Student Perspective:

```
1. Open "My Bookings" screen
   ↓
2. See upcoming confirmed booking
   ↓
3. 5 minutes before session time
   ↓
4. "Start Session" button appears (green)
   ↓
5. Tap "Start Session"
   ↓
6. Loading indicator
   ↓
7. Backend creates Agora channel
   ↓
8. Navigate to Active Session Screen
   ↓
9. See timer, other party info
   ↓
10. Video call active (Agora)
    ↓
11. Session timer counts down
    ↓
12. 5 minutes warning
    ↓
13. Time up or tap "End Session"
    ↓
14. Confirmation dialog
    ↓
15. Session ends
    ↓
16. Completion dialog shows
    ↓
17. Option to rate session
    ↓
18. Navigate to rating screen or bookings
```

### Tutor Perspective:

```
Same flow as student, but:
- Sees student information
- Can add session notes
- Receives payment after 24 hours
```

---

## 🧪 Testing Checklist

### Before Session Time:
- [ ] "Start Session" button is hidden
- [ ] Shows countdown "In X hours/minutes"
- [ ] Status shows "Confirmed"

### 5 Minutes Before:
- [ ] "Start Session" button appears (green)
- [ ] Shows "In 5 minutes" or less
- [ ] Button is clickable

### During Session Window (5 min before to 15 min after):
- [ ] Button remains visible
- [ ] Can start session
- [ ] Agora channel created
- [ ] Navigate to session screen

### After Starting:
- [ ] Timer displays correctly
- [ ] Countdown works
- [ ] 5-minute warning shows
- [ ] Can end session
- [ ] Completion dialog shows
- [ ] Rating prompt appears

### After Session:
- [ ] Status changes to "Completed"
- [ ] "Start Session" button hidden
- [ ] Can view session details
- [ ] Can rate session

---

## 📱 Quick Implementation Summary

### Files to Modify:

1. **student_bookings_screen.dart**
   - Add SessionService import
   - Add _startSession() method
   - Add _joinSession() method
   - Add _canStartSession() method
   - Add button to booking card

2. **tutor_bookings_screen.dart**
   - Same changes as student screen

### Files Already Created:

1. ✅ `session_timer.dart` - Timer widget
2. ✅ `active_session_screen.dart` - Session screen
3. ✅ `session_service.dart` - API service
4. ✅ `app_router.dart` - Route added

### Backend Already Complete:

1. ✅ Session start/join/end endpoints
2. ✅ Escrow system
3. ✅ Agora token generation
4. ✅ Notifications
5. ✅ Auto-release after 24 hours

---

## 🚀 Next Action

Would you like me to:

1. **Update student_bookings_screen.dart** with the Start Session button?
2. **Update tutor_bookings_screen.dart** with the Start Session button?
3. **Create a helper widget** for the booking card with session button?
4. **All of the above**?

Just say which one and I'll implement it!
