# 🔧 Fixes for 4 Issues

## Issue #1: Notification Badge Count ✅ ALREADY WORKS

**Status:** The code is already implemented correctly!

**How to verify it's working:**
1. Create a notification for the user
2. Check the dashboard - badge should show count
3. Mark notifications as read
4. Badge should update/disappear

**If still not working:**
- Check server logs for `/notifications/unread-count` endpoint
- Verify notifications exist in database
- Check if `isRead` field is being set correctly

---

## Issue #2: Profile Detail Not Showing ❓ NEED MORE INFO

**Need clarification:**
- Which profile screen? (Student profile? Tutor profile?)
- From where? (Dashboard? Search? Chat?)
- What error message appears?

**Common causes:**
- Navigation route not configured
- API endpoint returning wrong data
- Profile ID not being passed correctly

---

## Issue #3: Chat "View Profile" Not Working ❌ FIX NEEDED

**Problem:** Using `Navigator.pushNamed` instead of `context.push` (go_router)

**Location:** `mobile_app/lib/features/chat/screens/chat_screen.dart` line ~1378

**Current Code:**
```dart
Navigator.pushNamed(
  context,
  '/student/tutor/${widget.participantId}',
);
```

**Fixed Code:**
```dart
context.push('/student/tutor/${widget.participantId}');
```

**Also need to import:**
```dart
import 'package:go_router/go_router.dart';
```

---

## Issue #4: "Access Denied" on Clear Chat ❌ FIX NEEDED

**Problem:** Backend is checking `req.user.userId` but it might not be set

**Possible causes:**
1. Auth token not being sent
2. Token expired
3. User ID format mismatch (string vs ObjectId)

**Backend code looks correct:**
```javascript
const isParticipant = conversation.participants.some(
  p => p.userId.toString() === userId
);
```

**Need to check:**
- Is auth token being sent in request?
- Is `req.user.userId` being set by auth middleware?
- Are participant IDs stored as ObjectId or string?

**Debug steps:**
1. Add console.log in backend to see what `userId` is
2. Add console.log to see what `conversation.participants` contains
3. Check if comparison is working

---

## Quick Fixes to Apply:

### Fix #3: Chat View Profile
```dart
// In chat_screen.dart, replace _viewProfile method:

void _viewProfile() {
  final authProvider = context.read<AuthProvider>();
  final currentUserRole = authProvider.user?.role;
  
  if (currentUserRole == 'student') {
    // Student viewing tutor profile - USE context.push!
    context.push('/student/tutor/${widget.participantId}');
  } else if (currentUserRole == 'tutor') {
    // Tutor viewing student profile
    _showStudentInfoDialog();
  }
}
```

### Fix #4: Clear Chat Debug
```javascript
// In chatController.js, add debug logs:

exports.clearChat = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { conversationId } = req.params;

    console.log(`🗑️ User ${userId} clearing chat ${conversationId}`);
    console.log(`🔍 User ID type: ${typeof userId}`);
    console.log(`🔍 User ID value: ${userId}`);

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found'
      });
    }

    console.log(`🔍 Participants:`, conversation.participants.map(p => ({
      userId: p.userId.toString(),
      type: typeof p.userId
    })));

    const isParticipant = conversation.participants.some(
      p => p.userId.toString() === userId.toString() // Add .toString() to userId too!
    );

    console.log(`🔍 Is participant: ${isParticipant}`);

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to clear this conversation'
      });
    }

    // Rest of code...
  }
};
```

---

## Let me apply these fixes now!
