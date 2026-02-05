# 🧪 Test Guide: Three Critical Fixes

## Quick Test Checklist

### ✅ Fix 1 & 2: Profile Display

**Test Steps:**
1. Open mobile app as a student
2. Go to "Find Tutors" tab
3. Tap on any tutor card
4. **Expected:** Profile details should display (name, bio, subjects, rate, etc.)
5. Scroll down and tap "View Full Profile" or similar button
6. **Expected:** Full profile page should load with all information

**What to Look For:**
- ✅ Tutor name displays
- ✅ Profile picture shows
- ✅ Bio text is visible
- ✅ Subjects list appears
- ✅ Hourly rate displays
- ✅ Experience and education show
- ✅ Rating and reviews count visible

**If It Fails:**
- Check server logs for errors
- Verify API response structure
- Check mobile app console for errors

---

### ✅ Fix 3: Clear Chat

**Test Steps:**
1. Open mobile app
2. Go to Messages/Chat tab
3. Open any existing conversation
4. Tap the menu icon (⋮ or three dots)
5. Select "Clear Chat"
6. **Expected:** Chat clears successfully
7. Check server logs

**What to Look For:**
- ✅ Chat messages disappear from UI
- ✅ Success message shows
- ✅ No error dialogs appear
- ✅ Server logs show: "✅ Chat cleared for user [userId]"
- ✅ NO error: "Cannot add new event after calling close"

**Server Log Check:**
```
✅ GOOD:
🗑️ User 6982070893c3d1baab1d3857 clearing chat 69824267eee7b2c6dd780234
✅ Chat cleared for user 6982070893c3d1baab1d3857
✅ Socket event emitted to user_698292bf77cd6ccd64c5b705

❌ BAD (should NOT see):
Cannot add new event after calling close
Error: Socket closed
```

---

## Additional Tests

### Test Multiple Clear Chat Operations
1. Clear chat in conversation A
2. Immediately clear chat in conversation B
3. Clear chat in conversation A again
4. **Expected:** All operations succeed without socket errors

### Test Clear Chat While Other User Online
1. Have two devices/users in a conversation
2. User A clears the chat
3. **Expected:** 
   - User A sees cleared chat
   - User B receives notification (if implemented)
   - No socket errors in server logs

---

## Server Logs to Monitor

### Good Logs (What You Want to See):
```
🔌 User connected: [Name] ([userId])
📨 Getting conversations for user: [userId]
🗑️ User [userId] clearing chat [conversationId]
✅ Chat cleared for user [userId]
✅ Socket event emitted to user_[recipientId]
```

### Bad Logs (What Should NOT Appear):
```
❌ Cannot add new event after calling close
❌ Error: Socket closed
❌ TypeError: Cannot read property 'emit' of undefined
❌ Socket emit error: [critical error]
```

### Acceptable Warnings (Non-Critical):
```
⚠️ Socket emit error (non-critical): [message]
⚠️ Error broadcasting user status: [message]
```

---

## Troubleshooting

### Profile Not Showing
1. Check server is running: `http://localhost:5000/api/tutors`
2. Test API directly: `GET http://localhost:5000/api/tutors/[tutorId]`
3. Verify response structure has `data` directly (not `data.tutor`)
4. Check mobile app API service is using correct endpoint

### Clear Chat Still Failing
1. Restart server completely
2. Clear mobile app cache/data
3. Reconnect to server
4. Check socket connection is established
5. Verify user is authenticated

### Socket Errors Persist
1. Check `io.sockets` is available
2. Verify socket middleware is working
3. Check user authentication token
4. Monitor socket connection/disconnection events

---

## Success Criteria

All three fixes are working if:
- ✅ Tutor profiles display correctly
- ✅ View profile navigation works
- ✅ Clear chat completes without errors
- ✅ No "Cannot add new event" errors in logs
- ✅ Socket operations are stable

---

## Report Issues

If any test fails, provide:
1. Which test failed
2. Error message (if any)
3. Server logs (last 20 lines)
4. Mobile app console logs
5. Steps to reproduce

---

**Ready to Test!** 🚀

Start with the profile display test, then move to clear chat.
