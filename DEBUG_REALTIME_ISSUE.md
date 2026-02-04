# 🔍 Debug Real-Time Communication Issue

## Current Status

The server has been updated with extensive logging to help us debug why real-time communication isn't working.

## What to Do Now

### Step 1: Wait for Deployment (2-3 minutes)
Go to https://dashboard.render.com and wait for `tutor-app-backend` to show "Deploy live"

### Step 2: Test and Check Logs

**On Device A (Student):**
1. Login: `etsebruk@example.com` / `123abc`
2. Go to Messages
3. Open chat with tutor
4. Send message: "Test 1"

**Immediately check Render logs** for these messages:
```
💬 Attempting to emit socket event for conversation: [conversationId]
💬 Current user ID: [userId]
💬 Conversation participants: [...]
💬 Comparing: [participantId] !== [currentUserId]
💬 Found recipient: [recipientId]
💬 Emitting to room: user_[recipientId]
✅ Socket event emitted to user_[recipientId]
✅ Socket event emitted to chat_[conversationId]
```

### Step 3: Check for Errors

**If you see:**
```
❌ Could not find recipient in conversation
❌ Socket.IO not available!
❌ Socket emit error:
```

→ There's a problem! Share the full error message.

### Step 4: Check Socket Connection

**On both devices**, after login, check if you see in Render logs:
```
🔌 User connected: [Name] ([userId])
```

**If you DON'T see this** → Socket is not connecting!

## Common Issues & Solutions

### Issue 1: Socket Not Connecting

**Symptoms:**
- No "User connected" message in logs
- Messages don't appear on other device

**Possible Causes:**
1. App not connecting to socket
2. Auth token not being sent
3. Network issue

**Solution:**
1. Close app completely on both devices
2. Reopen and login again
3. Check logs for "User connected"

### Issue 2: Socket Events Not Being Emitted

**Symptoms:**
- "User connected" appears in logs
- But no "Socket event emitted" messages

**Possible Causes:**
1. Conversation participants not loaded correctly
2. Recipient ID not found
3. Socket.IO instance not available

**Solution:**
Check the debug logs I added - they will show exactly where it's failing

### Issue 3: Events Emitted But Not Received

**Symptoms:**
- "Socket event emitted" appears in logs
- But message doesn't appear on other device

**Possible Causes:**
1. Mobile app not listening for events
2. Wrong room name
3. Socket disconnected on receiver

**Solution:**
1. Check if receiver shows "User connected" in logs
2. Verify room name matches: `user_[userId]`
3. Restart receiver's app

## What the New Logs Will Tell Us

The updated code now logs:

1. **Conversation ID** - Which chat is being used
2. **Current User ID** - Who is sending
3. **All Participants** - Who is in the conversation
4. **Comparison** - How we're finding the recipient
5. **Recipient ID** - Who should receive the message
6. **Room Name** - Which socket room we're emitting to
7. **Success/Failure** - Whether emit succeeded

This will help us pinpoint EXACTLY where the problem is!

## Testing Checklist

After deployment completes:

- [ ] Device A: Login and check logs for "User connected"
- [ ] Device B: Login and check logs for "User connected"
- [ ] Device A: Send message
- [ ] Check logs for "Attempting to emit socket event"
- [ ] Check logs for "Found recipient"
- [ ] Check logs for "Socket event emitted"
- [ ] Device B: Check if message appears

## What to Report Back

Please share:

1. **Do you see "User connected" for both users?** (Yes/No)
2. **When you send a message, what logs appear?** (Copy/paste)
3. **Any error messages?** (Copy/paste)
4. **Does the message appear after refresh?** (Yes/No)

## Next Steps

Based on the logs, we'll know if the issue is:
- Socket connection (no "User connected")
- Event emission (no "Socket event emitted")
- Event reception (emitted but not received)
- Something else

Then we can fix the specific problem!

---

## Quick Test After Deployment

1. Wait for "Deploy live" on Render
2. Login on both devices
3. Send one message
4. Check Render logs immediately
5. Report back what you see!
