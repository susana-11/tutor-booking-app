# ✅ Schedule Duration Validation Fixed

## 🐛 Issue

When creating availability slots, the error occurs:
```
AvailabilitySlot validation failed: timeSlot.durationMinutes: 
Path `durationMinutes` (6) is less than minimum allowed value (15).
```

## 🔍 Root Cause

The tutor is selecting a time slot that's less than 15 minutes long. For example:
- Start: 08:15
- End: 08:21
- Duration: 6 minutes ❌ (minimum is 15 minutes)

## ✅ Fix Applied

### Backend Validation Enhanced
**File**: `server/controllers/availabilitySlotController.js`

Added better validation and error message:
```javascript
if (durationMinutes < 15) {
  return res.status(400).json({
    success: false,
    message: `Time slot must be at least 15 minutes long. Current duration: ${durationMinutes} minutes. Please select a longer time slot.`
  });
}
```

Now the error message will clearly tell the tutor:
- What the minimum duration is (15 minutes)
- What duration they selected (e.g., 6 minutes)
- What to do (select a longer time slot)

## 📱 How to Fix in Mobile App

### Option 1: Enforce Minimum Duration in Time Picker

When selecting end time, ensure it's at least 15 minutes after start time:

```dart
// In tutor_schedule_screen.dart
void _selectEndTime() async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _endTime,
  );
  
  if (picked != null) {
    // Calculate duration
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = picked.hour * 60 + picked.minute;
    final duration = endMinutes - startMinutes;
    
    if (duration < 15) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot must be at least 15 minutes long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _endTime = picked;
    });
  }
}
```

### Option 2: Use Predefined Duration Options

Instead of free time selection, offer preset durations:

```dart
// Duration options
final durations = [
  {'label': '15 minutes', 'minutes': 15},
  {'label': '30 minutes', 'minutes': 30},
  {'label': '45 minutes', 'minutes': 45},
  {'label': '1 hour', 'minutes': 60},
  {'label': '1.5 hours', 'minutes': 90},
  {'label': '2 hours', 'minutes': 120},
];

// Then calculate end time based on start time + duration
final endTime = startTime.add(Duration(minutes: selectedDuration));
```

### Option 3: Show Duration While Selecting

Display the calculated duration in real-time:

```dart
Widget build(BuildContext context) {
  final duration = _calculateDuration(_startTime, _endTime);
  
  return Column(
    children: [
      // Start time picker
      // End time picker
      
      // Duration display
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: duration < 15 ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Duration: $duration minutes ${duration < 15 ? '(minimum 15 minutes)' : '✓'}',
          style: TextStyle(
            color: duration < 15 ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
```

## 🎯 Recommended Solution

**Use Option 2 (Predefined Durations)** because:
1. ✅ Prevents user error
2. ✅ Faster to select
3. ✅ Standard durations (15, 30, 45, 60 min)
4. ✅ Better UX
5. ✅ No validation errors

## 🧪 Testing

### Test Case 1: Short Duration
```
1. Select start time: 08:00
2. Select end time: 08:10 (10 minutes)
3. Try to save
4. ✅ Should show error: "Time slot must be at least 15 minutes long"
```

### Test Case 2: Valid Duration
```
1. Select start time: 08:00
2. Select end time: 08:30 (30 minutes)
3. Save
4. ✅ Should create slot successfully
```

### Test Case 3: Minimum Duration
```
1. Select start time: 08:00
2. Select end time: 08:15 (15 minutes)
3. Save
4. ✅ Should create slot successfully
```

## 📊 Duration Rules

### Minimum: 15 minutes
- Shortest allowed session
- Good for quick consultations

### Recommended: 30-60 minutes
- Standard tutoring session
- Most common duration

### Maximum: 480 minutes (8 hours)
- Longest allowed session
- For intensive courses

## ✅ Summary

**Issue**: Time slots less than 15 minutes were being rejected  
**Fix**: Added clear validation message in backend  
**Next Step**: Add duration validation in mobile app UI  
**Recommended**: Use predefined duration options (15, 30, 45, 60 min)

---

**Status**: ✅ Backend validation improved  
**Action Required**: Update mobile app to enforce minimum duration
