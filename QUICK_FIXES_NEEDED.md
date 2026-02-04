# 🔧 Quick Fixes Needed

## Issues to Fix:

### 1. ✅ Notification Badge Count - ALREADY IMPLEMENTED
**Status:** The badge is already functional in the code
**Location:** 
- `mobile_app/lib/features/student/screens/student_dashboard_screen.dart`
- `mobile_app/lib/features/tutor/screens/tutor_dashboard_screen.dart`

**How it works:**
- Calls `_notificationService.getUnreadCount()` on init
- Listens to `notificationCountStream` for real-time updates
- Shows badge when `_unreadCount > 0`

**If not working, check:**
- Server endpoint `/notifications/unread-count` is working
- Notifications are being marked as read properly
- Stream is emitting updates

---

### 2. ❌ Profile Detail Not Showing
**Issue:** Need to investigate which profile screen
**Possible locations:**
- Student viewing own profile
- Tutor viewing own profile  
- Student viewing tutor profile
- Tutor viewing student profile

**Need to check:**
- Navigation routes
- API calls
- Data loading

---

### 3. ❌ Chat "View Profile" Not Working
**Issue:** View Profile option in chat menu
**Location:** `mobile_app/lib/features/chat/screens/chat_screen.dart`
**Need to check:**
- Menu action handler
- Navigation to profile screen
- Profile ID being passed correctly

---

### 4. ❌ "Access Denied" on Clear Chat
**Issue:** Permission error when clearing chat
**Location:** 
- Frontend: `mobile_app/lib/features/chat/screens/chat_screen.dart`
- Backend: `server/controllers/chatController.js`
**Need to check:**
- Clear chat endpoint permissions
- Auth middleware
- User role checks

---

## Let's Fix Them One by One!
