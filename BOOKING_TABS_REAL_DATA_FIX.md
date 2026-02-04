# 🔧 Booking Tabs - Real Data Implementation

## Issue Found:
Both student and tutor booking screens are using **placeholder/mock field names** instead of real API data fields.

### Mock Fields (Wrong):
```dart
booking['date']          // ❌ Doesn't exist in API
booking['time']          // ❌ Doesn't exist in API
booking['price']         // ❌ Doesn't exist in API
booking['studentMessage'] // ❌ Wrong field name
booking['requestedAt']   // ❌ Wrong field name
booking['earnings']      // ❌ Doesn't exist in API
booking['rating']        // ❌ Wrong location
booking['review']        // ❌ Wrong location
```

### Real API Fields (Correct):
```dart
booking['sessionDate']   // ✅ ISO date string
booking['startTime']     // ✅ Time string (e.g., "10:00 AM")
booking['endTime']       // ✅ Time string (e.g., "11:00 AM")
booking['totalAmount']   // ✅ or booking['pricePerHour']
booking['message']       // ✅ Student's message
booking['createdAt']     // ✅ When booking was created
booking['studentName']   // ✅ Student's full name
booking['tutorName']     // ✅ Tutor's full name
booking['subject']       // ✅ Subject name
booking['mode']          // ✅ 'online' or 'in-person'
booking['location']      // ✅ For in-person sessions
booking['status']        // ✅ 'pending', 'confirmed', 'completed', 'cancelled'
booking['paymentStatus'] // ✅ 'pending', 'completed', 'failed'
```

---

## Fix Applied:

### 1. Student Bookings Screen
**File**: `mobile_app/lib/features/student/screens/student_bookings_screen.dart`

#### Fixed `_loadBookings()` method:
- ✅ Proper date parsing with error handling
- ✅ Filter upcoming bookings by future dates only
- ✅ Sort bookings by date (earliest first for upcoming, most recent first for completed)
- ✅ Handle null/missing dates gracefully
- ✅ Move past-date pending/confirmed bookings to cancelled

#### Fixed booking card display:
- ✅ Use `booking['sessionDate']` instead of `booking['date']`
- ✅ Use `booking['startTime']` and `booking['endTime']` instead of `booking['time']`
- ✅ Use `booking['totalAmount']` or `booking['pricePerHour']` instead of `booking['price']`
- ✅ Use `booking['message']` instead of `booking['studentMessage']`
- ✅ Use `booking['createdAt']` instead of `booking['requestedAt']`

### 2. Tutor Bookings Screen
**File**: `mobile_app/lib/features/tutor/screens/tutor_bookings_screen.dart`

#### Fixed `_loadBookings()` method:
- ✅ Load all bookings in one call (more efficient)
- ✅ Proper date parsing with error handling
- ✅ Filter bookings by status AND date
- ✅ Sort bookings by date
- ✅ Handle null/missing dates gracefully
- ✅ Move past-date pending/confirmed bookings to cancelled

#### Need to fix booking cards:
- ⏳ Update `_buildPendingBookingCard()` to use real fields
- ⏳ Update `_buildConfirmedBookingCard()` to use real fields
- ⏳ Update `_buildCompletedBookingCard()` to use real fields
- ⏳ Update `_buildCancelledBookingCard()` to use real fields

---

## Real Data Mapping:

### Pending Booking Card:
```dart
final studentName = booking['studentName'] ?? booking['student']?['firstName'] ?? 'Student';
final subject = booking['subject'] ?? booking['subjectId']?['name'] ?? 'Unknown Subject';
final sessionDate = booking['sessionDate'] ?? '';
final startTime = booking['startTime'] ?? '';
final endTime = booking['endTime'] ?? '';
final mode = booking['mode'] ?? booking['sessionType'] ?? 'Online';
final price = booking['totalAmount'] ?? booking['pricePerHour'] ?? 0;
final studentMessage = booking['message'];
final requestedAt = booking['createdAt'] ?? '';
final location = booking['location'];
```

### Confirmed Booking Card:
```dart
final studentName = booking['studentName'] ?? booking['student']?['firstName'] ?? 'Student';
final subject = booking['subject'] ?? booking['subjectId']?['name'] ?? 'Unknown Subject';
final sessionDate = booking['sessionDate'] ?? '';
final startTime = booking['startTime'] ?? '';
final endTime = booking['endTime'] ?? '';
final mode = booking['mode'] ?? booking['sessionType'] ?? 'Online';
final price = booking['totalAmount'] ?? booking['pricePerHour'] ?? 0;
final location = booking['location'];
final meetingLink = booking['meetingLink'];
```

### Completed Booking Card:
```dart
final studentName = booking['studentName'] ?? booking['student']?['firstName'] ?? 'Student';
final subject = booking['subject'] ?? booking['subjectId']?['name'] ?? 'Unknown Subject';
final sessionDate = booking['sessionDate'] ?? '';
final earnings = booking['totalAmount'] ?? booking['pricePerHour'] ?? 0;
// Reviews are separate - need to fetch from reviews API or check booking['review'] object
final hasReview = booking['review'] != null || booking['hasReview'] == true;
final rating = booking['review']?['rating'];
final reviewText = booking['review']?['comment'];
```

### Cancelled Booking Card:
```dart
final studentName = booking['studentName'] ?? booking['student']?['firstName'] ?? 'Student';
final subject = booking['subject'] ?? booking['subjectId']?['name'] ?? 'Unknown Subject';
final sessionDate = booking['sessionDate'] ?? '';
final cancelledBy = booking['cancelledBy'] ?? 'Unknown';
final cancellationReason = booking['cancellationReason'] ?? booking['reason'];
final cancelledAt = booking['cancelledAt'] ?? booking['updatedAt'] ?? '';
```

---

## Helper Methods Needed:

### Format Date:
```dart
String _formatDate(String dateStr) {
  if (dateStr.isEmpty) return 'No date';
  try {
    final date = DateTime.parse(dateStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  } catch (e) {
    return dateStr;
  }
}
```

### Format Time Ago:
```dart
String _formatTimeAgo(String dateStr) {
  if (dateStr.isEmpty) return 'recently';
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} week${difference.inDays > 13 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  } catch (e) {
    return 'recently';
  }
}
```

### Check if Today:
```dart
bool _isToday(String dateStr) {
  if (dateStr.isEmpty) return false;
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    return sessionDay.isAtSameMomentAs(today);
  } catch (e) {
    return false;
  }
}
```

---

## Status:

### Student Bookings Screen:
- ✅ `_loadBookings()` - FIXED
- ✅ Booking card display - ALREADY USING REAL FIELDS
- ✅ Date filtering - FIXED
- ✅ Sorting - FIXED

### Tutor Bookings Screen:
- ✅ `_loadBookings()` - FIXED
- ⏳ `_buildPendingBookingCard()` - NEEDS UPDATE
- ⏳ `_buildConfirmedBookingCard()` - NEEDS UPDATE
- ⏳ `_buildCompletedBookingCard()` - NEEDS UPDATE
- ⏳ `_buildCancelledBookingCard()` - NEEDS UPDATE

---

## Next Steps:

1. ✅ Update student bookings `_loadBookings()` - DONE
2. ✅ Update tutor bookings `_loadBookings()` - DONE
3. ⏳ Update tutor booking cards to use real fields
4. ⏳ Add helper methods for date formatting
5. ⏳ Test with real API data
6. ⏳ Verify all tabs show correct data

---

**Current Status**: IN PROGRESS
**Files Modified**: 2/2 (loading logic fixed, card display needs update)
